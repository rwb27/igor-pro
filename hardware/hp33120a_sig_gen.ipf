#pragma IndependentModule = sig_gen
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "visa_basic" as visa
strconstant hardware_id = "hp33120a_signal_generator"
strconstant resourceName = "GPIB0::3::INSTR"
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