#pragma IndependentModule = pixis
//#pragma modulename = pixis
#pragma version = 6.31
#pragma rtGlobals=1		// Use modern global access method.

strconstant gv_folder = "root:global_variables:princeton_instr_pixis_256e_ccd"

strconstant kinetics = "c:\\users\\hera\\desktop\\tip_exp\\pixis_256e\\kinetics.exe"
strconstant init_kinetics = "c:\\users\\hera\\desktop\\tip_exp\\pixis_256e\\init_kinetics.exe"
strconstant reset_kinetics = "c:\\users\\hera\\desktop\\tip_exp\\pixis_256e\\reset_kinetics.exe"

strconstant current_folder = "root:pixis_256e:current"
strconstant calibration_folder = "root:pixis_256e:calibration"
strconstant data_folder = "root:pixis_256e:data"

static function check_folder(data_folder)
	string data_folder
	if (!datafolderexists(data_folder))
		newdatafolder $data_folder
	endif
end

function/s gv_path()
	return gv_folder
end

function initialise()
	string gvs = "root:global_variables"
	check_folder(gvs)
	check_folder(gv_folder)
	check_folder("root:pixis_256e")
	check_folder(current_folder)
	check_folder(calibration_folder)
	check_folder(data_folder)
	
	getfilefolderinfo/p=home/q/z "pixis_256e"
	string/g $(gv_folder + ":pixis_path") = s_path
	if (!waveexists($(current_folder + ":wavelength")))
		load_calibration()
	endif
end

function reset(hCam)
	variable hCam
	executescripttext/b/w=0.01/z reset_kinetics + " -h " + num2str(hCam)
end

function ready(exp_time)
	variable exp_time
	variable/g root:pixis_256e:current:exp_time = exp_time
	executescripttext/B/W=0.01/Z kinetics + " -t " + num2istr(exp_time)
end

function read()
	svar pixis_path = $(gv_folder + ":pixis_path")
	GBLoadWave/Q/O/N=temp/T={80,80}/W=1/B pixis_path + "image.raw"
	//GBLoadWave/Q/O/N=temp/T={80,80}/W=1/B "C:Users:Hera:Desktop:Tip_Exp:pixis_256e:image.raw"
	redimension/n=(1024,256) temp0
	duplicate/o temp0, $(current_folder + ":image")
	killwaves temp0
	duplicate/o $(current_folder + ":image"), $(current_folder + ":image_raw")
	correct_pixis()
	scale_kinetics()
	if (waveexists($(current_folder + ":bkgd_image")) && waveexists($(current_folder + ":ref_image")))
		normalise_image()
	endif
end

function display_image()
	dowindow/k pixis
	display/n=pixis
	appendimage/w=pixis $(current_folder + ":image")
	modifyimage image ctab= {*,*,Geo,0}, ctabAutoscale=1, lookup= $""
	label left "wavelength (\\U)"; label bottom "time (\\U)"	
end

function capture_image(exp_time)
	variable exp_time
	variable/g $(gv_folder + ":exp_time") = exp_time
	executescripttext/B init_kinetics + " -t " + num2str(exp_time)
	read()
end

function scale_kinetics()
	wave image = $(current_folder + ":image")
	//ImageRotate/O/V image
	matrixtranspose image
	// timing
	nvar exp_time = $(gv_folder + ":exp_time")
	variable shiftrate = 9.2e-6, windowsize = 1
	variable resolution = (exp_time*1e-6 + shiftrate)/windowsize
	setscale/P x, 0, resolution, "s", image
	// make separate timing wave
	make/o/n=(dimsize(image, 0)) $(current_folder + ":timing")
	wave timing = $(current_folder + ":timing")
	timing = resolution*x
	setscale d, 0, 0, "s", timing
	// wavelength
	if (waveexists($(current_folder + ":wavelength")))
		wave wavelength = $(current_folder + ":wavelength")
		setscale/i y, wavelength[0], wavelength[numpnts(wavelength)-2], "m", image
	endif
end

function correct_pixis()
	wave image = $(current_folder + ":image")
	deletepoints/M=0 250, 6, image			// remove end exposure
	image[0,2][] = 530						// remove initial exposure
end

// BACKGROUND / REFERENCE ACQUISITION //

function read_bkgd(exp_time)
	variable exp_time
	//capture_image(exp_time)
	ready(exp_time);sleep/s 5; read()
	duplicate/o $(current_folder + ":image"), $(current_folder + ":bkgd_image")
	// Automatic creation of background spectrum
	wave bkgd_image = $(current_folder + ":bkgd_image")
	average(bkgd_image, dimsize(bkgd_image,0))
	make/o/n=(dimsize(bkgd_image,1)) $(current_folder + ":bkgd")
	wave bkgd = $(current_folder + ":bkgd")
	bkgd[]=bkgd_image[250][p]
end

function read_ref(exp_time)
	variable exp_time
	//capture_image(exp_time)
	ready(exp_time);sleep/s 5; read()
	duplicate/o $(current_folder + ":image"), $(current_folder + ":ref_image")
	// Automatic creation of reference spectrum
	wave ref_image = $(current_folder + ":ref_image")
	average(ref_image, dimsize(ref_image,0))
	make/o/n=(dimsize(ref_image,1)) $(current_folder + ":ref")
	wave ref = $(current_folder + ":ref")
	ref[]=ref_image[250][p]
