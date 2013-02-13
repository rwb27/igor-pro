#pragma ModuleName = dso
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "visa"
	static strconstant hardware_id = "agilent_dsox2012a_dso"
	static strconstant resourceName = "USB0::0x0957::0x1799::MY51330673::0::INSTR"
	static strconstant gv_folder = "root:global_variables:agilent_dsox2012a_dso"

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
	visa#cmd(hardware_id, "*rst")
	get_timebase()
	get_channel("1")
	get_channel("2")
	get_trigger()
end

function reset()
	visa#cmd(hardware_id, "*rst")
end

function set_general(mode, clear)
	string mode
	variable clear
	
	visa#cmd(hardware_id, ":stop")
	print visa#read_str(hardware_id, "*opc?")
	if (!stringmatch(mode, "run") && !stringmatch(mode, "single") && !stringmatch(mode, "stop"))
		abort "invalid mode (run | single | stop)"
	endif
	visa#cmd(hardware_id, ":"+mode)
	
	if (clear == 1)
		visa#cmd(hardware_id, "*cls")
	endif
	
	string/g $(gv_folder + ":mode") = mode
end

function set_timebase(mode, range, scale, delay, ref)
	variable range, scale, delay
	string mode, ref
	string param_dir = gv_folder + ":timebase_settings"
	visa#check_folder(param_dir)
	
	if (!stringmatch(mode, "main") && !stringmatch(mode, "window") && !stringmatch(mode, "xy") && !stringmatch(mode, "roll"))
		abort "invalid timebase mode (main | window | xy | roll)"
	endif
	visa#cmd(hardware_id, ":timebase:mode " + mode)
	string/g $(param_dir + ":time_mode") = mode
	
	if (stringmatch(mode, "window"))
		//set_window_timebase_dso()
	endif
	
	if (range != 0)
		visa#cmd(hardware_id, ":timebase:range " + num2str(range))
		variable/g $(param_dir + ":time_range") = range
		variable/g $(param_dir + ":time_scale") = 0
	endif
	if (scale != 0)
		visa#cmd(hardware_id, ":timebase:scale " + num2str(scale))
		variable/g $(param_dir + ":time_scale") = scale
		variable/g $(param_dir + ":time_range") = 0
	endif
	
	if (!stringmatch(ref, "left") && !stringmatch(ref, "center") && !stringmatch(ref, "right"))
		abort "invalid timebase reference (left | center | right)"
	endif
	visa#cmd(hardware_id, ":timebase:reference " + ref)
	string/g $(param_dir + ":time_reference") = ref
	
	visa#cmd(hardware_id, ":timebase:delay " + num2str(delay))
	variable/g $(param_dir + ":time_delay") = delay
end

function get_timebase()
	string param_dir = gv_folder + ":timebase_settings"
	visa#check_folder(param_dir)
	string/g $(param_dir + ":time_mode") = visa#read_str(hardware_id, ":timebase:mode?")
	variable/g $(param_dir + ":time_range") = visa#read(hardware_id, ":timebase:range?")
	variable/g $(param_dir + ":time_scale") = visa#read(hardware_id, ":timebase:scale?")
	string/g $(param_dir + ":time_reference") = visa#read_str(hardware_id, ":timebase:reference?")
	variable/g $(param_dir + ":time_delay") = visa#read(hardware_id, ":timebase:delay?")
end

function set_window_timebase(pos, range, scale)
	variable pos, range, scale
	visa#cmd(hardware_id, ":timebase:window:position " + num2str(pos))
	visa#cmd(hardware_id, ":timebase:window:range " + num2str(range))
	visa#cmd(hardware_id, ":timebase:window:scale " + num2str(scale))
end

