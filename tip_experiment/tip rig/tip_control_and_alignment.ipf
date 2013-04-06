#pragma ModuleName = tip_control
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "data_handling"
#include "pi_pi733_3cd_stage"
#include "newport_actuators"
#include "hp33120a_sig_gen"
#include "tip_alignment"

function starting_pos()
	pi_stage#open_comms()
	pi_stage#move("a", 50)
	pi_stage#move("b", 50)
	pi_stage#move("c", 5)
	pi_stage#close_comms()
end

function starting_pos_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			starting_pos()
			break
		case -1:
			break
	endswitch
	return 0
end

function set_x20_amplitude_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			nvar volt = $(sig_gen#gv_path() + ":amplitude")
			sig_gen#open_comms()
			sig_gen#set_amplitude(volt/20)
			sig_gen#close_comms()
			break
		case -1:
			break
	endswitch
	return 0
end

function set_x20_amplitude_panel(sva) : setvariablecontrol
	struct wmsetvariableaction &sva
	switch( sva.eventcode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
			sig_gen#open_comms()
			sig_gen#set_amplitude(dval/20)
			sig_gen#close_comms()
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

// Panel //

function tip_control_and_alignment() : panel
	variable left, right, top, bottom
	dowindow/k tip_control
	
	actuators#open_comms()
	pi_stage#open_comms()
	sig_gen#open_comms()
	actuators#initialise()
	pi_stage#initialise()
	sig_gen#initialise()
	actuators#close_comms()
	pi_stage#close_comms()
	sig_gen#close_comms()
	alignment#initialise()
	
	// panel layout
	newpanel/w=(500,80,850,660)/n=tip_control as "Tip Control and Alignment"
	modifypanel cbRGB=(60928,60928,60928), framestyle=1
	setdrawlayer UserBack
	showtools/a
	
	// title
	left = 5; top = 5
	titlebox title, pos={left,top}, size={130,25}, title="Tip Control and Alignment"
	
	// newport actuators
	top = 30
	variable l_size = 340, t_size = 195 - top
	groupbox newport_group, pos={left, top}, size={l_size, t_size}, title="Newport NanoPZ/HLX Actuators"
	groupbox newport_group, labelBack=(56576,56576,56576), fStyle=1
		// buttons
	left = 10; top += 20
	button startup_actuators, pos={left, top}, size={60,20}, proc=actuators#startup_button, title="Startup"
	button startup_actuators, fColor=(32768,65280,0)
	top += 20
	button shutdown_actuators, pos={left, top}, size={60,20}, proc=actuators#shutdown_button, title="Shutdown"
	button shutdown_actuators, fColor=(65280,0,0)
	top += 20
	button actuators_update, pos={left,top}, size={60,20}, proc=actuators#update_button, title="Update"
	top += 20
	button init_actuators, pos={left,top}, size={60,20}, proc=actuators#init_button, title="Initialise"
		// position display
	left += 65; top -= 60
	valdisplay actuator_x, pos={left, top}, size={110,15}, bodyWidth=60, title="height (x)"
	valdisplay actuator_x, limits={0,0,0}, barmisc={0,1000}
	valdisplay actuator_x, value= #"root:global_variables:newport_actuators_x:pos_x"
	top += 20
	valdisplay actuator_y, pos={left, top}, size={110,15}, bodyWidth=60, title="focus (y)"
	valdisplay actuator_y, limits={0,0,0}, barmisc={0,1000}
	valdisplay actuator_y, value= #"root:global_variables:newport_actuators_y:pos_y"
	top += 20
	valdisplay actuator_z, pos={left, top}, size={110,15}, bodyWidth=60, title="lateral (z)"
	valdisplay actuator_z, limits={0,0,0}, barmisc={0,1000}
	valdisplay actuator_z, value= #"root:global_variables:newport_actuators_z:pos_z"
		// step display
	left += 115; top -= 40
	setvariable actuators_step_x, pos={left, top}, size={92,15}, bodyWidth=60, title="ht step"
	setvariable actuators_step_x, value= root:global_variables:newport_actuators_x:step_x
	top += 20
	setvariable actuators_step_y, pos={left, top},size={92,15},bodyWidth=60,title="f step"
	setvariable actuators_step_y, value= root:global_variables:newport_actuators_y:step_y
	top += 20
	setvariable actuators_step_z, pos={left, top},size={92,15},bodyWidth=60,title="lat step"
	setvariable actuators_step_z, value= root:global_variables:newport_actuators_z:step_z
		// movement controls
	left = 190; top += 20
	variable t_spacer = 25, l_spacer = 50, t_spacer2 = t_spacer + 5
	variable up_l = left + l_spacer, up_t = top, in_l = left + 2*l_spacer, in_t = top	// top row
	variable left_l = left, left_t = top + t_spacer2, right_l = left + 2*l_spacer, right_t = top + t_spacer2	// middle row
	variable out_l = left, out_t = top + 2*t_spacer, down_l = left + l_spacer, down_t = top + 2*t_spacer	// bottom row
	button actuators_left, pos={left_l, left_t}, size={50,20}, proc=actuators#move_left_button, title="Left"
	button actuators_focusout, pos={out_l, out_t}, size={50,30}, proc=actuators#move_focusdown_button, title="Focus\rOut"
	button actuators_down, pos={down_l, down_t}, size={50,20}, proc=actuators#move_down_button, title="Down"
	button actuators_up, pos={up_l, up_t}, size={50,20}, proc=actuators#move_up_button, title="Up"
	button actuators_right, pos={right_l, right_t}, size={50,20}, proc=actuators#move_right_button, title="Right"
	button actuators_focusin, pos={in_l, in_t}, size={50,30}, proc=actuators#move_focusup_button, title="Focus\rIn"
	
	// pi stage
	left = 5; top = 200
	l_size = 340; t_size = 405 - top
	groupbox pi_group,pos={left, top},size={l_size, t_size},title="PI PI733.3CD Stage"
	groupbox pi_group, labelBack=(56576,56576,56576), fStyle=1
		// main buttons
	left += 5; top += 20
	button startup_stage ,pos={left, top}, size={60,20}, proc=pi_stage#startup_button, title="Startup"
	button startup_stage, fColor=(32768,65280,0)
	top += 20
	button shutdown_stage, pos={left, top}, size={60,20}, proc=pi_stage#shutdown_button, title="Shutdown"
	button shutdown_stage, fColor=(65280,0,0)
	top += 20
	button stage_update, pos={left, top}, size={60,20}, proc=pi_stage#update_button, title="Update"
	top += 20
	button stage_starting_pos, pos={left, top}, size={60,30}, proc=starting_pos_button, title="Starting\rPositions"
	
		// position display
	top += 40
	setvariable stage_pos_a, pos={left, top}, size={70,15}, bodyWidth=55, proc=pi_stage#set_position_a_panel, title="A"
	setvariable stage_pos_a, value= _NUM:20//root:global_variables:pi_pi733_3cd_stage:pos_a
	top += 20
	setvariable stage_pos_b, pos={left, top}, size={70,15}, bodyWidth=55, proc=pi_stage#set_position_b_panel, title="B"
	setvariable stage_pos_b, value= _NUM:20//root:global_variables:pi_pi733_3cd_stage:pos_b
	top += 20
	setvariable stage_pos_c, pos={left, top}, size={70,15}, bodyWidth=55, proc=pi_stage#set_position_c_panel, title="C"
	setvariable stage_pos_c, value= _NUM:5//root:global_variables:pi_pi733_3cd_stage:pos_c
	
		// position display
	left += 65; top -= 60 + 80
	valdisplay stage_a, pos={left, top}, size={110,15}, bodyWidth=60, title="lateral (a)"
	valdisplay stage_a, limits={0,0,0}, barmisc={0,1000}
	valdisplay stage_a, value= #"root:global_variables:pi_pi733_3cd_stage:pos_a"
	top += 20
	valdisplay stage_b, pos={left, top}, size={110,15}, bodyWidth=60, title="height (b)"
	valdisplay stage_b, limits={0,0,0}, barmisc={0,1000}
	valdisplay stage_b, value= #"root:global_variables:pi_pi733_3cd_stage:pos_b"
	top += 20
	valdisplay stage_c,pos={left, top},size={110,15},bodyWidth=60,title="focus (c)"
	valdisplay stage_c,limits={0,0,0},barmisc={0,1000}
	valdisplay stage_c,value= #"root:global_variables:pi_pi733_3cd_stage:pos_c"
		// velocity display
	top += 20
	setvariable stage_vel_a, pos={left, top}, size={109,16}, bodyWidth=60, proc=pi_stage#set_velocity_a_panel,title="a-velocity"
	setvariable stage_vel_a, value= root:global_variables:pi_pi733_3cd_stage:vel_a
	top += 20
	setvariable stage_vel_b, pos={left, top}, size={109,16}, bodyWidth=60, proc=pi_stage#set_velocity_b_panel,title="b-velocity"
	setvariable stage_vel_b, value= root:global_variables:pi_pi733_3cd_stage:vel_b
	top += 20
	setvariable stage_vel_c, pos={left, top}, size={109,16}, bodyWidth=60, proc=pi_stage#set_velocity_c_panel,title="c-velocity"
	setvariable stage_vel_c, value= root:global_variables:pi_pi733_3cd_stage:vel_c
		// dco display
	top += 20
	setvariable stage_dco_a, pos={left, top}, size={109,16}, bodyWidth=60, proc=pi_stage#set_dco_a_panel, title="a-dco"
	setvariable stage_dco_a, value= root:global_variables:pi_pi733_3cd_stage:dco_a
	top += 20
	setvariable stage_dco_b, pos={left, top}, size={109,16}, bodyWidth=60, proc=pi_stage#set_dco_b_panel, title="b-dco"
	setvariable stage_dco_b, value= root:global_variables:pi_pi733_3cd_stage:dco_b
	top += 20
	setvariable stage_dco_c, pos={left, top}, size={109,16}, bodyWidth=60, proc=pi_stage#set_dco_c_panel, title="c-dco"
	setvariable stage_dco_c, value= root:global_variables:pi_pi733_3cd_stage:dco_c
		// step display
	left += 115; top -= 160
	setvariable stage_step_a, pos={left, top}, size={93,16}, bodyWidth=60, title="a-step"
	setvariable stage_step_a, value= root:global_variables:pi_pi733_3cd_stage:step_a
	top += 20
	setvariable stage_step_b, pos={left, top}, size={93,16}, bodyWidth=60, title="b-step"
	setvariable stage_step_b, value= root:global_variables:pi_pi733_3cd_stage:step_b
	top += 20
	setvariable stage_step_c, pos={left, top}, size={93,16}, bodyWidth=60, title="c-step"
	setvariable stage_step_c, value= root:global_variables:pi_pi733_3cd_stage:step_c
		// movement control
	left = 190; top += 20
	t_spacer = 25; l_spacer = 50; t_spacer2 = t_spacer + 5
	up_l = left + l_spacer; up_t = top; in_l = left + 2*l_spacer; in_t = top	// top row
	left_l = left; left_t = top + t_spacer2; right_l = left + 2*l_spacer; right_t = top + t_spacer2	// middle row
	out_l = left; out_t = top + 2*t_spacer; down_l = left + l_spacer; down_t = top + 2*t_spacer	// bottom row
	button stage_left, pos={left_l, left_t}, size={50,20}, proc=pi_stage#move_left_button, title="Left"
	button stage_down, pos={down_l, down_t}, size={50,20}, proc=pi_stage#move_down_button, title="Down"
	button stage_up, pos={up_l, up_t}, size={50,20}, proc=pi_stage#move_up_button, title="Up"
	button stage_right, pos={right_l, right_t}, size={50,20}, proc=pi_stage#move_right_button, title="Right"
	button stage_focusin, pos={in_l, in_t}, size={50,30}, proc=pi_stage#move_focusup_button, title="Focus\rIn"
	button stage_focusout, pos={out_l, out_t}, size={50,30}, proc=pi_stage#move_focusdown_button, title="Focus\rOut"
	
	// alignment controls
	left = 5; top = 410
	l_size = 340; t_size = 165
	groupbox alignment_group, pos={left, top}, size={l_size, t_size}, title="Tip Alignment"
	groupbox alignment_group, labelBack=(56576,56576,56576), fStyle=1
		// alignment controls
	left += 5; top += 20
	setvariable set_scan_size, pos={left, top}, size={105,15}, bodyWidth=50, title="Scan Size"
	setvariable set_scan_size, value= root:global_variables:tip_alignment:scan_size
	top += 20
	setvariable set_scan_step, pos={left, top}, size={105,15}, bodyWidth=50, title="Scan Step"
	setvariable set_scan_step, value= root:global_variables:tip_alignment:scan_step
	top += 20
	setvariable set_alignment_set, pos={left, top}, size={105,15}, bodyWidth=50, title="Scan Set"
	setvariable set_alignment_set, value= root:global_variables:tip_alignment:alignment_set
	top += 20
	button align_tips, pos={left, top}, size={50,40}, proc=align_tips_button, title="Align\rTips"
	button align_tips, fColor=(65280,65280,0)
	left += 50
	button centre_tips, pos={left, top}, size={50,40}, proc=move_to_centre_button, title="Move to\rCentre"
	button centre_tips, fColor=(32768,65280,0)
	left -= 50; top += 40
	button fit_x, pos={left, top}, size={30,20}, proc=fit_alignment_data_x_button, title="Fit X"; left += 30
	button fit_y, pos={left, top}, size={30,20}, proc=fit_alignment_data_y_button, title="Fit Y"; left += 30
	button fit_r, pos={left, top}, size={30,20}, proc=fit_alignment_data_r_button, title="Fit R"
	left -= 60; top += 20
	button fit_theta, pos={left, top}, size={50,20}, proc=fit_alignment_data_theta_button, title="Fit Theta"; left += 50
	button fit_y_psd, pos={left, top}, size={50,20}, proc=fit_alignment_data_Y_psd_button, title="Fit yPSD"; left += 60
	top -= 20
	string align_path = alignment#gv_path()
	valdisplay cent_b, pos={left, top}, size={100,20}, title="cent. ht. (b)"
	string b = align_path + ":x0"
	valdisplay cent_b, value= #b; top += 20
	valdisplay cent_c, pos={left, top}, size={100,20}, title="cent. f. (c)"
	string c = align_path + ":y0"
	valdisplay cent_c, value= #c
	left -= 110; top -= 80
		// resonance scan controls
	left += 110; top -= 40
	setvariable set_freq_start, pos={left, top}, size={105,15}, bodyWidth=50, title="Freq: Start"
	setvariable set_freq_start, value= root:global_variables:tip_alignment:freq_start
	top += 20
	setvariable set_freq_stop, pos={left, top}, size={105,15}, bodyWidth=50, title="Freq: Stop"
	setvariable set_freq_stop, value= root:global_variables:tip_alignment:freq_stop
	top += 20
	setvariable set_freq_inc, pos={left, top}, size={105,15}, bodyWidth=50, title="Freq: Step"
	setvariable set_freq_inc, value= root:global_variables:tip_alignment:freq_inc
	top += 20
	button res_scan, pos={left, top}, size={70,40}, proc=resonance_scan_button, title="Resonance\rScan"
	button res_scan, fColor=(65280,65280,0)
		// hp signal generator controls
	left += 110; top -= 3*20
	setvariable x20_amplitude, pos={left, top}, size={105,15}, bodyWidth=50, proc=set_x20_amplitude_panel, title="Amplitude"
	//setvariable x20_amplitude, value= root:global_variables:hp33120a_signal_generator:amplitude
	setvariable x20_amplitude, value= root:global_variables:tip_alignment:amplified_voltage
	top += 20
	setvariable frequency, pos={left, top}, size={105,15}, bodyWidth=50, proc=sig_gen#set_frequency_panel, title="Frequency"
	setvariable frequency, value= root:global_variables:hp33120a_signal_generator:frequency
end