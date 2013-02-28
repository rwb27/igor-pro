#pragma ModuleName = tip_exp
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "data_handling"
#include "pi_pi733_3cd_stage"
#include "keithley_2635a_smu"
#include "agilent_dsox2000_series_dso"
#include "tektronix_tds1001b"
#include "princeton_instruments_pixis_256e_ccd"

static constant g0 = 7.7480917e-5
static strconstant gv_folder = "root:global_variables:tip_experiments"

static function initialise()
	data#check_gvpath(gv_folder)
	if (exists((gv_folder + ":append_mode")) == 0)
		string gv_path
		// experiment parameters
		variable/g $(gv_folder + ":append_mode") = 0
		variable/g $(gv_folder + ":scan_step") = 1e-3			// 1 nm steps
		variable/g $(gv_folder + ":scan_size") = 5			// 5 um max
		variable/g $(gv_folder + ":scan_direction") = -1		// approaching
		variable/g $(gv_folder + ":current_set_point") = 1		// 1 A stopping point
		variable/g $(gv_folder + ":trig_g0") = 0.5				// 0.5G0 trigger point
		// amplifier parameters
		gv_path = "root:global_variables:amplifiers"
		data#check_gvpath(gv_path)
		variable/g $(gv_path + ":gain_dso") = 1000
		variable/g $(gv_path + ":gain_force_x") = 50
		variable/g $(gv_path + ":gain_force_y") = 50
		variable/g $(gv_path + ":gain_force_dso") = 50
		variable/g $(gv_path + ":bandwidth_dso") = 500e3
		variable/g $(gv_path + ":bandwidth_force_x") = 0
		variable/g $(gv_path + ":bandwidth_force_y") = 0
		variable/g $(gv_path + ":bandwidth_force_dso") = 500e3
		// smu parameters
		gv_path = smu#gv_path()
		data#check_gvpath(gv_path)
		variable/g $(gv_path + ":voltage") = 100e-3			// 100 mV standard for qc experiments
		variable/g $(gv_path + ":current_range") = 10e-9		// 10 nA setting is minimum possible for fast acqusition
		variable/g $(gv_path + ":current_limit") = 250e-6		// 250 uA maximum for preventing tip damage
		variable/g $(gv_path + ":output") = 1
		// dso parameters
		gv_path = dso#gv_path()
		data#check_gvpath(gv_path)
		// pi_stage parameters
		gv_path = pi_stage#gv_path()
		data#check_gvpath(gv_path)
		variable/g $(gv_path + ":vel_a") = 10
		// tek parameters
		gv_path = tek#gv_path()
		data#check_gvpath(gv_path)
	endif
end

function/s setup_scan_folder()
	nvar append_mode = $(gv_folder + ":append_mode")
	svar prev_scan_folder = root:data:current_scan_folder
	string scan_folder
	if (append_mode)
		scan_folder = prev_scan_folder
	else
		string data_folder = data#check_data_folder()
		scan_folder = data#new_data_folder(data_folder + ":tip_exp_")
		data#check_folder(scan_folder + ":spectra")
		data#check_folder(scan_folder + ":time_resolved_data")
		string/g root:data:current_scan_folder = scan_folder
	endif
	return scan_folder
end

function initialise_scan(scan_folder)
	string scan_folder
	nvar append_mode = $(gv_folder + ":append_mode")
	nvar num_spectrometers
	if (!append_mode)									// if not appending
		// create data storage waves
		variable/g $(scan_folder + ":step") = 0
		make/o/n=0 $(scan_folder + ":steps")
		make/o/n=0 $(scan_folder + ":displacement")
		make/o/n=0 $(scan_folder + ":current"), $(scan_folder + ":voltage")
		make/o/n=0 $(scan_folder + ":conductance"), $(scan_folder + ":current_range")
		make/o/n=0 $(scan_folder + ":psd_x"), $(scan_folder + ":psd_y")
		make/o/n=0 $(scan_folder + ":psd_x_stdev"), $(scan_folder + ":psd_y_stdev")
		make/o/n=0 $(scan_folder + ":timestamp")
		// spectra data
		duplicate/o root:oo:data:current:wl_wave, $(scan_folder + ":wavelength")
		wave wl_wave = $(scan_folder + ":wavelength")
		wl_wave *= 1e-9
		setscale d, 0, 0, "m", wl_wave
		make/o/n=(numpnts(wl_wave), 0) $(scan_folder + ":spec2d")
		if (num_spectrometers == 2)
			make/o/n=(numpnts(wl_wave), 0) $(scan_folder + ":spec2d_t")
		endif
		// scaling
		setscale d, 0, 0, "A", $(scan_folder + ":current"), $(scan_folder + ":current_range")
		setscale d, 0, 0, "V", $(scan_folder + ":voltage")
		setscale d, 0, 0, "G\B0\M", $(scan_folder + ":conductance")
		setscale d, 0, 0, "V", $(scan_folder + ":psd_x"), $(scan_folder + ":psd_y")
		setscale d, 0, 0, "V", $(scan_folder + ":psd_x_stdev"), $(scan_folder + ":psd_y_stdev")
	else
		// do something if required
	endif
