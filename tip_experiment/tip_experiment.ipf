#pragma ModuleName = tip_exp
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "data_handling"
#include "pi_pi733_3cd_stage"
#include "keithley_2635a_smu"
#include "agilent_dsox2000_series_dso"
#include "tektronix_tds1001b"
#include "princeton_instruments_pixis_256e_ccd"
#include "oo spectrometer v4.2"

#include "tip_experiment_init"
#include "tip_experiment_display"
#include "tip_experiment_logging"
#include "tip_experiment_setup"

static constant g0 = 7.7480917e-5
static strconstant gv_folder = "root:global_variables:tip_experiments"

function tip_scan()			// tip experiment master function
	// initialise data storage
	dfref scan_folder = tip_exp_init#init_scan()
	
	// open communications and initialise instruments
	smu#open_comms(); smu#initialise(); smu#close_comms()
	dso#open_comms(); dso#initialise(); dso#close_comms()
	tek#open_comms(); tek#initialise(); tek#close_comms()
	pi_stage#open_comms(); pi_stage#initialise(); pi_stage#close_comms()
	
	// load all necessary variables / scan parameters / paths
	dfref exp_path = $gv_folder
		// experiment
	nvar/sdfr=exp_path append_mode
	nvar/sdfr=exp_path i = :current_step
	nvar/sdfr=exp_path scan_step, scan_size, scan_direction, current_set_point
	variable scan_step_d = scan_direction * scan_step
		// amplifier
	dfref amp_path = root:global_variables:amplifiers
	nvar/sdfr=amp_path gain = gain_dso
		// smu
	dfref smu_path = $smu#gv_path()
	nvar/sdfr=smu_path v = :voltage, i_range = :current_range
		// spectrometer
	dfref spec_path = root:oo:globalvariables
	nvar/sdfr=spec_path numspectrometers
		// pixis
	dfref pixis_path = $pixis#gv_path()
	nvar/sdfr=pixis_path exp_time
		// agilent
		// tektronix
		// pi_stage
	
	// prepare initial instrument configurations
	tip_exp_setup#setup(1)
	// log scan settings
	tip_exp_log#log_scan_parameters(scan_folder, i)
	// display experiment
	tip_exp_display#display_scan(scan_folder)
	
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
	if (numspectrometers == 2)
		wave/sdfr=scan_folder spec2d_t
	endif

	// EXPERIMENT
	
	// open communications and initialise instruments
	smu#open_comms()
	dso#open_comms()
	tek#open_comms(); tek#initialise()
	pi_stage#open_comms(); pi_stage#initialise()
	
	// do experiment
	variable condition = 0
	variable set_point_reached = 0
	// initialise data
	variable/c smu_data, force_x, force_y
	variable current_pos
	// initialise time resolved data
	string qc_name, qcg_name, qcf_name, qcs_name
	
	// experiment loop
	do
		// check for experiment breaks
		if (scan_step * i > scan_size)		// end at scan limit
			break
		elseif (getkeystate(0) & 32)			// manual escape (esc)
			print "scan aborted at step " + num2str(i)
			break
		endif
		
		// prepare measurement waves
		redimension/n=(i+1) steps, displacement, voltage, current, current_range
		redimension/n=(i+1) psd_x, psd_y, psd_x_stdev, psd_y_stdev, timestamp
		redimension/n=(dimsize(spec2d, 0), i+1) spec2d, spec2d_t
		
		// MOVEMENT PHASE
		// move to position
		if (!set_point_reached)
			pi_stage#move_rel("a", scan_step_d)
		//elseif (set_point_reached)
			//force feedback experiments
		endif
		
		// MEASUREMENT PHASE
		// perform measurement checks
		current_range[i] = smu#check_current_range()
		
		// take measurements
		current_pos = pi_stage#get_pos_ch("a")
		smu_data = smu#measure_iv()
		force_x = tek#wave_stats("1")
		force_y = tek#wave_stats("2")
		oo_read()
		
		// STORAGE PHASE
		steps[i] = i
		// store pz measurements
		displacement[i] = current_pos
		timestamp[i] = ticks/60
		// store smu measurements
		voltage[i] = real(smu_data)
		current[i] = imag(smu_data)
		// store force measurements
		psd_x[i] = real(force_x)
		psd_x_stdev[i] = imag(force_x)
		psd_y[i] = real(force_y)
		psd_y_stdev[i] = imag(force_y)
		// store spectra
		duplicate/o root:oo:data:current:spectra, scan_folder:$("spectra:spec_" + num2str(i))
		wave/sdfr=scan_folder spec = $("spectra:spec_" + num2str(i))
		spec2d[][i] = spec[p]
		if (numspectrometers == 2)
			duplicate/o root:oo:data:current:spectra_2, scan_folder:$("spectra:spec_t_" + num2str(i))
			wave/sdfr=scan_folder spec = $("spectra:spec_t_" + num2str(i))
			spec2d_t[][i] = spec[p]
		endif
		
		// perform end-loop checks
		// TIME-RESOLVED CHECKS
		if (dso#check_trigger(0))						// check for dso trigger
			// get time-resolved measurements
			print "triggered at " + num2str(i)
			
			// set wave names
			string scan_folder_str
 			dfref initial_folder = getdatafolderdfr()
 			setdatafolder scan_folder
 			scan_folder_str = getdatafolder(1)
			setdatafolder initial_folder
			
			qc_name = scan_folder_str + "time_resolved_data:qc_trace_"+num2str(i)
			qcg_name = scan_folder_str + "time_resolved_data:qcg_trace_"+num2str(i)
			qcf_name = scan_folder_str + "time_resolved_data:qc_force_"+num2str(i)
			qcs_name = scan_folder_str + "time_resolved_data:qc_spec_"+num2str(i)
			
			// time-resolved current measurement
			dso#import_data("1", qc_name)
			// calculate time-resolved conductance
			duplicate $qc_name, $qcg_name
			wave g_trace = $qcg_name
			nvar gain = $(gv_folder + ":gain")
			g_trace /= (gain * voltage[i] * g0)
			// get time-resolved force measurement
			dso#import_data("2", qcf_name)
			
			// get time-resolved spectra
			pixis#read()
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

	redimension/n=(numpnts(current)) conductance
	conductance = (current / voltage) / g0
	// save data analysis
	
	// save exit point
	saveexperiment
end