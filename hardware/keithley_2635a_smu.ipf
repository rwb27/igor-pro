#pragma ModuleName = smu
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "visa_comms"
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

static function/s gv_path()
	return gv_folder
end

static function initialise()
	variable/g $(gv_folder + ":voltage"), $(gv_folder + ":current"), $(gv_folder + ":current_range")
	variable/g $(gv_folder + ":current_limit"), $(gv_folder + ":output")
	visa#cmd(hardware_id, "smua.reset()\n") // restore to default settings
	visa#cmd(hardware_id, "smua.measure.rangei = 10e-9\n") // set current measure range to 1 nA
end

function empty_buffer()
	variable value
	do
		value = visa#read(hardware_id, "")
	while (abs(value) > 1e-300)
	return value
end

function output(o)
	variable o // on (o == 1) or off (o == 0)
	if (o == 0 || o == 1)
		visa#cmd(hardware_id, "smua.source.output=" + num2str(o) + "\n")
	else
		print "incorrect state variable"
	endif
	variable/g $(gv_folder + ":output") = o
end

function/s get_error()
	visa#cmd(hardware_id, "errorCode, message = errorqueue.next()\n")
	string error = visa#read_str(hardware_id, "print(errorCode)\n")
	string message = visa#read_str(hardware_id, "print(message)\n")
	string error_message = error + ": " + message
	return error_message
end

function set_voltage_range(v_range)
	variable v_range
	visa#cmd(hardware_id, "smua.source.rangev = " + num2str(v_range) + "\n")
	variable/g $(gv_folder + ":voltage_range") = v_range
end

function get_voltage_range()
	variable v_range = visa#read(hardware_id, "print(smua.source.rangev)\n")
	variable/g $(gv_folder + ":voltage_range") = v_range
	return v_range
end

function set_current_range(i_range)
	variable i_range
	visa#cmd(hardware_id, "smua.measure.rangei = " + num2str(i_range) + "\n")
	variable/g $(gv_folder + ":current_range") = i_range
end

function get_current_range()
	variable i_range = visa#read(hardware_id, "print(smua.measure.rangei)\n")
	variable/g $(gv_folder + ":current_range") = i_range
	return i_range
end

function set_current_limit(i_limit)
	variable i_limit
	visa#cmd(hardware_id, "smua.source.limiti = " + num2str(i_limit) + "\n")
	variable/g $(gv_folder + ":current_limit") = i_limit
end

function get_current_limit()
	variable i_limit = visa#read(hardware_id, "print(smua.source.limiti)\n")
	variable/g $(gv_folder + ":current_limit") = i_limit
	return i_limit
end

function set_voltage(v)
	variable v
	visa#cmd(hardware_id, "smua.source.func=smua.OUTPUT_DCVOLTS\n") // set to source voltage
	visa#cmd(hardware_id, "smua.source.levelv = " + num2str(v) + "\n")
	variable/g $(gv_folder + ":voltage") = v
end

function measure_voltage()
	variable voltage = visa#read(hardware_id, "print(smua.measure.v())\n")
	variable/g $(gv_folder + ":voltage") = voltage
	return voltage
end

function measure_current()
	variable current = visa#read(hardware_id, "print(smua.measure.i())\n")
	variable/g $(gv_folder + ":current") = current
	return current
end

function/c measure_iv()
	visa#cmd(hardware_id, "iRead, vRead = smua.measure.iv()\n")
	variable v = visa#read(hardware_id, "print(vRead)\n")
	variable i = visa#read(hardware_id, "print(iRead)\n")
	variable/g $(gv_folder + ":voltage") = v
	variable/g $(gv_folder + ":current") = i
	variable/c output = cmplx(v, i)
	return output
end

function measure_resistance()
	variable resistance = visa#read(hardware_id, "print(smua.measure.r())\n")
	variable/g $(gv_folder + ":resistance") = resistance
	return resistance
end

function check_current_range()
	variable i_range = get_current_range()
	variable current = measure_current()
	do
		if (current < 1e12)
			break
		endif
		i_range *= 10
		set_current_range(i_range)
		sleep/s 0.25
		current = measure_current()
	while (1)
	return i_range
end

// Panel Controls

function output_on_button(ba) : ButtonControl	// output on
	struct WMButtonAction &ba
	switch( ba.eventCode)
		case 2:
			open_comms()
			output(1)
			close_comms()
			break
	endswitch
	return 0
end

function output_off_button(ba) : ButtonControl	// output off
	struct WMButtonAction &ba
	switch( ba.eventCode)
		case 2:
			open_comms()
			output(0)
			close_comms()
			break
	endswitch
	return 0
end

