#pragma IndependentModule = lockin
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "visa_basic" as visa
strconstant hardware_id = "srs_sr830_lockin_amplifier"
strconstant resourceName = "GPIB0::6::INSTR"
strconstant gv_folder = "root:global_variables:" + hardware_id

function open()
	variable status
	status = visa#open(hardware_id, resourceName)
	return status
end

function close()
	variable status
	status = visa#close(hardware_id)
	return status
end

function/c measure_xy()
	variable x, y
	variable/c data
	x = visa#read(hardware_id, "OUTP?1\r")
	y = visa#read(hardware_id, "OUTP?2\r")
	variable/g $(gv_folder + ":x") = x
	variable/g $(gv_folder + ":y") = y
	data = cmplx(x, y)
	return data
end

function/c measure_rtheta()
	variable r, theta
	variable/c data
	r = visa#read(hardware_id, "OUTP?3\r")
	theta = visa#read(hardware_id, "OUTP?4\r")
	variable/g $(gv_folder + ":r") = r
	variable/g $(gv_folder + ":theta") = theta
	data = cmplx(r, theta)
	return data
end

function purge()
	string buffer
	do
		buffer = visa#read_str(hardware_id, "")
	while (!stringmatch(buffer, ""))
end