end

function log_scan_parameters(scan_folder, i)
	string scan_folder
	variable i
	string param_folder = data#check_folder(scan_folder + ":scan_parameters_" + num2str(i))
	string gv_path
	duplicatedatafolder $gv_folder, $(param_folder + ":exp")
	gv_path = "root:global_variables:amplifiers"
	duplicatedatafolder $gv_path, $(param_folder + ":amplifiers")
	gv_path = smu#gv_path()
	duplicatedatafolder $gv_path, $(param_folder + ":smu")
end

function log_scan_parameters2(scan_folder)
	string scan_folder
	string param_folder = data#check_folder(scan_folder + ":scan_parameters")
	string gv_path

	// load required parameters
	// experiment parameters
	nvar append_mode = $(gv_folder + ":append_mode")
	nvar scan_step = $(gv_folder + ":scan_step")
	nvar scan_size = $(gv_folder + ":scan_size")
	nvar scan_direction = $(gv_folder + ":scan_direction")
	nvar current_set_point = $(gv_folder + ":current_set_point")
	nvar trig_g0 = $(gv_folder + ":trig_g0")
	// amplifier parameters
	gv_path = "root:global_variables:amplifiers"
	nvar gain_dso = $(gv_path + ":gain_dso")
	nvar gain_force_x = $(gv_path + ":gain_force_x")
	nvar gain_force_y = $(gv_path + ":gain_force_y")
	nvar gain_force_dso = $(gv_path + ":gain_force_dso")
	nvar bandwidth_dso = $(gv_path + ":bandwidth_dso")
	nvar bandwidth_force_x = $(gv_path + ":bandwidth_force_x")
	nvar bandwidth_force_y = $(gv_path + ":bandwidth_force_y")
	nvar bandwidth_force_dso = $(gv_path + ":bandwidth_force_dso")
	
	// save parameters to parameter folder
	// experiment parameters
	variable/g $(param_folder + ":append_mode") = append_mode
	variable/g $(param_folder + ":scan_step") = scan_step
	variable/g $(param_folder + ":scan_size") = scan_size
	variable/g $(param_folder + ":scan_direction") = scan_direction
	variable/g $(param_folder + ":current_set_point") = current_set_point
	variable/g $(param_folder + ":trig_g0") = trig_g0
	// amplifier parameters
	variable/g $(param_folder + ":gain_dso") = gain_dso
	variable/g $(param_folder + ":gain_force_x") = gain_force_x
	variable/g $(param_folder + ":gain_force_y") = gain_force_y
	variable/g $(param_folder + ":gain_force_dso") = gain_force_dso
	variable/g $(param_folder + ":bandwidth_dso") = bandwidth_dso
	variable/g $(param_folder + ":bandwidth_force_x") = bandwidth_force_x
	variable/g $(param_folder + ":bandwidth_force_y") = bandwidth_force_y
	variable/g $(param_folder + ":bandwidth_force_dso") = bandwidth_force_dso
end

function make_axis_wave(w, wname)
	// function by MH
	wave w
	string wname
	make/o/n=(numpnts(w)) $(wname)
	wave w_ax = $(wname)
	w_ax = 0.5*(w[p+1] + w[p])
	InsertPoints 0,1, w_ax							// Amend first point
	w_ax[0] = 2*w[0] - w_ax[1]
	w_ax[numpnts(w_ax) - 1] = 2*w[numpnts(w) - 1] - w_ax[numpnts(w_ax)  -2]	// Amend final point
	return 0
