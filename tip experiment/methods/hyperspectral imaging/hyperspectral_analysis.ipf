#pragma ModuleName = hyperspec_analysis
#pragma version = 6.23
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "analysis_tools"

static function fit_scan(hs_scan, wavelength)
	wave hs_scan
	variable wavelength
	svar/sdfr=$gv_folder scan_folder = current_scan_folder
	wave wl_wave = $(scan_folder + ":wavelength")
	variable index = wavelength_to_index(wl_wave, wavelength)
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
	svar/sdfr=$gv_folder scan_folder = current_scan_folder
	wave wl_wave = $(scan_folder + ":wavelength")
	variable index = wavelength_to_index(wl_wave, wavelength)
	dowindow/k hyperspectral_image
	display/n=hyperspectral_image
	appendimage hs_data; modifyimage ''#0 plane=index
	modifygraph tick=2, mirror=1, fSize=11
	modifygraph width=250
	modifygraph height={aspect,1}
	modifyimage ''#0 ctab= {0,*,ColdWarm,0}, ctabAutoscale=3,lookup= $""
	textbox/c/n=text0/f=0/b=1/g=(65280,65280,0)/a=rt "\\Z10\\F'Symbol'l\\F'Arial' = "+num2str(wavelength)+" nm"
end

static function display_multi_scan(hs_data1, hs_data2, wavelength)
	wave hs_data1, hs_data2
	variable wavelength
	svar/sdfr=$gv_folder scan_folder = current_scan_folder
	wave wl_wave = $(scan_folder + ":wavelength")
	variable index = wavelength_to_index(wl_wave, wavelength)
	dowindow/k hyperspectral_image
	display/n=hyperspectral_image
	appendimage/l/t hs_data1; modifyimage ''#0 plane=index
	appendimage/r/b hs_data2; modifyimage ''#1 plane=index
	ModifyGraph axisEnab(top)={0,0.5},axisEnab(bottom)={0.5,1}
	modifygraph freepos=0
	modifygraph tick=2, fSize=11
	modifygraph width=500
	modifygraph height={aspect,0.5}
	modifyimage ''#0 ctab= {0,*,ColdWarm,0}, ctabAutoscale=3,lookup= $""
	modifyimage ''#1 ctab= {0,*,ColdWarm,0}, ctabAutoscale=3,lookup= $""
	textbox/c/n=text0/f=0/b=1/g=(65280,65280,0)/a=rt "\\Z10\\F'Symbol'l\\F'Arial' = "+num2str(wavelength)+" nm"
end

static function display_sum_scan(hs_data)
	wave hs_data
	make/o/n=(dimsize(hs_data, 0), dimsize(hs_data, 1)) sum_image = 0
	variable i
	for(i = 0; i <= dimsize(hs_data, 2); i += 1)
		make/free/n=(dimsize(hs_data, 0), dimsize(hs_data, 1)) image
		image[][] = hs_data[p][q][i] / dimsize(hs_data, 2)
		sum_image[][] += image
	endfor
	dowindow/k hyperspectral_image
	display/n=hyperspectral_image
	appendimage sum_image
	modifygraph tick=2, mirror=1, fSize=11
	modifygraph width=250
	modifygraph height={aspect,1}
	modifyimage '' ctab= {0,*,ColdWarm,0}, ctabAutoscale=3,lookup= $""
end

function analyse_scan(hs_data, wavelength)
	wave hs_data
	variable wavelength
	display_scan(hs_data, wavelength)
	cursor/a=1/c=(65000,65000,65000)/h=0/i/p/s=2 A, ''#0, dimsize(hs_data, 0)/2, dimsize(hs_data, 1)/2
	setwindow hyperspectral_image, hook(csrA)=spectra_cursor
	svar image = $(gv_folder + ":image")
	wave spec = $(image + ":spec"), wl_wave = $(image + ":wavelength")
	if (!waveexists(spec))
		make/o/n=(dimsize(hs_data, 2)) $(image + ":spec")
	endif
	dowindow/k hs_spec
	display/n=hs_spec spec vs wl_wave
	setaxis/a=2 left
	setaxis bottom 450, 1000
end

