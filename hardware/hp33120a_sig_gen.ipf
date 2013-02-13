#pragma ModuleName = sig_gen
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "visa"
static strconstant hardware_id = "hp33120a_signal_generator"
static strconstant resourceName = "GPIB0::3::INSTR"
static strconstant gv_folder = "root:global_variables:hp33120a_signal_generator"

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

function set_frequency(freq)
	variable freq
	visa#cmd(hardware_id, "FREQ " + num2str(freq) + "\n")
end

function set_amplitude(volt)
	variable volt
	visa#cmd(hardware_id, "output:load inf")
	visa#cmd(hardware_id, "voltage " + num2str(volt) + "\n")
end

function set_offset(offset)
	variable offset
	visa#cmd(hardware_id, "voltage:offset " + num2str(offset) + "\n")
end