end

function setup_display(scan_folder)
	string scan_folder
	// Make wavelength image axis
	wave wavelength = $(scan_folder + ":wavelength")
	make_axis_wave(wavelength, scan_folder + ":wavelength_ax")
	wave wavelength_ax = $(scan_folder + ":wavelength_ax")
	wave steps = $(scan_folder + ":steps")
	make_axis_wave(steps, scan_folder + ":steps_ax")
	wave steps_ax = $(scan_folder + ":steps_ax")
	
	wave displacement = $(scan_folder + ":displacement")
	wave conductance = $(scan_folder + ":conductance")
	wave current_range = $(scan_folder + ":current_range")
	wave psd_x = $(scan_folder + ":psd_x")
	wave psd_y = $(scan_folder + ":psd_y")
	wave spec2d = $(scan_folder + ":spec2d")
	dowindow/k tip_exp_data
	display/n=tip_exp_data
	appendtograph/l=disp displacement
	appendtograph/l=force_l psd_y
	appendtograph/r=force_r psd_x
	appendtograph/l=smu conductance
	appendimage spec2d vs {*, wavelength_ax}
end

function tip_scan()			// tip experiment master function
	// initialise data storage
	initialise()
	string scan_folder = setup_scan_folder()
	
	// open communications and initialise instruments
	smu#open_comms(); smu#initialise()
	dso#open_comms(); dso#initialise()
	tek#open_comms(); tek#initialise()
	pi_stage#open_comms(); pi_stage#initialise()

// LOAD/LOG SCAN
	
	// load all necessary variables / scan parameters
	string gv_path
		// experiment
	nvar append_mode = $(gv_folder + ":append_mode")
	nvar scan_step = $(gv_folder + ":scan_step")
	nvar scan_size = $(gv_folder + ":scan_size")
	nvar scan_direction = $(gv_folder + ":scan_direction")
	nvar current_set_point = $(gv_folder + ":current_set_point")
	variable scan_step_d = scan_direction * scan_step
		// smu
	gv_path = smu#gv_path()
	nvar v = $(gv_path + ":voltage"), i_range = $(gv_path + ":current_range")
		// spectrometer
	nvar num_spectrometers
		// pixis
		// agilent
	gv_path = dso#gv_path()
		// tektronix
	gv_path = tek#gv_path()
		// pi_stage
	gv_path = pi_stage#gv_path()
	
	// log scan settings
	nvar i = $(scan_folder + ":step")
	log_scan_parameters(scan_folder, i)
	
	// prepare data storage
	initialise_scan(scan_folder)
	wave steps = $(scan_folder + ":steps")
	wave displacement = $(scan_folder + ":displacement")
	wave current = $(scan_folder + ":current")
	wave voltage = $(scan_folder + ":voltage")
	wave conductance = $(scan_folder + ":conductance")
	wave current_range = $(scan_folder + ":current_range")
	wave psd_x = $(scan_folder + ":psd_x")
	wave psd_y = $(scan_folder + ":psd_y")
	wave psd_x_stdev = $(scan_folder + ":psd_x_stdev")
	wave psd_y_stdev = $(scan_folder + ":psd_y_stdev")
	wave timestamp = $(scan_folder + ":timestamp")
	wave spec2d = $(scan_folder + ":spec2d")
	if (num_spectrometers == 2)
		wave spec2d_t = $(scan_folder + ":spec2d_t")
	endif
	
	// display experiment
	setup_display(scan_folder)

// EQUIPMENT/EXPERIMENT SETUP

	// prepare initial instrument configurations
	pi_stage#get_pos()
		// smu
	smu#set_voltage(v)
	smu#set_current_range(i_range)
	smu#output(1)
		// time-resolved experiment
		// agilent dsox2000 series dso
	nvar trig_g0, gain
	variable level = trig_g0 * g0 * v * gain
	if(scan_direction == 1)				
		dso#set_trigger("auto", "edge", "channel1", level, "negative", "0", "0")
	elseif(scan_direction == -1)
		dso#set_trigger("auto", "edge", "channel1", level, "positive", "0", "0")
		smu#set_current_range(1e-8)					// Set SMU current range to 1e-8 
	endif
		// pixis 256e ccd
	nvar t_range = root:gVariables:agilentOscilloscope:timeRange
	variable trange = t_range * 1e6
	variable shiftrate = 9.2
	variable exp_time = (trange / 256) - shiftrate
	pixis#ready(exp_time)

