#pragma ModuleName = smu
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "visa"
	static strconstant hardware_id = "keithley_2635a_smu"
	static strconstant resourceName = "GPIB0::26::INSTR"
	static strconstant gv_folder = "root:global_variables:keithley_2635a_smu"

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

static function initialise()
	visa#cmd(hardware_id, "smua.reset()") // restore to default settings
	visa#cmd(hardware_id, "smua.measure.rangei = 10e-9") // set current measure range to 1 nA
end

function empty_buffer()
	variable value
	do
		value = visa#read(hardware_id, "")
	while (abs(value) > 1e-300)
	return value
end

function output_state(o)
	variable o // on (o == 1) or off (o == 0)
	if (o == 0 || o == 1)
		visa#cmd(hardware_id, "smua.source.output="+num2str(o))
	else
		print "incorrect state variable"
	endif
	variable/g $(gv_folder + ":output_state") = o
end

function/s get_error()
	visa#cmd(hardware_id, "errorCode, message = errorqueue.next()")
	string error = visa#read_str(hardware_id, "print(errorCode)")
	string message = visa#read_str(hardware_id, "print(message)")
	string error_message = error + ": " + message
	return error_message
end

function set_current_range(i_range)
	variable i_range
	visa#cmd(hardware_id, "smua.measure.rangei = " + num2str(i_range))
	variable/g $(gv_folder + ":current_range") = i_range
end

function set_voltage(v)
	variable v
	visa#cmd(hardware_id, "smua.source.func=smua.OUTPUT_DCVOLTS") // set to source voltage
	visa#cmd(hardware_id, "smua.source.levelv = " + num2str(v))
	variable/g $(gv_folder + ":voltage") = v
end

function measure_voltage()
	variable voltage = visa#read(hardware_id, "print(smua.measure.v())")
	variable/g $(gv_folder + ":voltage") = voltage
	return voltage
end

function measure_current()
	variable current = visa#read(hardware_id, "print(smua.measure.i())")
	variable/g $(gv_folder + ":current") = current
	return current
end

function/c measure_iv()
	visa#cmd(hardware_id, "iRead, vRead = smua.measure.iv()")
	variable v = visa#read(hardware_id, "print(vRead)")
	variable i = visa#read(hardware_id, "print(iRead)")
	variable/g $(gv_folder + ":voltage") = v
	variable/g $(gv_folder + ":current") = i
	variable/c output = cmplx(v, i)
	return output
end

function measure_resistance()
	variable resistance = visa#read(hardware_id, "print(smua.measure.r())")
	variable/g $(gv_folder + ":resistance") = resistance
	return resistance
end

function output_on_button(ba) : ButtonControl	// output on
	struct WMButtonAction &ba
	switch( ba.eventCode)
		case 2:
			output_state(1)
			break
	endswitch
	return 0
end

function output_off_button(ba) : ButtonControl	// output off
	struct WMButtonAction &ba
	switch( ba.eventCode)
		case 2:
			output_state(0)
			break
	endswitch
	return 0
end

function measure_voltage_button(ba) : ButtonControl	// measure voltage
	struct WMButtonAction &ba
	switch( ba.eventCode)
		case 2:
			variable/g $(gv_folder + ":voltage") = measure_voltage()
			break
	endswitch
	return 0
end

function measure_current_button(ba) : ButtonControl	// measure current
	struct WMButtonAction &ba
	switch( ba.eventCode)
		case 2:
			variable/g $(gv_folder + ":current") = measure_current()
			break
	endswitch
	return 0
end

function measure_resistance_button(ba) : ButtonControl	// measure resistance
	struct WMButtonAction &ba
	switch( ba.eventCode)
		case 2:
			variable/g $(gv_folder + ":resistance") = measure_resistance()
			break
	endswitch
	return 0
end

function measure_iv_button(ba) : ButtonControl	// measure IV
	struct WMButtonAction &ba
	switch( ba.eventCode)
		case 2:
			variable/c measurement = measure_iv()
			variable/g $(gv_folder + ":voltage") = real(measurement)
			variable/g $(gv_folder + ":current") = imag(measurement)
			break
	endswitch
	return 0
end

function set_voltage_smu_button()
end

function set_current_range_smu_button()
end