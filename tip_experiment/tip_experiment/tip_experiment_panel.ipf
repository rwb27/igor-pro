#pragma modulename = tip_panel
#pragma version = 6.31
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "keithley_2635a_smu"
#include "agilent_dsox2000_series_dso"
#include "princeton_instruments_pixis_256e_ccd"
#include "tip_experiment"

static strconstant gv_folder = "root:global_variables:tip_experiment"

// Panel Controls

static function tip_scan_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch(ba.eventcode)
		case 2:
			tip_exp#tip_scan()
			break
	endswitch
	return 0
end

static function restore_defaults_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch(ba.eventcode)
		case 2:
			tip_exp_init#restore_default_values()
			break
	endswitch
	return 0
end

function set_scan_direction(pa) : popupmenucontrol
	struct wmpopupaction &pa
	switch(pa.eventcode)
		case 2: // mouse up
			variable popnum = pa.popnum
			string popstr = pa.popstr
			nvar/sdfr=$gv_folder scan_direction
			if (stringmatch(popstr, "Approach"))
				scan_direction = -1
			elseif (stringmatch(popstr, "Retract"))
				scan_direction = 1
			endif
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end


// Other Panels

static function/c insert_exp_panel(left, top) : panel
	variable left, top
	
	dfref gv_path = $gv_folder
	
	variable l_size = 350, t_size = 120
	groupbox exp_group, pos={left, top}, size={l_size, t_size}, frame=0, title="Experiment"
	groupbox exp_group, labelBack=(56576,56576,56576), fsize=12, fStyle=1
	left += 5; top += 17
	
	// buttons
	titlebox exp_controls title="Exp. Controls", pos={left, top}, frame=0, fSize=11, fstyle=1
	top += 17
	button exp_tip_scan,pos={left, top}, size={60,20}, proc=tip_panel#tip_scan_button, title="Tip Scan"
	button exp_tip_scan, fColor=(32768,65280,0)
	top += 20
	button exp_defaults,pos={left, top}, size={60,30}, proc=tip_panel#restore_defaults_button, title="Restore\rDefaults"
	top -= 17 + 20
	// set and display variables
	left += 90
	titlebox exp_scan_params title="Scan Parameters", pos={left, top}, frame=0, fSize=11, fstyle=1
	top += 17
	setvariable exp_set_append, pos={left, top}, size={135,15}, bodywidth=70, title="append mode"
	setvariable exp_set_append, value=gv_path:append_mode
	top += 17
	setvariable exp_scan_size, pos={left, top}, size={135,15}, bodywidth=70, title="scan size (um)"
	setvariable exp_scan_size, value=gv_path:scan_size
	top += 17
	setvariable exp_scan_step, pos={left, top}, size={135,15}, bodywidth=70, title="scan step (um)"
	setvariable exp_scan_step, value=gv_path:scan_step
	top += 17
	//setvariable exp_scan_direction, pos={left, top}, size={135,15}, bodywidth=70, title="scan direction"
	//setvariable exp_scan_direction, limits={-1,1,2}, value=gv_path:scan_direction
	popupmenu exp_scan_direction, pos={left, top}, size={135,15}, bodywidth=70, title="scan_direction",value="Approach;Retract"
	popupmenu exp_scan_direction fSize=11, proc=set_scan_direction
	top += 17
	top -= 17*5
	// display only values
	left += 135
	titlebox exp_params title="Exp. Parameters", pos={left, top}, frame=0, fSize=11, fstyle=1
	top += 17
	setvariable exp_set_trig_g0, pos={left, top}, size={105,15}, bodywidth=60, title="trig (G\B0\M)"
	setvariable exp_set_trig_g0, value=gv_path:trig_g0
	top += 17
	setvariable exp_set_vis_g0, pos={left, top}, size={105,15}, bodywidth=60, title="vis (G\B0\M)"
	setvariable exp_set_vis_g0, value=gv_path:vis_g0
	top += 17
	//left -= 135; top -= 17*3
	//top += 17*5
	titlebox exp_display title="Display Parameters", pos={left, top}, frame=0, fSize=11, fstyle=1
	top += 17
	valdisplay exp_current_step, pos={left, top}, size={115,15}, bodyWidth=50, title="current step"
	valdisplay exp_current_step, limits={0,0,0}, barmisc={0,1000}
	valdisplay exp_current_step, value= #"root:global_variables:tip_experiment:current_step"
	
	return cmplx(l_size, t_size)
end

// Panel //

function tip_scan_panel() : panel
	variable left, right, top, bottom
	dowindow/k tip_scanning_panel
	
	// panel layout
	newpanel/w=(500,50,900,750)/n=tip_scanning_panel as "Tip Scanning"
	modifypanel cbRGB=(60928,60928,60928), framestyle=1
	setdrawlayer UserBack
	showtools/a
	
	// title
	left = 5; top = 5
	titlebox title, pos={left,top}, size={130,25}, title="Tip Scanning", fsize=14, fstyle=1, frame=0
	top += 20
	
	variable/c size
	
	// exp
	size = insert_exp_panel(left, top)
	top += imag(size) + 5
	// smu
	size = smu#insert_smu_panel(left, top)
	top += imag(size) + 5
	// dso
	size = dso#insert_dso_panel(left, top)
	top += imag(size) + 5
	// tek
	// pi stage
	// pixis
	size = pixis#insert_pixis_panel(left, top)
	top += imag(size) + 5
end