// EXPERIMENT

	// do experiment
	variable condition = 0
	variable set_point_reached = 0
	// initialise data
	variable/c smu_data, force_x, force_y
	variable current_pos
	// initialise time resolved data
	string qc_name, qcg_name, qcf_name, qcs_name
	do
		// check for experiment breaks
		if (scan_step * i > scan_size)		// end at scan limit
			break
		elseif (getkeystate(0) & 32)			// manual escape (esc)
			print "scan aborted at step " + num2str(i)
			break
		endif
		
		// prepare measurement waves
		redimension/n=(i+1) steps, displacement, voltage, current, conductance, current_range
		redimension/n=(i+1) psd_x, psd_y, psd_x_stdev, psd_y_stdev, timestamp
		redimension/n=(dimsize(spec2d, 0), i+1) spec2d
		
		// move to position
		if (!set_point_reached)
			pi_stage#move_rel("a", scan_step_d)
		endif
		
		// perform measurement checks
		current_range[i] = smu#check_current_range()
		
		// take measurements
		current_pos = pi_stage#get_pos_ch("a")
		smu_data = smu#measure_iv()
		force_x = tek#wave_stats("1")
		force_y = tek#wave_stats("2")
		//oo_read()
		
		steps[i] = i
		// store pz measurements
		displacement[i] = current_pos
		timestamp[i] = ticks/60
		// store smu measurements
		voltage[i] = real(smu_data)
		current[i] = imag(smu_data)
		conductance[i] = (current[i] / voltage[i]) / g0
		// store force measurements
		psd_x[i] = real(force_x)
		psd_x_stdev[i] = imag(force_x)
		psd_y[i] = real(force_y)
		psd_y_stdev[i] = imag(force_y)
		// store spectra
		duplicate/o root:oo:data:current:spectra, $(scan_folder + ":spectra:spec_" + num2str(i))
		wave spec = $(scan_folder + ":spectra:spec_" + num2str(i))
		spec2d[][i] = spec[p]
		if (num_spectrometers == 2)
			duplicate/o root:oo:data:current:spectra_2, $(scan_folder + ":spectra:spec_t_" + num2str(i))
			wave spec = $(scan_folder + ":spectra:spec_t_" + num2str(i))
			spec2d_t[][i] = spec[p]
		endif
		
		// perform end-loop checks
		if (dso#check_trigger(0))						// check for dso trigger
			// get time-resolved measurements
			print "triggered at " + num2str(i)
			// time-resolved current measurement
			qc_name = scan_folder + "time_resolved_data:qc_trace_"+num2str(i)  	// Update qcTrace name									
			dso#import_data("1", qc_name)										// Download wave from oscilloscope and store in folder
			// calculate time-resolved conductance
			qcg_name = scan_folder + "time_resolved_data:qcg_trace_"+num2str(i)
			duplicate $qc_name, $qcg_name
			wave g_trace = $qcg_name
			nvar gain = $(gv_folder + ":gain")
			g_trace /= (gain * voltage[i] * g0)
			// get time-resolved force measurement
			qcf_name = scan_folder + "time_resolved_data:qc_force_"+num2str(i)  	// Update qcForce name
			dso#import_data("2", qcf_name)
			// get time-resolved spectra
			pixis#read()
			qcs_name = scan_folder + "time_resolved_data:qc_spec_"+num2str(i)
			duplicate root:pixis_256e:current:image, $qcs_name
			// re-arm time-resolved measurements
			pixis#ready(exp_time)
			dso#arm_trigger()
			break
		endif
		if (imag(smu_data) >= current_set_point)		// prevents movement once current limit reached
			set_point_reached = 1
		endif
		
		doupdate
		i += 1
	while (condition)
	
	// clear all instruments
	dso#check_trigger(1)
	// close communications
	smu#close_comms()
	dso#close_comms()
	tek#close_comms()
	pi_stage#close_comms()
	
// ANALYSIS

	// save data analysis
	
	// save exit point
	saveexperiment
end