function spectra_cursor(s)
	struct wmwinhookstruct &s
	svar image = $(gv_folder + ":image")
	wave hs_data = $(image + ":hyperspec_image")
	wave wavelength = $(image + ":wavelength")
	switch (s.eventcode)
		case 7:
			wave spec = $(image + ":spec")
			if (!waveexists(spec))
				make/o/n=(dimsize(hs_data, 2)) $(image + ":spec")
			endif
			spec = hs_data[pcsr(A)][qcsr(A)][p]
			doupdate
			break
	endswitch
	return 0
end

function analyse_multi_scan(hs_data1, hs_data2, wavelength)
	wave hs_data1, hs_data2
	variable wavelength
	display_multi_scan(hs_data1, hs_data2, wavelength)
	cursor/a=1/c=(65000,65000,65000)/h=0/i/p/s=0 A, ''#0, dimsize(hs_data1, 0)/2, dimsize(hs_data1, 1)/2
	cursor/a=1/c=(65000,65000,65000)/h=0/i/p/s=0 B, ''#1, dimsize(hs_data2, 0)/2, dimsize(hs_data2, 1)/2
	setwindow hyperspectral_image, hook(csrA)=multi_spectra_cursor
	svar image1 = $(gv_folder + ":image")
	wave spec1 = $(image1 + ":spec"), wl_wave = $(image1 + ":wavelength")
	if (!waveexists(spec1))
		make/o/n=(dimsize(hs_data1, 2)) $(image1 + ":spec")
	endif
	svar image2 = $(gv_folder + ":image2")
	wave spec2 = $(image2 + ":spec")
	if (!waveexists(spec2))
		make/o/n=(dimsize(hs_data2, 2)) $(image2 + ":spec")
	endif
	dowindow/k hs_spec
	display/n=hs_spec spec1 vs wl_wave
	modifygraph rgb(''#0)=(0,0,0)
	appendtograph/r spec2 vs wl_wave
	setaxis/a=2 left; setaxis/a=2 right
	setaxis bottom 450, 1000
end

function multi_spectra_cursor(s)
	struct wmwinhookstruct &s
	svar image1 = $(gv_folder + ":image")
	svar image2 = $(gv_folder + ":image2")
	wave hs_data1 = $(image1 + ":hyperspec_image")
	wave hs_data2 = $(image2 + ":hyperspec_image")
	wave wavelength = $(image1 + ":wavelength")
	switch (s.eventcode)
		case 7:
			wave spec1 = $(image1 + ":spec")
			if (!waveexists(spec1))
				make/o/n=(dimsize(hs_data1, 2)) $(image1 + ":spec")
			endif
			spec1 = hs_data1[pcsr(A)][qcsr(A)][p]
			wave spec2 = $(image2 + ":spec")
			if (!waveexists(spec2))
				make/o/n=(dimsize(hs_data2, 2)) $(image2 + ":spec")
			endif
			spec2 = hs_data2[pcsr(B)][qcsr(B)][p]
			doupdate
			break
	endswitch
	return 0
end

// -- PANEL -- //

function display_scan_button(ba) : ButtonControl
	struct wmbuttonaction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			nvar wavelength = $(gv_folder + ":wavelength")
			svar image = $(gv_folder + ":image")
			wave hs_data = $(image + ":hyperspec_image")
			display_scan(hs_data, wavelength)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

function display_analysis_button(ba) : ButtonControl
	struct wmbuttonaction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			nvar wavelength = $(gv_folder + ":wavelength")
			svar image = $(gv_folder + ":image")
			wave hs_data = $(image + ":hyperspec_image")
			analyse_scan(hs_data, wavelength)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

function display_multi_analysis_button(ba) : ButtonControl
	struct wmbuttonaction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			nvar wavelength = $(gv_folder + ":wavelength")
			svar image1 = $(gv_folder + ":image")
			svar image2 = $(gv_folder + ":image2")
			wave hs_data1 = $(image1 + ":hyperspec_image")
			wave hs_data2 = $(image2 + ":hyperspec_image")
			analyse_multi_scan(hs_data1, hs_data2, wavelength)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

function display_sum_scan_button(ba) : ButtonControl
	struct wmbuttonaction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			svar image = $(gv_folder + ":image")
			wave hs_data = $(image + ":hyperspec_image")
			display_sum_scan(hs_data)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

function set_image(sva) : setvariablecontrol
	struct wmsetvariableaction &sva
	switch (sva.eventcode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
			dowindow hyperspectral_image
		case -1: // control being killed
			break
	endswitch
	return 0
end

function set_wavelength(sva) : setvariablecontrol
	struct wmsetvariableaction &sva
	switch (sva.eventcode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
			dowindow hyperspectral_image
			if (V_flag == 1)
				svar/sdfr=$gv_folder scan_folder = current_scan_folder
				wave wl_wave = $(scan_folder + ":wavelength")
				modifyimage ''#0 plane = wavelength_to_index(wl_wave, dval)
				modifyimage ''#1 plane = wavelength_to_index(wl_wave, dval)
				textbox/k/n=text0
				textbox/c/n=text0/f=0/b=1/g=(65280,65280,0)/a=rt "\\Z10\\F'Symbol'l\\F'Arial' = "+num2str(dval)+" nm"
			endif
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

function wavelength_slider(sa) : slidercontrol
	struct wmslideraction &sa
	switch( sa.eventcode )
		case -1: // control being killed
			break
		default:
			if( sa.eventcode & 1 ) // value set
				variable curval = sa.curval
				dowindow hyperspectral_image
				if (V_flag == 1)
					svar/sdfr=$gv_folder scan_folder = current_scan_folder
					wave wl_wave = $(scan_folder + ":wavelength")
					modifyimage ''#0 plane = wavelength_to_index(wl_wave, curval)
					modifyimage ''#1 plane = wavelength_to_index(wl_wave, curval)
					textbox/k/n=text0
					textbox/c/n=text0/f=0/b=1/g=(65280,65280,0)/a=rt "\\Z10\\F'Symbol'l\\F'Arial' = "+num2str(curval)+" nm"
				endif
			endif
			break
	endswitch
	return 0
end

function hyperspec_imaging() : panel
	variable left, top, right, bottom
	initialise()
	left = 0; top = 0
	dowindow/k hyperspec
	newpanel/w=(500,100,750,250)/n=hyperspec as "Hyperspectral Imaging"
	modifypanel frameStyle=1
	showtools/a
	// display scan button
	left += 5; top += 5
	button display_hs, pos={left, top}, size={70,20}, proc=display_scan_button, title="Display Scan"
	button display_hs, fSize=11
	// set image
	left += 75
	setvariable set_hs, pos={left, top}, size={150,20}, proc=set_image,title="Image"
	setvariable set_hs, fSize=11
	setvariable set_hs, value= $(gv_folder + ":image")
	left -= 75
	// set image 2
	top += 25
	left += 75
	setvariable set_hs2, pos={left, top}, size={150,20}, proc=set_image,title="Image 2"
	setvariable set_hs2, fSize=11
	setvariable set_hs2, value= $(gv_folder + ":image2")
	left -= 75
	// set wavelength
	top += 25
	setvariable set_wlen,pos={left, top},size={130,20},bodyWidth=60,proc=set_wavelength,title="Wavelength"
	setvariable set_wlen,fSize=11
	setvariable set_wlen, limits={450,1000,10}, live=1, value= $(gv_folder + ":wavelength")
	// display sum scan button
	left += 140
	button display_shs, pos={left, top}, size={70,20}, proc=display_sum_scan_button, title="Display Sum"
	button display_shs, fSize=11
	left -= 140
	// set wavelength slide
	top += 20
	slider wl_slider,pos={left, top},size={193,52},proc=wavelength_slider
	slider wl_slider,limits={450,1000,1},variable= $(gv_folder + ":wavelength"),vert= 0
	// display analysis button
	top += 45
	button analyse_hs, pos={left, top}, size={70,20}, proc=display_analysis_button, title="Analysis"
	button analyse_hs, fSize=11
	// display multi analysis button
	left += 75
	button analyse_multi_hs, pos={left, top}, size={80,20}, proc=display_multi_analysis_button, title="Multi-Analysis"
	button analyse_multi_hs, fSize=11
end