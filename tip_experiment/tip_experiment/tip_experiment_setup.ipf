#pragma modulename = tip_exp_setup
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "data_handling"
#include "pi_pi733_3cd_stage"
#include "keithley_2635a_smu"
#include "agilent_dsox2000_series_dso"
#include "tektronix_tds1001b"
#include "princeton_instruments_pixis_256e_ccd"

static constant g0 = 7.7480917e-5
static strconstant gv_folder = "root:global_variables:tip_experiments"

// take currently set global variable values for each piece of equipment and set the parameters
static function setup(rst)
	variable rst
	setup_exp(rst)
	setup_pi(rst)
	setup_smu(rst)
	setup_tek(rst)
	setup_dso(rst)
	setup_pixis(rst)
end

function setup_exp(rst)
	variable rst
	dfref exp_path = $gv_folder
	nvar/sdfr=exp_path scan_direction, vis_g0, trig_g0, dual_pol_meas
	dfref spec_path = root:oo:globalvariables
	nvar/sdfr=spec_path numspectrometers
	dfref amp_path = root:global_variables:amplifiers
	nvar/sdfr=amp_path gain = gain_dso
	// reset to defaults
	if (rst == 1)
		gain = 1000
		vis_g0 = 20
		if (scan_direction == -1)
			trig_g0 = 0.5
		elseif (scan_direction == 1)
			trig_g0 = 15
		endif
	endif
	if (numspectrometers == 1 && dual_pol_meas == 1)
		// setup shutters
		// test both shutters with flip
		// open p-polarisation shutter
	endif
end

function setup_pi(rst)
	variable rst
	dfref pi_path = $pi_stage#gv_path()
	nvar/sdfr=pi_path vel_a, dco_a
	// reset to defaults
	if (rst == 1)
		vel_a = 10
		dco_a = 0
	endif
	pi_stage#open_comms()
	pi_stage#set_velocity_a(vel_a)
	pi_stage#set_dco_a(dco_a)
	pi_stage#get_pos()
	pi_stage#close_comms()
end

function setup_smu(rst)
	variable rst
	dfref exp_path = $gv_folder
	nvar/sdfr=exp_path scan_direction
	dfref smu_path = $smu#gv_path()
	nvar/sdfr=smu_path v = :voltage, i_range = :current_range, i_limit = :current_limit
	// reset to defaults
	if (rst == 1)
		v = 100e-3
		i_limit = 100e-3
		if (scan_direction == -1)
			i_range = 1e-8
		endif
	endif
	smu#open_comms()
	smu#set_voltage(v)
	smu#set_current_limit(i_limit)
	smu#set_current_range(i_range)
	smu#output(1)
	smu#close_comms()
end

function setup_tek(rst)
	variable rst
	tek#open_comms()
	tek#get_waveform_params("1")
	tek#get_waveform_params("2")
	tek#close_comms()
end

function setup_dso(rst)
	variable rst
	dfref exp_path = $gv_folder
	nvar/sdfr=exp_path scan_direction, vis_g0, trig_g0
	dfref amp_path = root:global_variables:amplifiers
	nvar/sdfr=amp_path gain = gain_dso
	dfref smu_path = $smu#gv_path()
	nvar/sdfr=smu_path v = :voltage
	dfref dso_path = $dso#gv_path()
	nvar/sdfr=dso_path t_range = :timebase_settings:time_range, delay = :timebase_settings:time_delay
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
	variable ch1_offset = -4 * ch1_range/10
	
	variable ch2_range = 10
	variable ch2_offset = 0
	
	dso#open_comms()
	set_timebase("main", t_range, 0, delay, "left")
	set_channel("1", ch1_range, 0, ch1_offset, "dc", "V", "current", 1)
	set_channel("2", ch2_range, 0, ch2_offset, "dc", "V", "force", 1)
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
	dfref dso_path = $dso#gv_path()
	nvar/sdfr=dso_path t_range = :timebase_settings:time_range
	dfref pixis_path = $pixis#gv_path()
	nvar/sdfr=pixis_path exp_time
	variable us_range = t_range * 1e6
	variable shiftrate = 9.2
	exp_time = (us_range / 256) - shiftrate
	pixis#ready(exp_time)
end