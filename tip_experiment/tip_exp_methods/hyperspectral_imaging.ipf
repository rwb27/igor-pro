#pragma ModuleName = hyperspec
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "data_handling"
#include "pi_pi733_3cd_stage"
#include "OO spectrometer v4.2"

static strconstant gv_folder = "root:global_variables:hyperspectral_imaging"

static function initialise()
	data#check_folder("root:global_variables")
	data#check_folder(gv_folder)
	variable/g $(gv_folder + ":wavelength") = 0
end

function wavelength_to_index(wavelength)
	variable wavelength
	wave wl_wave = root:oo:data:current:wl_wave
	variable index, i = 0
	do
		i += 1
	while (wl_wave[i] < wavelength)
	if ((wl_wave[i] - wavelength) > (wavelength - wl_wave[i-1]))
		i -= 1
	endif
	return i
end

static function scan(scan_size, scan_step)
	// perform a spectral scan to obtain a hyperspectral image. //
	variable scan_size, scan_step
	data#check_folder("root:global_variables")
	data#check_folder(gv_folder)
	string data_folder = data#check_data_folder()
	string scan_folder = data#new_data_folder(data_folder + ":hyperspec_image_")
	
	// make hyperspectral image array
	duplicate/o root:oo:data:current:wl_wave, $(scan_folder + ":wavelength")
	wave wavelength = $(scan_folder + ":wavelength")
	variable image_size = scan_size/scan_step + 1
	make/o/n=(image_size, image_size, numpnts(wavelength)) $(scan_folder + ":hyperspec_image")
	wave hs_data = $(scan_folder + ":hyperspec_image")
	hs_data = 0
	
	// prepare scan preview
	variable wavelength_1 = wavelength_to_index(520)
	variable wavelength_2 = wavelength_to_index(633)
	variable/g $(gv_folder + ":wavelength_1") = wavelength_1
	variable/g $(gv_folder + ":wavelength_2") = wavelength_2
	
	dowindow/k hyperspectral_image
	display/n=hyperspectral_image
	appendimage hs_data; modifyimage ''#0 plane=wavelength_1
	appendimage/l=l2 hs_data; modifyimage ''#1 plane=wavelength_2
	modifygraph tick=2,mirror=1,fSize=14,standoff=0,axisEnab(left)={0.51,1}
	modifygraph axisEnab(l2)={0,0.49},freePos(l2)=0
	modifygraph width=226.772
	modifygraph height={Aspect,2}
	modifyimage ''#0 ctab= {*,*,ColdWarm,0}, ctabAutoscale=2,lookup= $""
	modifyimage ''#1 ctab= {*,*,ColdWarm,0}, ctabAutoscale=2,lookup= $""
	
	// get current pz positions
	pi_stage#open_comms()
	variable init_a = pi_stage#get_pos_ch("a")
	variable init_b = pi_stage#get_pos_ch("b")
	variable init_c = pi_stage#get_pos_ch("c")
	variable move_delay = 0.1//0.05
	
	// move to initial position
	variable pos_a = init_a - scan_size/2
	variable pos_b = init_b - scan_size/2
	setscale/p x pos_a, scan_step, hs_data
	setscale/p y pos_b, scan_step, hs_data
	
	// begin scan
	variable q1, q2
	do
		pos_a = init_a - scan_size/2							// reset A position
		pi_stage#move("A", pos_a); sleep/s move_delay			// move to right
		q1 = 0												// reset A counter
		
		pi_stage#move("B", pos_b); sleep/s move_delay
		do
			if(getkeystate(0) & 32)								// check for user abort (escape key)
				pi_stage#move("A", init_a); sleep/s move_delay
				pi_stage#move("B", init_b); sleep/s move_delay
				abort "user abort"
			endif
			// move to location and take spectra
			pi_stage#move("A", pos_a); sleep/s move_delay
			OO_read()
			// save spectra
			wave w=root:oo:data:current:spectra				// declare spectrum wave
			hs_data[q1][q2][] = w[r]					
			doupdate
								
			pos_a += scan_step								// increment grid (a) position	
			q1 += 1											// increment counter
		while(q1 <= (scan_size/scan_step))
		
		pos_b += scan_step									// increment grid (b) position
		q2 += 1												// reset B counter
	while(q2 <= (scan_size/scan_step))
	
	pi_stage#move("A", init_a); sleep/s move_delay							// move to initial position
	pi_stage#move("B", init_b); sleep/s move_delay
end

