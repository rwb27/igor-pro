#pragma ModuleName = lockin
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "visa_comms"
static strconstant hardware_id = "srs_sr830_lockin_amplifier"
static strconstant resourceName = "GPIB0::19::INSTR"
static strconstant gv_folder = "root:global_variables:srs_sr830_lockin_amplifier"

static function/df gv_path()
	return $gv_folder
end

static function initialise()
	newdatafolder/o root:global_variables
	newdatafolder/o $gv_folder
	variable/g $(gv_folder+":time_constant")
end

static function open_comms()
	variable status
	status = visa#open_comms(hardware_id, resourceName)
	return status
end

static function close_comms()
	variable status
	status = visa#close_comms(hardware_id)
	return status
end

static function/c measure_xy()
	variable x, y
	variable/c data
	x = visa#read(hardware_id, "OUTP?1\r")
	y = visa#read(hardware_id, "OUTP?2\r")
	variable/g $(gv_folder + ":x") = x
	variable/g $(gv_folder + ":y") = y
	data = cmplx(x, y)
	return data
end

static function/c measure_rtheta()
	variable r, theta
	variable/c data
	r = visa#read(hardware_id, "OUTP?3\r")
	theta = visa#read(hardware_id, "OUTP?4\r")
	variable/g $(gv_folder + ":r") = r
	variable/g $(gv_folder + ":theta") = theta
	data = cmplx(r, theta)
	return data
end

static function purge()
	string buffer
	do
		buffer = visa#read_str(hardware_id, "")
	while (!stringmatch(buffer, ""))
end

static function aphs()
	visa#cmd(hardware_id, "APHS\r")
	sleep/s 2
end

static function get_time_constant()
	variable tc_ref = visa#read(hardware_id, "OFLT?\r")
	variable time_constant
	switch(tc_ref)
		case 4:
			time_constant = 1e-3
			break
		case 5:
			time_constant = 3e-3
			break
		case 6:
			time_constant = 10e-3
			break
		case 7:
			time_constant = 30e-3
			break
		case 8:
			time_constant = 100e-3
			break
		case 9:
			time_constant = 300e-3
			break
		default:
			time_constant = 0
	endswitch
	variable/g $(gv_folder+":time_constant") = time_constant
	return time_constant
end