#pragma ModuleName = tip_exp
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "data_handling"
#include "pi_pi733_3cd_stage"
#include "keithley_2635a_smu"
#include "oo spectrometer v4.23"
#include <NIDAQmxWaveScanProcs>

#include "key_control"

#include "tip_experiment_init"
#include "tip_experiment_display"
#include "tip_experiment_logging"
#include "tip_experiment_setup"
#include "tip_experiment_time_res_meas"
#include "tip_experiment_panel"

static constant g0 = 7.7480917e-5
static strconstant gv_folder = "root:global_variables:tip_experiment"

static function/df gv_path()
	return $gv_folder
end

function tip_scan()			// tip experiment master function	
	// initialise scan
	dfref scan_folder = tip_exp_init#init_scan()					// initialises experiment structure, data and equipment
	string scan_folder_str
 	dfref initial_folder = getdatafolderdfr()
 	setdatafolder scan_folder
 	scan_folder_str = getdatafolder(1)
	setdatafolder initial_folder
	
	// load all necessary variables / scan parameters / paths
	// experiment
	dfref exp_path = $gv_folder
	nvar/sdfr=exp_path append_mode
	nvar/sdfr=exp_path i = :current_step
	nvar/sdfr=exp_path scan_step, scan_direction, current_set_point
	variable/g exp_path:set_point_reached = 0
	nvar/sdfr=exp_path set_point_reached
	// spectrometer
	dfref spec_path = root:oo:globalvariables
	nvar/sdfr=spec_path numspectrometers
	nvar/sdfr=$gv_folder dual_pol_meas
	// setup equipment with current parameter values
	tip_exp_setup#setup(0)
	// log scan settings
	tip_exp_log#log_scan_parameters(scan_folder, i)
	// display experiment
	tip_exp_display#display_scan(scan_folder)

	// open communications and initialise instruments
	smu#open_comms()
	dso#open_comms()
	pi_stage#open_comms()
	
	// do experiment
	variable condition = 1
	// experiment loop
	do
		if (getkeystate(0) & 32)			// manual escape (esc)
			print "scan log: scan aborted at step " + num2str(i)
			break
		endif
		key_control#check_keys_tips()
		if (!set_point_reached)
			pi_stage#move_rel("a", scan_direction * scan_step)
		elseif (set_point_reached)
			//print "scan log: set point reached", current_set_point
			//force feedback experiments
		endif
		spatial_measurements(scan_folder)
		if (dso#check_trigger(0))						// check for dso trigger
			print "scan log: triggered at " + num2str(i)
			tip_exp_time_res#temporal_measurements(scan_folder, i)	// get time-resolved measurements
		endif
		nvar/sdfr=$smu#gv_path() current
		if (current >= current_set_point && current <= 1)		// prevents movement once current limit reached
			print "scan log: set point reached - current (", current,") > set point (", current_set_point,")"
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
	pi_stage#close_comms()
	
	// save exit point
	saveexperiment
end

function spatial_measurements(sf)
	dfref sf
	string sf_str = getdatafolder(1, sf)
	variable i_range = smu#check_current_range()	// measurement check
	
	// make measurements
	oo_read()																	// start measuring spectra - bkgd measurement would help
	DAQmx_Scan/dev="dev1"/bkg WAVES="daq_1, 1/diff, -2, 2; daq_2, 2/diff, -1, 1;"		// start measuring force
	variable current_pos = pi_stage#get_pos_ch("a")									// position
	variable/c smu_data = smu#measure_iv()										// conductance
	fDAQmx_ScanWait("dev1")													// wait until force measurement is complete
	
	// store measurements
	wave/sdfr=sf steps, displacement, timestamp
	wave/sdfr=sf voltage, current, current_range, conductance
	wave/sdfr=sf psd_x, psd_x_stdev, psd_y, psd_y_stdev
	wave/sdfr=root: force_y = daq_1, force_x = daq_2
	variable i = numpnts(steps)
	redimension/n=(i+1) steps, displacement, timestamp
	redimension/n=(i+1) voltage, current, current_range, conductance
	redimension/n=(i+1) psd_x, psd_y, psd_x_stdev, psd_y_stdev
	steps[i] = i
	displacement[i] = current_pos
	timestamp[i] = ticks/60
	voltage[i] = real(smu_data)
	current[i] = imag(smu_data)
	current_range[i] = i_range
	conductance[i] = (imag(smu_data) / real(smu_data)) / g0
	psd_x[i] = mean(force_x)
	psd_x_stdev[i] = sqrt(variance(force_x))
	psd_y[i] = mean(force_y)
	psd_y_stdev[i] = sqrt(variance(force_y))
	// store spectra
	dfref spec_path = root:oo:globalvariables
	nvar/sdfr=spec_path numspectrometers
	// store individual spectra
	duplicate/o root:oo:data:current:spectra, $(sf_str + "spectra:spec_" + num2str(i))
	duplicate/o root:oo:data:current:spectra_raw, $(sf_str + "spectra:raw_spec_" + num2str(i))
	// store referenced spectral image
	wave/sdfr=sf spec2d
	wave/sdfr=root:oo:data:current spectra
	redimension/n=(dimsize(spec2d, 0), i+1) spec2d
	spec2d[][i] = spectra[p]
	// raw image
	wave/sdfr=sf spec2d_raw
	wave/sdfr=root:oo:data:current spectraraw
	redimension/n=(dimsize(spec2d_raw, 0), i+1) spec2d_raw
	spec2d_raw[][i] = spectraraw[p]
	
	if (numspectrometers == 2)
		// store individual spectra
		duplicate/o root:oo:data:current:spectra_2, $(sf_str + "spectra:spec_t_" + num2str(i))
		duplicate/o root:oo:data:current:spectra_2_raw, $(sf_str + "spectra:raw_spec_t_" + num2str(i))
		// store referenced spectra
		wave/sdfr=sf spec2d_t
		wave/sdfr=root:oo:data:current spectra_2
		redimension/n=(dimsize(spec2d_t, 0), i+1) spec2d_t
		spec2d_t[][i] = spectra_2[p]
		// raw image
		wave/sdfr=sf spec2d_t_raw
		wave/sdfr=root:oo:data:current spectraraw_2
		redimension/n=(dimsize(spec2d_t_raw, 0), i+1) spec2d_t_raw
		spec2d_t_raw[][i] = spectraraw_2[p]
	endif
end