static function fit_scan(hs_scan, wavelength)
	wave hs_scan
	variable wavelength
	variable index = wavelength_to_index(wavelength)
	variable z0, a0, x0, sigx, y0, sigy, corr
		
	// Amplitude: Difference between z0 and the grid centre value
	imagestats/m=1/p=(index) hs_scan
	z0 = V_min
	a0 = V_max - z0
	// Centre-points: The location of the maximum grid value
	x0 = DimOffset(hs_scan, 0) + V_maxRowLoc*DimDelta(hs_scan, 0)
	y0 = DimOffset(hs_scan, 1) + V_maxColLoc*DimDelta(hs_scan, 1)
	// Peak width: Set to 100 nm, a typical starting point
	sigx = 0.1
	sigy = 0.1
	// xy correlation: Set to 0
	corr = 0
	
	string data_folder = data#check_data_folder()
	make/d/n=7/o $(data_folder + ":w_coef_"+num2str(wavelength))
	wave w_coef = $(data_folder + ":w_coef_"+num2str(wavelength))
	w_coef[0] = {z0, a0, x0, y0, sigx, sigy, corr}
	FuncFitMD/nthr=0/q gauss2dc, w_coef, hs_scan[][][index] /D//C=constraintWave
end

static function gauss2dc(w, x, y) : FitFunc
	wave w
	variable x, y
	variable z0 = w[0], A = w[1], x0 = w[2], y0 = w[3], sigx = w[4], sigy = w[5], corr = w[6]
	variable f = z0 + A * exp( ( -1/(2*(1-corr^2)) ) * ( ( (x - x0)^2 / (2*sigx^2) ) + ( (y - y0)^2 / (2*sigy^2) ) - ( (2*corr*(x-x0)*(y-y0))/(sigx*sigy) ) ) )
	return f
end

static function display_scan(hs_data, wavelength)
	wave hs_data
	variable wavelength
	variable index = wavelength_to_index(wavelength)
	dowindow/k hyperspectral_image
	display/n=hyperspectral_image
	appendimage hs_data; modifyimage hs_scan plane=index
	modifygraph tick=2,mirror=1,fSize=14
	modifygraph width=226.772
	modifygraph height={Aspect,2}
	modifyimage '' ctab= {*,*,ColdWarm,0}, ctabAutoscale=2,lookup= $""
	textbox/c/n=text0/f=0/b=1/g=(65280,65280,0)/a=rt "\\Z10\\F'Symbol'l\\F'Arial' = "+num2str(wavelength)+" nm"
end

// -- PANEL -- //

function display_scan_button(ba) : ButtonControl
	struct wmbuttonaction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			nvar wavelength = $(gv_folder + ":wavelength")
			wave hs_data
			display_scan(hs_data, wavelength)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

function set_wavelength(sva) : SetVariableControl
	struct wmsetvariableaction &sva
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
			dowindow hyperspectral_image
			if (V_flag == 1)
				modifyimage '' plane = wavelength_to_index(dval)
				textbox/k/n=text0
				textbox/c/n=text0/f=0/b=1/g=(65280,65280,0)/a=rt "\\Z10\\F'Symbol'l\\F'Arial' = "+num2str(dval)+" nm"
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function wavelength_slider(sa) : slidercontrol
	struct wmslideraction &sa
	switch( sa.eventcode )
		case -1: // control being killed
			break
		default:
			if( sa.eventcode & 1 ) // value set
				variable curval = sa.curval
				dowindow hyperspectral_image
				if (V_flag == 1)
					modifyimage '' plane = wavelength_to_index(curval)
					textbox/k/n=text0
					textbox/c/n=text0/f=0/b=1/g=(65280,65280,0)/a=rt "\\Z10\\F'Symbol'l\\F'Arial' = "+num2str(curval)+" nm"
				endif
			endif
			break
	endswitch

	return 0
End

function hyperspec_imaging() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(790,75,994,152) as "HyperspecImage"
	ModifyPanel frameStyle=1
	ShowTools/A
	Button display,pos={128,3},size={70,20},proc=DisplayHyperSpec,title="Display Data"
	Button display,fSize=11
	initialise()
	SetVariable setwlen,pos={4,5},size={122,16},bodyWidth=60,proc=set_wavelength,title="Wavelength"
	SetVariable setwlen,fSize=11
	SetVariable setwlen,limits={400,1000,1},value= $(gv_folder + ":wavelength")
	Slider slider0,pos={5,24},size={193,52},proc=wavelength_slider
	Slider slider0,limits={400,1000,1},variable= $(gv_folder + ":wavelength"),vert= 0
end