#pragma ModuleName = tip_exp
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "data_handling"
#include "pi_pi733_3cd_stage"
#include "keithley_2635a_smu"
#include "agilent_dsox2000_series_dso"
#include "princeton_instruments_pixis_256e_ccd"
#include "oo spectrometer v4.2"
#include <NIDAQmxWaveScanProcs>

#include "tip_experiment_init"
#include "tip_experiment_display"
#include "tip_experiment_logging"
#include "tip_experiment_setup"
#include "tip_experiment_time_res_meas"
#include "tip_experiment_panel"

static constant g0 = 7.7480917e-5
static strconstant gv_folder = "root:global_variables:tip_experiment"

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
	nvar/sdfr=exp_path scan_step, scan_size, scan_direction, current_set_point
	variable scan_step_d = scan_direction * scan_step
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
	
	wave/sdfr=root force_x, force_y
	// prepare data storage
	wave/sdfr=scan_folder steps
	wave/sdfr=scan_folder displacement
	wave/sdfr=scan_folder current
	wave/sdfr=scan_folder voltage
	wave/sdfr=scan_folder conductance
	wave/sdfr=scan_folder current_range
	wave/sdfr=scan_folder psd_x
	wave/sdfr=scan_folder psd_y
	wave/sdfr=scan_folder psd_x_stdev
	wave/sdfr=scan_folder psd_y_stdev
	wave/sdfr=scan_folder timestamp
	wave/sdfr=scan_folder spec2d
	if (numspectrometers == 2 || (numspectrometers == 1 && dual_pol_meas == 1))
		wave/sdfr=scan_folder spec2d_t
	endif

	// EXPERIMENT
	
	// open communications and initialise instruments
	smu#open_comms()
	dso#open_comms()
	pi_stage#open_comms()
	
	// do experiment
	variable condition = 1
	variable set_point_reached = 0
	variable keys
	// initialise data
	variable/c smu_data
	variable i_range, current_pos
	
	// experiment loop
	do
		// check for experiment breaks
		keys = getkeystate(0)
		if (scan_step * i > scan_size)		// end at scan limit
			break
		elseif (keys & 32)			// manual escape (esc)
			print "scan aborted at step " + num2str(i)
			break
		elseif (keys & 1)			// ctrl key
			print "set point reached"
			set_point_reached = 1
		//elseif (keys & 2)			// alt key
			// do power experiment
		elseif (keys & 4)			// shift key
			print "set point disabled"
			set_point_reached = 0
		endif
		
		// MOVEMENT PHASE
		// move to position
		if (!set_point_reached)
			pi_stage#move_rel("a", scan_step_d)
		//elseif (set_point_reached)
			//force feedback experiments
		endif
		
		// MEASUREMENT PHASE
		// perform measurement checks
		i_range = smu#check_current_range()
		
		// take measurements
		DAQmx_Scan/dev="dev1"/bkg WAVES="force_y, 1/diff; force_x, 2/diff;"
		current_pos = pi_stage#get_pos_ch("a")
		smu_data = smu#measure_iv()
		force_x = tek#wave_stats("1")
		force_y = tek#wave_stats("2")
		oo_read()
		fDAQmx_ScanWait("dev1")
		
		// STORAGE PHASE
		// store pz measurements
		redimension/n=(i+1) steps, displacement, timestamp
		steps[i] = i
		displacement[i] = current_pos
		timestamp[i] = ticks/60
		// store smu measurements
		redimension/n=(i+1) voltage, current, current_range
		voltage[i] = real(smu_data)
		current[i] = imag(smu_data)
		current_range[i] = i_range
		// store force measurements
		redimension/n=(i+1) psd_x, psd_y, psd_x_stdev, psd_y_stdev
		psd_x[i] = mean(force_x)
		psd_x_stdev[i] = sqrt(variance(force_x))
		psd_y[i] = mean(force_y)
		psd_y_stdev[i] = sqrt(variance(force_y))
		// store spectra
		duplicate/o root:oo:data:current:spectra, $(scan_folder_str + "spectra:spec_" + num2str(i))
		wave/sdfr=scan_folder spec = $(":spectra:spec_" + num2str(i))
		redimension/n=(dimsize(spec2d, 0), i+1) spec2d
		spec2d[][i] = spec[p]
		if (numspectrometers == 2)
			duplicate/o root:oo:data:current:spectra_2, $(scan_folder_str + "spectra:spec_t_" + num2str(i))
			wave/sdfr=scan_folder spec = $(":spectra:spec_t_" + num2str(i))
			redimension/n=(dimsize(spec2d_t, 0), i+1) spec2d_t
			spec2d_t[][i] = spec[p]
		elseif (numspectrometers == 1 && dual_pol_meas == 1)
			// flip shutters
			oo_read()
			duplicate/o root:oo:data:current:spectra, $(scan_folder_str + "spectra:spec_t_" + num2str(i))
			wave/sdfr=scan_folder spec = $(":spectra:spec_t_" + num2str(i))
			redimension/n=(dimsize(spec2d_t, 0), i+1) spec2d_t
			spec2d_t[][i] = spec[p]
			// flip shutters
		endif
		
		// perform end-loop checks
		// TIME-RESOLVED CHECKS
		if (dso#check_trigger(0))						// check for dso trigger
			// get time-resolved measurements
			print "triggered at " + num2str(i)
			tip_exp_time_res#measure_time_resolved(scan_folder, i)
		endif
		if (imag(smu_data) >= current_set_point)		// prevents movement once current limit reached
			print "set point reached - current (", imag(smu_data),") > set point (", current_set_point,")"
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
	
	// ANALYSIS

	redimension/n=(numpnts(current)) conductance
	conductance = (current / voltage) / g0
	// save data analysis
	
	// save exit point
	saveexperiment
end