end

function average(image, rows)
	wave image
	variable rows
	redimension/s image
	variable j, k
	make/free/o/n=(dimsize(image, 1)) temp = 0
	for (j = 0; j < dimsize(image,0); j += rows)
		k = 0
		do
			temp[] += image[j+k][p]
			k += 1
		while (k < rows)
		temp /= rows
		k = 0
		do
			image[j+k][] = temp[q]
			k += 1
		while (k < rows)
		temp = 0
	endfor
end

// REFERENCE NORMALISATION //

function normalise_image()
	wave image = $(current_folder + ":image")
	wave bkgd = $(current_folder + ":bkgd_image")
	wave ref = $(current_folder + ":ref_image")
	redimension/s image; redimension/s bkgd; redimension/s ref
	
	duplicate/free ref, t_ref
	image -= bkgd
	t_ref -= bkgd
	image /= t_ref
	
	if (0)
		variable j, k
		for (j = 0; j < dimsize(image,0); j += 1)
			for (k = 0; k < dimsize(image,1); k += 1)
				image[j][k] -= bkgd[k]
				image[j][k] /= (ref[k]-bkgd[k])
			endfor
		endfor
	endif
end

function load_calibration()
	// requires the calibration to be stored in the correct location - see data path definition in "data_handling"
	loadwave/q/h/o/p=data ":calibrations:pixis_wavelength.ibw"
	wave wavelength
	//wavelength *= 1e-9
	setscale d 0,0,"m", wavelength
	movewave wavelength, $(current_folder + ":wavelength")
end

// Panel //

function image_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch( ba.eventcode )
		case 2: // mouse up
			nvar exp_time = $(gv_folder + ":exp_time")
			capture_image(exp_time)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

function live_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch( ba.eventcode )
		case 2: // mouse up
			//live code
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

function arm_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch( ba.eventcode )
		case 2: // mouse up
			nvar exp_time = $(gv_folder + ":exp_time")
			ready(exp_time)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

Function read_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			read()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function get_bkgd_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			nvar exp_time = $(gv_folder + ":exp_time")
			read_bkgd(exp_time)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function get_ref_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			nvar exp_time = $(gv_folder + ":exp_time")
			read_ref(exp_time)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function clear_bkgd_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			killwaves $(current_folder + ":bkgd_image"), $(current_folder + ":bkgd")
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function clear_ref_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			killwaves $(current_folder + ":ref_image"), $(current_folder + ":ref")
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function pixis_256e() : Panel
	initialise()
	// prepare panel with initial image
	capture_image(100e-6)
	// create panel
	dowindow/k pixis_256e
	newpanel/n=pixis_256e/w=(436,112,933,456) as "pixis 256e"
	ModifyPanel frameStyle=1
	ShowTools/A
	Button image,pos={4,3},size={50,20},proc=image_button,title="Image",fSize=11
	Button live,pos={55,4},size={50,20},proc=live_button,title="Live",fSize=11
	SetVariable setexp,pos={106,6},size={134,16},bodyWidth=60,title="Exposure Time"
	SetVariable setexp,fSize=11
	SetVariable setexp,limits={0,1000,1},value= $(gv_folder + ":exp_time")
	Button get_bkgd,pos={6,25},size={90,20},proc=get_bkgd_button,title="Get Background"
	Button get_bkgd,fSize=11
	Button get_ref,pos={107,26},size={90,20},proc=get_ref_button,title="Get Reference"
	Button get_ref,fSize=11
	Button clear_bkgd,pos={6,45},size={100,20},proc=clear_bkgd_button,title="Clear Background"
	Button clear_bkgd,fSize=11
	Button clear_ref,pos={107,46},size={100,20},proc=clear_ref_button,title="Clear Reference"
	Button clear_ref,fSize=11
	Button arm,pos={217,47},size={50,20},proc=arm_button,title="Arm",fSize=11
	Button read,pos={269,46},size={50,20},proc=read_button,title="Read",fSize=11
	Display/W=(8,70,491,336)/HOST=# 
	AppendImage $(current_folder + ":image")
	ModifyImage Image ctab= {*,*,Geo,0}
	ModifyImage Image ctabAutoscale=1
	ModifyGraph frameStyle=1
	ModifyGraph mirror=2
	Label left "wavelength (\\U)"
	Label bottom "time (\\U)"
	RenameWindow #,G0
	SetActiveSubwindow ##
end

function/c insert_pixis_panel(left, top) : panel
	variable left, top
	
	dfref gv_path = $gv_folder
	
	variable l_size = 350, t_size = 50
	groupbox pixis_group, pos={left, top}, size={l_size, t_size}, frame=0, title="PIXIS 256E"
	groupbox pixis_group, labelBack=(56576,56576,56576), fsize=12, fStyle=1
	left += 5; top += 17
	
	// buttons
	titlebox pixis_controls title="PIXIS Controls", pos={left, top}, frame=0, fSize=11, fstyle=1
	// set and display variables
	left += 90
	titlebox pixis_set title="Set Parameters", pos={left, top}, frame=0, fSize=11, fstyle=1
	// display only values
	left += 135
	titlebox pixis_display title="Display Parameters", pos={left, top}, frame=0, fSize=11, fstyle=1
	
	return cmplx(l_size, t_size)
end