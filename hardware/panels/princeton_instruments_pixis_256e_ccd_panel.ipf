#pragma rtGlobals=1		// Use modern global access method.
#include "princeton_instruments_pixis_256e_ccd"

strconstant gv_folder = "root:global_variables:pi_pi733_3cd_stage"
strconstant current_folder = "root:pixis_256e:current"
strconstant calibration_folder = "root:pixis_256e:calibration"
strconstant data_folder = "root:pixis_256e:data"

Function image_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			nvar exp_time = $(gv_folder + ":exp_time")
			pixis#image(exp_time)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function live_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			//live code
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function arm_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			nvar exp_time = $(gv_folder + ":exp_time")
			pixis#ready(exp_time)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function read_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			pixis#read()
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
			pixis#read_bkgd(exp_time)
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
			pixis#read_ref(exp_time)
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

window pixis_256e() : Panel
	// prepare panel with initial image
	pixis#image(100e-6)
	// create panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(436,112,933,456) as "PIXIS 256E"
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
endmacro