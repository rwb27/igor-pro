#pragma modulename = tip_exp_setup
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "pi_pi733_3cd_stage"
#include "keithley_2635a_smu"
#include "agilent_dsox2000_series_dso"
#include "princeton_instruments_pixis_256e_ccd"
#include "daq_methods"

static constant g0 = 7.7480917e-5
static strconstant gv_folder = "root:global_variables:tip_experiment"

// take currently set global variable values for each piece of equipment and set the parameters
static function setup(rst)
	variable rst
	setup_exp(rst)
	setup_pi(rst)
	setup_smu(rst)
	setup_dso(rst)
	setup_pixis(rst)
	
	// create daq waves for force measurements
	daq#create_daq_waves(2, 100e3, 0.1)
	// spectra logging
	svar current_data_folder = root:data:current_scan_folder
	dfref sf = $current_data_folder
	duplicatedatafolder root:oo:data:current, sf:spectra_parameters
end

static function setup_exp(rst)
	variable rst
	nvar/sdfr=$gv_folder scan_direction, vis_g0, trig_g0, dual_pol_meas
	nvar/sdfr=root:oo:globalvariables numspectrometers
	nvar/sdfr=root:global_variables:amplifiers gain = gain_dso
	// reset to defaults
	if (rst == 1)
		dual_pol_meas = 0
		gain = 1000
		vis_g0 = 20
		if (scan_direction == -1)
			trig_g0 = 1
		elseif (scan_direction == 1)
			trig_g0 = 15
		endif
	endif
end

static function setup_pi(rst)
	variable rst
	nvar/sdfr=$pi_stage#gv_path() vel_a
	// reset to defaults
	if (rst == 1)
		vel_a = 10
	endif
	pi_stage#open_comms()
	pi_stage#set_velocity_a(vel_a)
	pi_stage#set_dco_a(0)
	pi_stage#set_dco_b(0)
	pi_stage#set_dco_c(0)
	pi_stage#close_comms()
end

static function setup_smu(rst)
	variable rst
	nvar/sdfr=$gv_folder scan_direction
	nvar/sdfr=$smu#gv_path() v = voltage, v_range = voltage_range, i_range = current_range, i_limit = current_limit
	// reset to defaults
	if (rst == 1)
		v = 10e-3
		v_range = 10e-3
		i_limit = 250e-6
		if (scan_direction == -1)
			i_range = 1e-8
		endif
	endif
	smu#open_comms()
	smu#set_voltage(v)
	//smu#set_voltage_range(v_range)
	smu#set_current_limit(i_limit)
	smu#set_current_range(i_range)
	smu#output(1)
	smu#close_comms()
end

function setup_dso(rst)
	variable rst
	nvar/sdfr=$gv_folder scan_direction, vis_g0, trig_g0
	nvar/sdfr=root:global_variables:amplifiers gain = gain_dso
	nvar/sdfr=$smu#gv_path() v = voltage
	nvar/sdfr=$dso#gv_path() t_range = :timebase_settings:time_range, delay = :timebase_settings:time_delay
	// reset to defaults
	if (rst == 1)
		t_range = 10e-3
		if (scan_direction == -1)
			delay = 0
		elseif (scan_direction == 1)
			delay = 0
		endif
	endif
	
	// calculate voltages
	variable trig_level = trig_g0 * g0 * v * gain
	variable ch1_range = 10/9 * vis_g0 * g0 * v * gain
	variable ch1_offset = 4 * ch1_range/10
	variable ch2_range = 10
	variable ch2_offset = 0
	
	dso#open_comms()
	dso#set_timebase("main", t_range, 0, delay, "left")
	dso#set_channel("1", ch1_range, 0, ch1_offset, "dc", "V", "current", 1)
	dso#set_channel("2", ch2_range, 0, ch2_offset, "dc", "V", "force", 1)
	if (scan_direction == -1)
		dso#set_trigger("auto", "edge", "channel1", trig_level, "positive", "0", "0")
	elseif (scan_direction == 1)
		dso#set_trigger("auto", "edge", "channel1", trig_level, "negative", "0", "0")
	endif
	dso#arm_trigger()
	dso#close_comms()
end

function setup_pixis(rst)
	variable rst
	nvar/sdfr=$dso#gv_path() t_range = :timebase_settings:time_range
	nvar/sdfr=$pixis#gv_path() exp_time
	variable us_range = t_range * 1e6
	variable shiftrate = 9.2
	exp_time = (us_range / 256) - shiftrate
	pixis#ready(exp_time)
end

function setup_triggering()
	nvar/sdfr=$gv_folder scan_direction, vis_g0, trig_g0
	if (scan_direction == -1)
		trig_g0 = 1
		print "scan log: trig_g0 =", trig_g0
	elseif (scan_direction == 1)
		trig_g0 = 15
		print "scan log: trig_g0 =", trig_g0
	endif
	setup_dso(0)
end