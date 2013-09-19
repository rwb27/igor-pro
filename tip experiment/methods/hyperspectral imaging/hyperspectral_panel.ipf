#pragma ModuleName = hs_panel
#pragma version = 6.32
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "hyperspectral_display"
#include "analysis_tools"

static strconstant gv_folder = "root:global_variables:hyperspectral_imaging"

function display_scan_button(ba) : ButtonControl
	struct wmbuttonaction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			nvar/sdfr=$gv_folder selected_wavelength
			svar/sdfr=$gv_folder selected_scan
			dfref sf = $selected_scan
			hs_display#display_scan(sf, selected_wavelength)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

function display_sum_button(ba) : ButtonControl
	struct wmbuttonaction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			svar/sdfr=$gv_folder selected_scan
			dfref sf = $selected_scan
			hs_display#display_sum(sf)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

//function display_analysis_button(ba) : ButtonControl
//	struct wmbuttonaction &ba
//	switch( ba.eventCode )
//		case 2: // mouse up
//			nvar wavelength = $(gv_folder + ":wavelength")
//			svar image = $(gv_folder + ":image")
//			wave hs_data = $(image + ":hyperspec_image")
//			analyse_scan(hs_data, wavelength)
//			break
//		case -1: // control being killed
//			break
//	endswitch
//	return 0
//end
//
//function display_multi_analysis_button(ba) : ButtonControl
//	struct wmbuttonaction &ba
//	switch( ba.eventCode )
//		case 2: // mouse up
//			nvar wavelength = $(gv_folder + ":wavelength")
//			svar image1 = $(gv_folder + ":image")
//			svar image2 = $(gv_folder + ":image2")
//			wave hs_data1 = $(image1 + ":hyperspec_image")
//			wave hs_data2 = $(image2 + ":hyperspec_image")
//			analyse_multi_scan(hs_data1, hs_data2, wavelength)
//			break
//		case -1: // control being killed
//			break
//	endswitch
//	return 0
//end

function set_scan(sva) : setvariablecontrol
	struct wmsetvariableaction &sva
	switch (sva.eventcode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
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
			dowindow hyperspec
			if (V_flag == 1)
				svar/sdfr=$gv_folder selected_scan
				dfref sf = $selected_scan
				wave/sdfr=sf wavelength
				modifyimage ''#0 plane = wavelength_to_index(wavelength, dval)
				modifyimage ''#1 plane = wavelength_to_index(wavelength, dval)
				textbox/k/n=text0
				textbox/c/n=text0/f=0/b=1/g=(65280,65280,65280)/a=rt "\\Z10\\F'Symbol'l\\F'Arial' = "+num2str(dval)+" nm"
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
				dowindow hyperspec
				if (V_flag == 1)
					svar/sdfr=$gv_folder selected_scan
					dfref sf = $selected_scan
					wave/sdfr=sf wavelength
					modifyimage ''#0 plane = wavelength_to_index(wavelength, curval)
					modifyimage ''#1 plane = wavelength_to_index(wavelength, curval)
					textbox/k/n=text0
					textbox/c/n=text0/f=0/b=1/g=(65280,65280,65280)/a=rt "\\Z10\\F'Symbol'l\\F'Arial' = "+num2str(curval)+" nm"
				endif
			endif
			break
	endswitch
	return 0
end

function hyperspectral_panel() : panel
	// initialise panel variables
	newdatafolder/o root:global_variables
	newdatafolder/o $gv_folder
	dfref gf = $gv_folder
	variable/g gf:selected_wavelength = 633
	string/g gf:selected_scan = ""
	string/g gf:selected_scan_2 = ""
	
	variable left, top, right, bottom
	left = 0; top = 0
	dowindow/k hyperspec_panel
	newpanel/k=1/w=(500,100,750,250)/n=hyperspec_panel as "Hyperspectral Imaging"
	modifypanel frameStyle=1
	showtools/a
	// display scan button
	left += 5; top += 5
	button display_hs, pos={left, top}, size={70,20}, proc=display_scan_button, title="Display Scan"
	button display_hs, fSize=11
	// set image
	left += 75
	setvariable set_hs, pos={left, top}, size={150,20}, proc=set_scan,title="Scan"
	setvariable set_hs, fSize=11
	setvariable set_hs, value= $(gv_folder + ":selected_scan")
	left -= 75
	// set image 2
	top += 25
	left += 75
	setvariable set_hs2, pos={left, top}, size={150,20}, proc=set_scan,title="Scan 2"
	setvariable set_hs2, fSize=11
	setvariable set_hs2, value= $(gv_folder + ":selected_scan_2")
	left -= 75
	// set wavelength
	top += 25
	setvariable set_wlen,pos={left, top},size={130,20},bodyWidth=60,proc=set_wavelength,title="Wavelength"
	setvariable set_wlen,fSize=11
	setvariable set_wlen, limits={450,1000,10}, live=1, value= $(gv_folder + ":selected_wavelength")
	// display sum scan button
	left += 140
	button display_shs, pos={left, top}, size={70,20}, proc=display_sum_button, title="Display Sum"
	button display_shs, fSize=11
	left -= 140
	// set wavelength slide
	top += 20
	slider wl_slider,pos={left, top},size={193,52},proc=wavelength_slider
	slider wl_slider,limits={450,1000,1},variable= $(gv_folder + ":selected_wavelength"),vert= 0
	// display analysis button
	top += 45
	button analyse_hs, pos={left, top}, size={70,20}, proc=display_analysis_button, title="Analysis"
	button analyse_hs, fSize=11
	// display multi analysis button
	left += 75
	button analyse_multi_hs, pos={left, top}, size={80,20}, proc=display_multi_analysis_button, title="Multi-Analysis"
	button analyse_multi_hs, fSize=11
end