function set_channel(ch, range, scale, offset, coupling, unit, ch_label, probe)
	variable range, scale, offset, probe
	string ch, coupling, unit, ch_label
	
	if (!stringmatch(ch, "1") && !stringmatch(ch, "2"))
		abort "invalid channel number (1 | 2)"
	endif
	string param_dir = gv_folder + ":" + ch + "_settings"
	visa#check_folder(param_dir)
	
	if (probe != 0)
		visa#cmd(hardware_id, ":channel"+ch+":probe " + num2str(probe))
		variable/g $(param_dir + ":ch" + ch + "_probe") = probe
	endif
	if (range != 0)
		visa#cmd(hardware_id, ":channel"+ch+":range " + num2str(range))			// 8 mV to 40 V range
		variable/g $(param_dir + ":ch" + ch + "_range") = range
	endif
	if (scale != 0)
		visa#cmd(hardware_id, ":channel" + ch + ":scale " + num2str(scale))		// Volts/div
		variable/g $(param_dir + ":ch" + ch + "_scale") = scale
	endif
	visa#cmd(hardware_id, ":channel" + ch + ":offset " + num2str(offset))
	variable/g $(param_dir + ":ch" + ch + "_offset") = offset
	
	if (!stringmatch(coupling, "ac") && !stringmatch(coupling, "dc"))
		abort "invalid channel coupling (ac | dc)"
	endif
	visa#cmd(hardware_id, ":channel" + ch + ":coupling " + coupling)
	string/g $(param_dir + ":ch" + ch + "_coupling") = coupling
	
	if (stringmatch(unit, "V"))
		visa#cmd(hardware_id, ":channel"+ch+":units volt")
		string/g $(param_dir + ":ch" + ch + "_unit") = unit
	elseif (stringmatch(unit, "A"))
		visa#cmd(hardware_id, ":channel"+ch+":units ampere")
		string/g $(param_dir + ":ch" + ch + "_unit") = unit
	else
		abort "invalid channel unit (V | A)"
	endif
	
	if (!stringmatch(ch_label, ""))
		visa#cmd(hardware_id, ":channel"+ch+":label "+ch_label)
		string/g $(param_dir + ":ch" + ch + "_label") = ch_label
	endif
	
	visa#cmd(hardware_id, ":channel"+ch+":display 1")
end

function get_channel(ch)
	string ch
	if (!stringmatch(ch, "1") && !stringmatch(ch, "2"))
		abort "invalid channel number (1 | 2)"
	endif
	string param_dir = gv_folder + ":" + ch + "_settings"
	visa#check_folder(param_dir)
	variable/g $(param_dir + ":ch" + ch + "_probe") = visa#read(hardware_id, ":channel"+ch+":probe?")
	variable/g $(param_dir + ":ch" + ch + "_range") = visa#read(hardware_id, ":channel"+ch+":range?")
	variable/g $(param_dir + ":ch" + ch + "_scale") = visa#read(hardware_id, ":channel" + ch + ":scale?")
	variable/g $(param_dir + ":ch" + ch + "_offset") = visa#read(hardware_id, ":channel" + ch + ":offset?")
	string/g $(param_dir + ":ch" + ch + "_coupling") = visa#read_str(hardware_id, ":channel" + ch + ":coupling?")
	string/g $(param_dir + ":ch" + ch + "_unit") = visa#read_str(hardware_id, ":channel"+ch+":units?")
	string/g $(param_dir + ":ch" + ch + "_label") = visa#read_str(hardware_id, ":channel"+ch+":label?")
end

function set_trigger(sweep, mode, source, level, slope, rejectnoise, filter)
	variable level
	string sweep, mode, source, slope, rejectnoise, filter
	string param_dir = gv_folder + ":trigger_settings"
	visa#check_folder(param_dir)
	
	// sweep settings
	if (!stringmatch(sweep, "normal") && !stringmatch(sweep, "auto"))
		abort "invalid trigger sweep (normal | auto)"
	endif
	visa#cmd(hardware_id, ":trigger:sweep "+sweep)
	string/g $(param_dir + ":trigger_sweep") = sweep
	
	// trigger mode
	if (!stringmatch(mode, "edge") && !stringmatch(mode, "gitch") && !stringmatch(mode, "pattern") && !stringmatch(mode, "tv"))
		abort "invalid trigger mode (edge | glitch | pattern | tv)"
	endif
	visa#cmd(hardware_id, ":trigger:mode "+mode)
	string/g $(param_dir + ":trigger_mode") = mode
	
	// trigger source
	if (!stringmatch(source, "channel*") && !stringmatch(source, "external") && !stringmatch(source, "line") && !stringmatch(source, "wgen"))
		abort "invalid trigger source (channel<n> | external | line | wgen)"
	endif
	visa#cmd(hardware_id, ":trigger:source "+source)
	string/g $(param_dir + ":trigger_source") = source
	
	// trigger level
	visa#cmd(hardware_id, ":trigger:level " + num2str(level))
	variable/g $(param_dir + ":trigger_level") = level
	
	// slope settings
	if (!stringmatch(slope, "positive") && !stringmatch(slope, "negative") && !stringmatch(slope, "either") && !stringmatch(slope, "alternate"))
		abort "invalid trigger slope (positive | negative | either | alternate)"
	endif
	visa#cmd(hardware_id, ":trigger:slope "+slope)
	string/g $(param_dir + ":trigger_slope") = slope
	
	// noise rejection
	if (!stringmatch(rejectnoise, "0") && !stringmatch(rejectnoise, "1"))
		abort "invalid trigger noise rejection (1 | 0)"
	endif
	visa#cmd(hardware_id, ":trigger:nreject "+rejectnoise)
	string/g $(param_dir + ":trigger_nreject") = rejectnoise
	
	// high pass filter
	if (!stringmatch(filter,"0") && !stringmatch(filter,"1"))
		abort "invalid trigger filter (1 | 0)"
	endif
	visa#cmd(hardware_id, ":trigger:hfreject "+filter)
	string/g $(param_dir + ":trigger_hfreject") = filter
