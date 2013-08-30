#pragma ModuleName = tip_control
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "data_handling"
#include "pi_pi733_3cd_stage"
#include "newport_actuators"
#include "hp33120a_sig_gen"
#include "tip_alignment_lockin"

menu "Panels"
	"Tip Control and Alignment", dowindow/f tip_control
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

function set_set_points_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			nvar/sdfr=$(pi_stage#gv_path()) pos_a, pos_b, pos_c
			nvar/sdfr=$(tip_alignment#gv_path()) set_point_a, set_point_b, set_point_c
			set_point_a = pos_a
			set_point_b = pos_b
			set_point_c = pos_c
			nvar/sdfr=grid_scan#gv_path() set_point_a, set_point_b, set_point_c
			set_point_a = pos_a
			set_point_b = pos_b
			set_point_c = pos_c
			break
		case -1:
			break
	endswitch
	return 0
end

// Panel //

static function/c insert_alignment_panel(left, top) : panel
	variable left, top
	
	//dfref gv_path = $gv_folder
	
	sig_gen#open_comms()
	sig_gen#initialise()
	sig_gen#close_comms()
	tip_alignment#initialise()
	
	// alignment controls
	variable l_size = 340, t_size = 180
	groupbox alignment_group, pos={left, top}, size={l_size, t_size}, title="Tip Alignment"
	groupbox alignment_group, labelBack=(56576,56576,56576), fStyle=1
	// alignment variables and controls
	// column 1
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
	setvariable set_elec_align, pos={left, top}, size={105,15}, bodyWidth=30, title="Electronics"
	setvariable set_elec_align, limits={0,1,1}, value= root:global_variables:tip_alignment:electronic_alignment
	top += 20
	setvariable set_force_align, pos={left, top}, size={105,15}, bodyWidth=30, title="Force"
	setvariable set_force_align, limits={0,1,1}, value= root:global_variables:tip_alignment:force_alignment
	
	top += 20
	setvariable set_set_point_a, pos={left, top}, size={105,15}, bodyWidth=50, title="Set Point A"
	setvariable set_set_point_a, value= root:global_variables:tip_alignment:set_point_a
	top += 20
	setvariable set_set_point_b, pos={left, top}, size={105,15}, bodyWidth=50, title="Set Point B"
	setvariable set_set_point_b, value= root:global_variables:tip_alignment:set_point_b
	top += 20
	setvariable set_set_point_c, pos={left, top}, size={105,15}, bodyWidth=50, title="Set Point C"
	setvariable set_set_point_c, value= root:global_variables:tip_alignment:set_point_c
	
	// column 2
	left += 110; top -= 7*20
	// resonance scan controls
	setvariable set_freq_start, pos={left, top}, size={105,15}, bodyWidth=50, title="Freq: Start"
	setvariable set_freq_start, value= root:global_variables:tip_alignment:freq_start
	top += 20
	setvariable set_freq_stop, pos={left, top}, size={105,15}, bodyWidth=50, title="Freq: Stop"
	setvariable set_freq_stop, value= root:global_variables:tip_alignment:freq_stop
	top += 20
	setvariable set_freq_inc, pos={left, top}, size={105,15}, bodyWidth=50, title="Freq: Step"
	setvariable set_freq_inc, value= root:global_variables:tip_alignment:freq_inc
	top += 20
	
	left += 110; top -= 20
	button res_scan, pos={left, top}, size={70,40}, proc=resonance_scan_button, title="Resonance\rScan"
	button res_scan, fColor=(65280,65280,0)
	// this will need to be moved in the future - start
	left += 70
	button sine_button, pos={left, top}, size={40,20}, proc=output_sine_button, title="Sine"
	left -= 70
	// end
	left -=110; top += 20
	
	// buttons
	button align_tips, pos={left, top}, size={50,40}, proc=align_tips_button, title="Align\rTips"
	button align_tips, fColor=(65280,65280,0)
	left += 50
	button centre_tips, pos={left, top}, size={50,40}, proc=move_to_centre_button, title="Move to\rCentre"
	button centre_tips, fColor=(32768,65280,0)
	left -= 50; top += 40
	button set_set_points, pos={left, top}, size={100,20}, proc=set_set_points_button, title="Set Set Points"
	button set_set_points, fColor=(32768,65280,0)
	top += 20
	string align_path = tip_alignment#gv_path()
	valdisplay cent_b, pos={left, top}, size={100,20}, title="cent. ht. (b)"
	string b = align_path + ":x0"
	valdisplay cent_b, value= #b; top += 20
	valdisplay cent_c, pos={left, top}, size={100,20}, title="cent. f. (c)"
	string c = align_path + ":y0"
	valdisplay cent_c, value= #c
	
	// column 3 //
	left += 110; top -= 7*20
	// hp signal generator controls
	setvariable x20_amplitude, pos={left, top}, size={105,15}, bodyWidth=50, proc=set_x20_amplitude_panel, title="Amplitude"
	//setvariable x20_amplitude, value= root:global_variables:hp33120a_signal_generator:amplitude
	setvariable x20_amplitude, value= root:global_variables:tip_alignment:amplified_voltage
	top += 20
	setvariable frequency, pos={left, top}, size={105,15}, bodyWidth=50, proc=sig_gen#set_frequency_panel, title="Frequency"
	setvariable frequency, value= root:global_variables:hp33120a_signal_generator:frequency
	top += 40
	top += 20
	// electronic alignment buttons //
	button fit_x, pos={left, top}, size={30,20}, proc=fit_alignment_data_x_button, title="Fit X"; left += 30
	button fit_y, pos={left, top}, size={30,20}, proc=fit_alignment_data_y_button, title="Fit Y"; left += 30
	button fit_r, pos={left, top}, size={30,20}, proc=fit_alignment_data_r_button, title="Fit R"
	left -= 30*2; top += 20
	button fit_theta, pos={left, top}, size={50,20}, proc=fit_alignment_data_theta_button, title="Fit Theta"; left += 50
	left -= 50; top += 20
	// force alignment buttons //
	button fit_fx, pos={left, top}, size={35,20}, proc=fit_alignment_data_fx_button, title="Fit FX"; left += 35
	button fit_fy, pos={left, top}, size={35,20}, proc=fit_alignment_data_fy_button, title="Fit FY"
	left -= 35; top += 20
	button fit_fr, pos={left, top}, size={35,20}, proc=fit_alignment_data_fr_button, title="Fit FR"; left += 35
	button fit_ftheta, pos={left, top}, size={60,20}, proc=fit_alignment_data_fthet_button, title="Fit FTheta"
	left -= 35
	
	return cmplx(l_size, t_size)
end

function tip_control_and_alignment() : panel
	variable left, right, top, bottom
	dowindow/k tip_control
	
	// MAIN PANEL //
	// panel layout
	newpanel/w=(50,20,400,600)/n=tip_control as "Tip Control and Alignment"
	modifypanel cbRGB=(60928,60928,60928), framestyle=1
	setdrawlayer UserBack
	showtools/a
	
	// title
	left = 5; top = 5
	titlebox title, pos={left,top}, size={130,25}, title="Tip Control and Alignment"
	top += 25
	variable/c size
	
	// newport actuators
	size = actuators#insert_actuators_panel(left, top)
	top += imag(size) + 5
	// pi stage
	size = pi_stage#insert_pi_stage_panel(left, top)
	top += imag(size) + 5
	// tip alignment
	size = tip_control#insert_alignment_panel(left, top)
	top += imag(size) + 5
	left = real(size) + 5
	
	movewindow/w=tip_control 50, 20, left-30, top-130
end