function measure_voltage_button(ba) : ButtonControl	// measure voltage
	struct WMButtonAction &ba
	switch( ba.eventCode)
		case 2:
			open_comms()
			measure_voltage()
			close_comms()
			break
	endswitch
	return 0
end

function measure_current_button(ba) : ButtonControl	// measure current
	struct WMButtonAction &ba
	switch( ba.eventCode)
		case 2:
			open_comms()
			measure_current()
			close_comms()
			break
	endswitch
	return 0
end

function measure_resistance_button(ba) : ButtonControl	// measure resistance
	struct WMButtonAction &ba
	switch( ba.eventCode)
		case 2:
			open_comms()
			measure_resistance()
			close_comms()
			break
	endswitch
	return 0
end

function measure_iv_button(ba) : ButtonControl	// measure IV
	struct WMButtonAction &ba
	switch( ba.eventCode)
		case 2:
			open_comms()
			measure_iv()
			close_comms()
			break
	endswitch
	return 0
end

static function set_voltage_panel(sva) : setvariablecontrol
	struct wmsetvariableaction &sva
	switch( sva.eventcode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
			open_comms()
			set_voltage(dval)
			close_comms()
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

static function set_voltage_range_panel(sva) : setvariablecontrol
	struct wmsetvariableaction &sva
	switch( sva.eventcode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
			open_comms()
			set_voltage_range(dval)
			close_comms()
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

static function set_current_range_panel(sva) : setvariablecontrol
	struct wmsetvariableaction &sva
	switch( sva.eventcode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
			open_comms()
			set_current_range(dval)
			close_comms()
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

static function set_current_limit_panel(sva) : setvariablecontrol
	struct wmsetvariableaction &sva
	switch( sva.eventcode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
			open_comms()
			set_current_limit(dval)
			close_comms()
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

// Panel

static function/c insert_smu_panel(left, top) : panel
	variable left, top
	
	dfref gv_path = $gv_folder
	
	variable l_size = 350, t_size = 120
	groupbox smu_group, pos={left, top}, size={l_size, t_size}, frame=0, title="Keithley 2635A SMU"
	groupbox smu_group, labelBack=(56576,56576,56576), fsize=12, fStyle=1
	left += 5; top += 17
	// buttons
	titlebox smu_output title="Output", pos={left, top}, frame=0, fSize=11, fstyle=1
	top += 17
	button smu_on ,pos={left, top}, size={30,20}, proc=smu#output_on_button, title="On"
	button smu_on, fColor=(32768,65280,0)
	left += 30
	button smu_off ,pos={left, top}, size={30,20}, proc=smu#output_off_button, title="Off"
	button smu_off, fColor=(65280,0,0)
	left -= 30; top += 20
	titlebox smu_measure title="Measurements", pos={left, top}, frame=0, fSize=11, fstyle=1
	top += 17
	button smu_measure_voltage ,pos={left, top}, size={80,20}, proc=smu#measure_voltage_button, title="Meas. Voltage"
	top += 20
	button smu_measure_current ,pos={left, top}, size={80,20}, proc=smu#measure_current_button, title="Meas. Current"
	top -= 17 + 20 + 17 + 20
	// set and display variables
	left += 90
	titlebox smu_set title="Set Parameters", pos={left, top}, frame=0, fSize=11, fstyle=1
	top += 17
	setvariable smu_set_voltage, pos={left, top}, size={135,15}, bodywidth=70, title="voltage"
	setvariable smu_set_voltage, value=gv_path:voltage, proc=smu#set_voltage_panel
	top += 17
	setvariable smu_set_voltage_range, pos={left, top}, size={135,15}, bodywidth=70, title="voltage range"
	setvariable smu_set_voltage_range, value=gv_path:voltage_range, proc=smu#set_voltaget_range_panel
	top += 17
	setvariable smu_set_current_range, pos={left, top}, size={135,15}, bodywidth=70, title="current range"
	setvariable smu_set_current_range, value=gv_path:current_range, proc=smu#set_current_range_panel
	top += 17
	setvariable smu_set_current_limit, pos={left, top}, size={135,15}, bodywidth=70, title="current limit"
	setvariable smu_set_current_limit, value=gv_path:current_limit, proc=smu#set_current_limit_panel
	top -= 17*4
	// display only values
	left += 135
	titlebox smu_display title="Display Parameters", pos={left, top}, frame=0, fSize=11, fstyle=1
	top += 17
	valdisplay smu_current, pos={left, top}, size={100,15}, bodyWidth=60, title="current"
	valdisplay smu_current, limits={0,0,0}, barmisc={0,1000}
	valdisplay smu_current, value= #"root:global_variables:keithley_2635a_smu:current"
	return cmplx(l_size, t_size)
end