end

function get_trigger()
	string param_dir = gv_folder + ":trigger_settings"
	visa#check_folder(param_dir)
	variable/g $(param_dir + ":trigger_level") = visa#read(hardware_id, ":trigger:level?")
end

function set_acquire(type)
	string type
	string param_dir = gv_folder + ":acquire_settings"
	visa#check_folder(param_dir)
	
	// setup acquire type
	if (!stringmatch(type,"normal") && !stringmatch(type,"average") && !stringmatch(type,"hresolution") && !stringmatch(type,"peak"))
		abort "invalid acquire type (normal | average | hresolution | peak)"
	endif
	visa#cmd(hardware_id, ":acquire:type " + type)
	string/g $(param_dir + ":acquire_type") = type
	visa#cmd(hardware_id, ":acquire:complete 100")
	variable/g $(param_dir + ":acquire_complete") = 100

	if (stringmatch(type, "average"))
		visa#cmd(hardware_id, ":acquire:count 8")
	endif
end

function capture_all()
	visa#cmd(hardware_id, ":digitize")
end

Function capture(ch)
	string ch
	if (!stringmatch(ch, "1") && !stringmatch(ch, "2"))
		abort "invalid channel number (1 | 2)"
	endif
	visa#cmd(hardware_id, ":digitize channel"+ch)
end

function import_data_dso(ch, wname)
	string ch, wname
	nvar instr = $(gv_folder + ":instr")
	string param_dir = gv_folder + ":import_parameters"
	visa#check_folder(param_dir)
	
	// import data
	variable points = visa#read(hardware_id, ":acquire:points?")
	make/o/n=(points+10) $wname
	wave w = $wname
	w = 0
	VISAwrite instr, ":waveform:source channel"+ch
	VISAwrite instr, ":waveform:format byte"
	VISAwrite instr, "waveform:unsigned 0"
	VISAwrite instr, ":waveform:points "+num2str(points)
	VISAwrite instr, ":waveform:data?"
	VISAReadBinaryWave/type=(0x08)/b instr, w
	deletepoints 0, 10, w
	
	// scale data
	variable y_or, y_inc, y_ref, x_or, x_inc
	y_or = visa#read(hardware_id, "waveform:yorigin?")
	y_inc = visa#read(hardware_id, "waveform:yincrement?")
	y_ref = visa#read(hardware_id, "waveform:yreference?")
	x_or = visa#read(hardware_id, "waveform:xorigin?")
	x_inc = visa#read(hardware_id, "waveform:xincrement?")
	w = y_or + (y_inc * (w - y_ref))
	setscale d, 0, 0, "V", w
	setscale/p x, x_or, x_inc, "s", w
	variable/g $(param_dir + ":y_or") = y_or
	variable/g $(param_dir + ":y_inc") = y_inc
	variable/g $(param_dir + ":y_ref") = y_ref
	variable/g $(param_dir + ":x_or") = x_or
	variable/g $(param_dir + ":x_inc") = x_inc
end

function check_trigger()
	if ((visa#read(hardware_id, ":operegister:condition?") & 8) == 0)
		return 1
	else
		return 0
	endif
end

