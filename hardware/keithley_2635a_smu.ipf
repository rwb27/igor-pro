#pragma rtGlobals=1		// Use modern global access method.
//
// v3, 31/01/13, AS
//

// required functions

function check_folder_smu(data_folder)
	string data_folder
	if (!datafolderexists(data_folder))
		newdatafolder $data_folder
	endif
end

function open_smu()
	variable session, instr, status
	string resourceName = "GPIB0::26::INSTR"
	string data_folder = "root:global_variables"
	check_folder_smu(data_folder)
	data_folder += ":keithley_2635a_smu"
	check_folder_smu(data_folder)
	status = viOpenDefaultRM(session)
	status = viOpen(session, resourceName, 0, 0, instr)
	status = viClear(session)
	variable/g $(data_folder + ":instr") = instr
	variable/g $(data_folder + ":session") = session
	return status
end

function close_smu()
	nvar session = root:global_variables:keithley_2635a_smu:session
	variable status = viClose(session)
	status = viClear(session)
	return status
end

function cmd_smu(cmd)
	string cmd
	nvar instr = root:global_variables:keithley_2635a_smu:instr
	VISAwrite instr, cmd
end

function read_smu(cmd)
	string cmd
	variable value
	nvar instr = root:global_variables:keithley_2635a_smu:instr
	VISAwrite instr, cmd
	VISAread instr, value
	return value
end

function/s read_str_smu(cmd)
	string cmd
	string message
	nvar instr = root:global_variables:keithley_2635a_smu:instr
	VISAwrite instr, cmd
	VISAread instr, message
	return message
end

function read_buffer_smu()
	variable value
	nvar instr = root:global_variables:keithley_2635a_smu:instr
	VISAread instr, value
	return value
end

function init_smu()
	cmd_smu("smua.reset()") // restore to default settings
	cmd_smu("smua.measure.rangei = 10e-9") // set current measure range to 1 nA
end

// misc functions

function empty_buffer_smu()
	variable value
	nvar instr = root:global_variables:keithley_2635a_smu:instr
	do
		VISAread instr, value
	while (abs(value) > 1e-300)
	return value
end

// control functions

function output_state_smu(o)
	variable o // on (o == 1) or off (o == 0)
	if (o == 0 || o == 1)
		cmd_smu("smua.source.output="+num2str(o))
	else
		print "incorrect state variable"
	endif
	variable/g root:global_variables:keithley_2635a_smu:output_state = o
end

function/s get_error_smu()
	cmd_smu("errorCode, message = errorqueue.next()")
	string error = read_str_smu("print(errorCode)")
	string message = read_str_smu("print(message)")
	string error_message = error + ": " + message
	return error_message
end

// Set Parameters

function set_current_range_smu(i_range)
	variable i_range
	cmd_smu("smua.measure.rangei = " + num2str(i_range))
	variable/g root:global_variables:keithley_2635a_smu:current_range = i_range
end

function set_voltage_smu(v)
	variable v
	cmd_smu("smua.source.func=smua.OUTPUT_DCVOLTS") // set to source voltage
	cmd_smu("smua.source.levelv = " + num2str(v))
	variable/g root:global_variables:keithley_2635a_smu:voltage = v
end

// Measurement Functions

function measure_voltage_smu()
	variable voltage = read_smu("print(smua.measure.v())")
	variable/g root:global_variables:keithley_2635a_smu:voltage = voltage
	return voltage
end

function measure_current_smu()
	variable current = read_smu("print(smua.measure.i())")
	variable/g root:global_variables:keithley_2635a_smu:current = current
	return current
end

function/c measure_iv_smu()
	cmd_smu("iRead, vRead = smua.measure.iv()")
	variable v = read_smu("print(vRead)")
	variable i = read_smu("print(iRead)")
	variable/g root:global_variables:keithley_2635a_smu:voltage = v
	variable/g root:global_variables:keithley_2635a_smu:current = i
	variable/c output = cmplx(v, i)
	return output
end

function measure_resistance_smu()
	variable resistance = read_smu("print(smua.measure.r())")
	variable/g root:global_variables:keithley_2635a_smu:resistance = resistance
	return resistance
end

// Panel Controls

function output_on_smu_button(ba) : ButtonControl	// output on
	struct WMButtonAction &ba
	switch( ba.eventCode)
		case 2:
			output_state_smu(1)
			break
	endswitch
	return 0
end

function output_off_smu_button(ba) : ButtonControl	// output off
	struct WMButtonAction &ba
	switch( ba.eventCode)
		case 2:
			output_state_smu(0)
			break
	endswitch
	return 0
end

function measure_voltage_smu_button(ba) : ButtonControl	// measure voltage
	struct WMButtonAction &ba
	switch( ba.eventCode)
		case 2:
			variable/g root:global_variables:keithley_2635a_smu:voltage = measure_voltage_smu()
			break
	endswitch
	return 0
end

function measure_current_smu_button(ba) : ButtonControl	// measure current
	struct WMButtonAction &ba
	switch( ba.eventCode)
		case 2:
			variable/g root:global_variables:keithley_2635a_smu:current = measure_current_smu()
			break
	endswitch
	return 0
end

function measure_resistance_smu_button(ba) : ButtonControl	// measure resistance
	struct WMButtonAction &ba
	switch( ba.eventCode)
		case 2:
			variable/g root:global_variables:keithley_2635a_smu:resistance = measure_resistance_smu()
			break
	endswitch
	return 0
end

function measure_iv_smu_button(ba) : ButtonControl	// measure IV
	struct WMButtonAction &ba
	switch( ba.eventCode)
		case 2:
			variable/c measurement = measure_iv_smu()
			variable/g root:global_variables:keithley_2635a_smu:voltage = real(measurement)
			variable/g root:global_variables:keithley_2635a_smu:current = imag(measurement)
			break
	endswitch
	return 0
end

function set_voltage_smu_button()
end

function set_current_range_smu_button()
end