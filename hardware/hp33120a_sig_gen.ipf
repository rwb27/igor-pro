#pragma ModuleName = sig_gen
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "visa_comms"
#include "data_handling"
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

static function/s gv_path()
	return gv_folder
end

static function initialise()
	data#check_gvpath(gv_folder)
	variable/g $(gv_folder + ":frequency")
	variable/g $(gv_folder + ":amplitude")
	variable/g $(gv_folder + ":offset")
end

static function set_frequency(freq)
	variable freq
	visa#cmd(hardware_id, "freq " + num2str(freq) + "\n")
	variable/g $(gv_folder + ":frequency") = freq
end

static function set_amplitude(volt)
	variable volt
	visa#cmd(hardware_id, "output:load inf")
	visa#cmd(hardware_id, "voltage " + num2str(volt) + "\n")
	variable/g $(gv_folder + ":amplitude") = volt
end

static function set_offset(offset)
	variable offset
	visa#cmd(hardware_id, "voltage:offset " + num2str(offset) + "\n")
	variable/g $(gv_folder + ":offset") = offset
end

static function output_dc()
	visa#cmd(hardware_id,"function:shape dc")
end
static function output_sine()
	visa#cmd(hardware_id,"function:shape sinusoid")
end

// Panel Controls

static function set_frequency_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			nvar freq = $(gv_folder + ":frequency")
			open_comms()
			set_frequency(freq)
			close_comms()
			break
		case -1:
			break
	endswitch
	return 0
end

static function set_amplitude_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			nvar volt = $(gv_folder + ":amplitude")
			open_comms()
			set_amplitude(volt)
			close_comms()
			break
		case -1:
			break
	endswitch
	return 0
end

static function set_offset_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			nvar offset = $(gv_folder + ":offset")
			open_comms()
			set_offset(offset)
			close_comms()
			break
		case -1:
			break
	endswitch
	return 0
end

static function set_frequency_panel(sva) : setvariablecontrol
	struct wmsetvariableaction &sva
	switch( sva.eventcode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
			open_comms()
			set_frequency(dval)
			close_comms()
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

static function set_amplitude_panel(sva) : setvariablecontrol
	struct wmsetvariableaction &sva
	switch( sva.eventcode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
			open_comms()
			set_amplitude(dval)
			close_comms()
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

static function set_offset_panel(sva) : setvariablecontrol
	struct wmsetvariableaction &sva
	switch( sva.eventcode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
			open_comms()
			set_offset(dval)
			close_comms()
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end