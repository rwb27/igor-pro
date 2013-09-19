#pragma modulename = tip_exp_init
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "data_handling"
#include "pi_pi733_3cd_stage"
#include "keithley_2635a_smu"
#include "agilent_dsox2000_series_dso"
#include "princeton_instruments_pixis_256e_ccd"

static constant g0 = 7.7480917e-5
static strconstant gv_folder = "root:global_variables:tip_experiment"

// FUNCTION 1 - Initialise the experiment structure the first time it is used. //
static function init_experiment()
	// creates all global variable storage folders and required variables with default values
	// initialise equipment
	smu#open_comms(); smu#initialise(); smu#close_comms()				// smu
	dso#open_comms(); dso#initialise(); dso#close_comms()					// dso
	pi_stage#open_comms(); pi_stage#initialise(); pi_stage#close_comms()		// pi
	pixis#initialise()														// pixis
	
	newdatafolder/o root:global_variables				// check existence of gv folder
	newdatafolder/o $gv_folder
	string gv_path
	variable/g $(gv_folder + ":initialised") = 1				// set experiment as initialised
	// experiment parameters
	variable/g $(gv_folder + ":append_mode") = 0
	string/g $(gv_folder + ":prev_scan_folder")
	variable/g $(gv_folder + ":current_step") = 0
	variable/g $(gv_folder + ":scan_step") = 0.001
	variable/g $(gv_folder + ":scan_size") = 10
	variable/g $(gv_folder + ":scan_direction") = -1
	variable/g $(gv_folder + ":current_set_point") = 0.005
	variable/g $(gv_folder + ":trig_g0") = 1
	variable/g $(gv_folder + ":vis_g0") = 20
	variable/g $(gv_folder + ":dual_pol_meas") = 0
	// amplifier parameters
	gv_path = "root:global_variables:amplifiers"
	newdatafolder/o $gv_path
	variable/g $(gv_path + ":gain_dso") = 1e4
	variable/g $(gv_path + ":gain_force_dso") = 50
	variable/g $(gv_path + ":bandwidth_dso") = 500e3
	variable/g $(gv_path + ":bandwidth_force_dso") = 300e3
	
	// restore defaults
	// smu parameters
	gv_path = smu#gv_path()
	variable/g $(gv_path + ":voltage") = 10e-3			// 100 mV standard for qc experiments
	variable/g $(gv_path + ":current_range") = 10e-9		// 10 nA setting is minimum possible for fast acqusition
	variable/g $(gv_path + ":current_limit") = 250e-6		// 250 uA maximum for preventing tip damage
	variable/g $(gv_path + ":output") = 0
	// dso parameters
	gv_path = dso#gv_path()
	variable/g $(gv_path + ":timebase_settings:time_range") = 10e-3
	// pi_stage parameters
	gv_path = pi_stage#gv_path()
	variable/g $(gv_path + ":vel_a") = 10
	variable/g $(gv_path + ":dco_a") = 0
end

// FUNCTION 2 - Initialise the tip experiment scan each time the tip_scan function is called. //
static function/df init_scan()
	check_prereqs()						// check experiment initialisation is complete
	dfref scan_folder = init_scan_folder()	// get scan folder
	init_scan_waves(scan_folder)			// get scan waves
	return scan_folder
end

static function check_prereqs()
	data#check_gvpath(gv_folder)			// check tip experiment gv folder exists
	nvar/z/sdfr=$gv_folder initialised		// check if experiment has been initialised
	if (!nvar_exists(initialised))				// if not initialised - initialise
		init_experiment()
		abort "reset experiment parameters"
	endif
end

static function/df init_scan_folder()
	nvar/sdfr=$gv_folder append_mode, current_step
	svar/sdfr=$gv_folder prev_scan_folder = root:data:current_scan_folder
	dfref scan_folder, data_folder
	if (append_mode && !stringmatch(prev_scan_folder, ""))		// if appending use previous scan
		scan_folder = $prev_scan_folder
		print "appending to", getdatafolder(0, scan_folder), "at point", current_step
	else														// default non-appending response
		// creation of tip experiment folder structure
		current_step = 0
		data_folder = $data#check_data_folder()
		setdatafolder data_folder
		string sname = uniquename("tip_exp_", 11, 1)
		newdatafolder/o data_folder:$sname
		scan_folder = data_folder:$sname
		newdatafolder/o scan_folder:spectra
		newdatafolder/o scan_folder:time_resolved_data
		setdatafolder root:
		string/g root:data:current_scan_folder = getdatafolder(1, scan_folder)
	endif
	return scan_folder
end

static function init_scan_waves(scan_folder)
	dfref scan_folder
	nvar/sdfr=$gv_folder append_mode
	nvar/sdfr=root:oo:globalvariables numspectrometers
	nvar/sdfr=$gv_folder dual_pol_meas
	if (!append_mode)									// if not appending
		// create data storage waves
		make/o/n=0 scan_folder:steps
		make/o/n=0 scan_folder:displacement
		make/o/n=0 scan_folder:current, scan_folder:voltage, scan_folder:current_range
		make/o/n=0 scan_folder:psd_x, scan_folder:psd_y
		make/o/n=0 scan_folder:psd_x_stdev, scan_folder:psd_y_stdev
		make/o/n=0 scan_folder:timestamp
		make/o/n=0 scan_folder:conductance
		// spectra data
		duplicate/o root:oo:data:current:wl_wave, scan_folder:wavelength
		wave wl_wave = scan_folder:wavelength
		wl_wave *= 1e-9
		setscale d, 0, 0, "m", wl_wave
		make/o/n=(numpnts(wl_wave), 1) scan_folder:spec2d
		// extra spectra data
		if (numspectrometers == 2)
			variable/g scan_folder:numspectrometers = 2
			duplicate/o root:oo:data:current:wl_wave_2, scan_folder:wavelength_t
			wave wl_wave_t = scan_folder:wavelength_t
			wl_wave_t *= 1e-9
			setscale d, 0, 0, "m", wl_wave_t
			make/o/n=(numpnts(wl_wave_t), 1) scan_folder:spec2d_t
		endif
		// scaling
		setscale d, 0, 0, "A", scan_folder:current, scan_folder:current_range
		setscale d, 0, 0, "V", scan_folder:voltage
		setscale d, 0, 0, "G\B0\M", scan_folder:conductance
		setscale d, 0, 0, "V", scan_folder:psd_x, scan_folder:psd_y
		setscale d, 0, 0, "V", scan_folder:psd_x_stdev, scan_folder:psd_y_stdev
	endif
end