#pragma modulename = tip_exp_init
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "data_handling"
#include "pi_pi733_3cd_stage"
#include "keithley_2635a_smu"
#include "agilent_dsox2000_series_dso"
#include "tektronix_tds1001b"
#include "princeton_instruments_pixis_256e_ccd"

static constant g0 = 7.7480917e-5
static strconstant gv_folder = "root:global_variables:tip_experiments"

static function/df init_scan()
	check_prereqs()
	dfref scan_folder = init_scan_folder()
	init_scan_waves(scan_folder)
	return scan_folder
end

static function init_experiment()
	data#check_gvpath(gv_folder)
	if (exists((gv_folder + ":initialised")) == 0)
		string gv_path
		variable/g $(gv_folder + ":initialised") = 1
		// experiment parameters
		variable/g $(gv_folder + ":append_mode") = 0
		string/g $(gv_folder + ":prev_scan_folder") = ""
		variable/g $(gv_folder + ":current_step") = 0
		
		variable/g $(gv_folder + ":scan_step") = 1e-3			// 1 nm steps
		variable/g $(gv_folder + ":scan_size") = 5			// 5 um max
		variable/g $(gv_folder + ":scan_direction") = -1		// approaching
		variable/g $(gv_folder + ":current_set_point") = 1		// 1 A stopping point
		variable/g $(gv_folder + ":trig_g0") = 0.5				// 0.5G0 trigger point
		variable/g $(gv_folder + ":vis_g0") = 20				// 20G0 viewing range
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
		variable/g $(gv_path + ":t_range") = 10e-3
		// pi_stage parameters
		gv_path = pi_stage#gv_path()
		data#check_gvpath(gv_path)
		variable/g $(gv_path + ":vel_a") = 10
		// tek parameters
		gv_path = tek#gv_path()
		data#check_gvpath(gv_path)
		// pixis parameters
		gv_path = pixis#gv_path()
		data#check_gvpath(gv_path)
		variable/g $(gv_path + ":exp_time") = 70
		// spectrometer parameters
		variable/g num_spectrometers = 1
	endif
end

static function check_prereqs()
	data#check_gvpath(gv_folder)
	nvar/z/sdfr=$gv_folder initialised
	if (!nvar_exists(initialised))
		init_experiment()
	endif
end

static function/df init_scan_folder()
	nvar/sdfr=$gv_folder append_mode
	svar/sdfr=$gv_folder prev_scan_folder = root:data:current_scan_folder
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
	return $scan_folder
end

static function init_scan_waves(scan_folder)
	dfref scan_folder
	nvar/sdfr=$gv_folder append_mode
	dfref spec_path = root:oo:globalvariables
	nvar/sdfr=spec_path num_spectrometers
	if (!append_mode)									// if not appending
		// create data storage waves
		make/o/n=0 scan_folder:steps
		make/o/n=0 scan_folder:displacement
		make/o/n=0 scan_folder:current, scan_folder:voltage, scan_folder:current_range
		make/o/n=0 scan_folder:psd_x, scan_folder:psd_y
		make/o/n=0 scan_folder:psd_x_stdev, scan_folder:psd_y_stdev
		make/o/n=0 scan_folder:timestamp
		
		// create dependencies
		make/o/n=0 scan_folder:conductance
		
		// spectra data
		duplicate/o root:oo:data:current:wl_wave, scan_folder:wavelength
		wave wl_wave = scan_folder:wavelength
		wl_wave *= 1e-9
		setscale d, 0, 0, "m", wl_wave
		make/o/n=(numpnts(wl_wave), 0) scan_folder:spec2d
		if (num_spectrometers == 2)
			make/o/n=(numpnts(wl_wave), 0) scan_folder:spec2d_t
		endif
		
		// scaling
		setscale d, 0, 0, "A", scan_folder:current, scan_folder:current_range
		setscale d, 0, 0, "V", scan_folder:voltage
		setscale d, 0, 0, "G\B0\M", scan_folder:conductance
		setscale d, 0, 0, "V", scan_folder:psd_x, scan_folder:psd_y
		setscale d, 0, 0, "V", scan_folder:psd_x_stdev, scan_folder:psd_y_stdev
	else
		// do something if required
	endif
end
