#pragma rtGlobals=1		// Use modern global access method.
//
// v3, 01/02/13, AS
//

// required functions

function check_folder_dso(data_folder)
	string data_folder
	if (!datafolderexists(data_folder))
		newdatafolder $data_folder
	endif
end

function open_dso()
	variable session, instr, status
	string resourceName = "USB0::0x0957::0x1799::MY51330673::0::INSTR"
	string data_folder = "root:global_variables"
	check_folder_dso(data_folder)
	data_folder += ":agilent_dsox2012a_dso"
	check_folder_dso(data_folder)
	
	string error_message
	status = viOpenDefaultRM(session)
	if (status < 0)
		string error_message
		viStatusDesc(instr, status, error_message)
		abort error_message
	endif
	status = viOpen(session, resourceName, 0, 0, instr)
	if (status < 0)
		string error_message
		viStatusDesc(instr, status, error_message)
		abort error_message
	endif
	status = viClear(session)
	if (status < 0)
		string error_message
		viStatusDesc(instr, status, error_message)
		abort error_message
	endif
	variable/g $(data_folder + ":instr") = instr
	variable/g $(data_folder + ":session") = session
	return status
end

function close_dso()
	nvar session = root:global_variables:agilent_dsox2012a_dso:session
	variable status
	status = viClear(session)
	if (status < 0)
		string error_message
		viStatusDesc(instr, status, error_message)
		abort error_message
	endif
	status = viCLose(session)
	if (status < 0)
		string error_message
		viStatusDesc(instr, status, error_message)
		abort error_message
	endif
	return status
end

function cmd_dso(cmd)
	string cmd
	nvar instr = root:global_variables:agilent_dsox2012a_dso:instr
	VISAwrite instr, cmd
end

function read_dso(cmd)
	string cmd
	variable value
	nvar instr = root:global_variables:agilent_dsox2012a_dso:instr
	VISAwrite instr, cmd
	VISAread instr, value
	return value
end

function/s read_str_dso(cmd)
	string cmd
	string message
	nvar instr = root:global_variables:agilent_dsox2012a_dso:instr
	VISAwrite instr, cmd
	VISAread/t="\n" instr, message
	return message
end

function read_buffer_dso()
	variable value
	nvar instr = root:global_variables:agilent_dsox2012a_dso:instr
	VISAread instr, value
	return value
end

function reset_dso()
	cmd_dso("*rst")
end

function init_dso()
end

// setup functions

function set_general_dso(mode, clear)
	string mode
	variable clear
	
	cmd_dso(":stop")
	print read_str_dso("*opc?")
	if (!stringmatch(mode, "run") && !stringmatch(mode, "single") && !stringmatch(mode, "stop"))
		abort "invalid mode (run | single | stop)"
	endif
	cmd_dso(":"+mode)
	
	if (clear == 1)
		cmd_dso("*cls")
	endif
	
	string/g root:global_variables:agilent_dsox2012a_dso:mode = mode
end

function set_timebase_dso(mode, range, scale, delay, ref)
	variable range, scale, delay
	string mode, ref
	string param_dir = "root:global_variables:agilent_dsox2012a_dso:timebase_settings"
	check_folder_dso(param_dir)
	
	if (!stringmatch(mode, "main") && !stringmatch(mode, "window") && !stringmatch(mode, "xy") && !stringmatch(mode, "roll"))
		abort "invalid timebase mode (main | window | xy | roll)"
	endif
	cmd_dso(":timebase:mode " + mode)
	string/g $(param_dir + ":time_mode") = mode
	
	if (stringmatch(mode, "window"))
		//set_window_timebase_dso()
	endif
	
	if (range != 0)
		cmd_dso(":timebase:range " + num2str(range))
		variable/g $(param_dir + ":time_range") = range
		variable/g $(param_dir + ":time_scale") = 0
	endif
	if (scale != 0)
		cmd_dso(":timebase:scale " + num2str(scale))
		variable/g $(param_dir + ":time_scale") = scale
		variable/g $(param_dir + ":time_range") = 0
	endif
	
	if (!stringmatch(ref, "left") && !stringmatch(ref, "center") && !stringmatch(ref, "right"))
		abort "invalid timebase reference (left | center | right)"
	endif
	cmd_dso(":timebase:reference " + ref)
	string/g $(param_dir + ":time_reference") = ref
	
	cmd_dso(":timebase:delay " + num2str(delay))
	variable/g $(param_dir + ":time_delay") = delay
end

function set_window_timebase_dso(pos, range, scale)
	variable pos, range, scale
	cmd_dso(":timebase:window:position " + num2str(pos))
	cmd_dso(":timebase:window:range " + num2str(range))
	cmd_dso(":timebase:window:scale " + num2str(scale))
end

function set_channel_dso(ch, range, scale, offset, coupling, unit, ch_label, probe)
	variable range, scale, offset, probe
	string ch, coupling, unit, ch_label
	
	if (!stringmatch(ch, "1") && !stringmatch(ch, "2"))
		abort "invalid channel number (1 | 2)"
	endif
	string param_dir = "root:global_variables:agilent_dsox2012a_dso:" + ch + "_settings"
	check_folder_dso(param_dir)
	
	if (probe != 0)
		cmd_dso(":channel"+ch+":probe " + num2str(probe))
		variable/g $(param_dir + ":ch" + ch + "_probe") = probe
	endif
	if (range != 0)
		cmd_dso(":channel"+ch+":range " + num2str(range))			// 8 mV to 40 V range
		variable/g $(param_dir + ":ch" + ch + "_range") = range
	endif
	if (scale != 0)
		cmd_dso(":channel" + ch + ":scale " + num2str(scale))		// Volts/div
		variable/g $(param_dir + ":ch" + ch + "_scale") = scale
	endif
	cmd_dso(":channel" + ch + ":offset " + num2str(offset))
	variable/g $(param_dir + ":ch" + ch + "_offset") = offset
	
	if (!stringmatch(coupling, "ac") && !stringmatch(coupling, "dc"))
		abort "invalid channel coupling (ac | dc)"
	endif
	cmd_dso(":channel" + ch + ":coupling "+coupling)
	string/g $(param_dir + ":ch" + ch + "_coupling") = coupling
	
	if (stringmatch(unit, "V"))
		cmd_dso(":channel"+ch+":units volt")
		string/g $(param_dir + ":ch" + ch + "_unit") = unit
	elseif (stringmatch(unit, "A"))
		cmd_dso(":channel"+ch+":units ampere")
		string/g $(param_dir + ":ch" + ch + "_unit") = unit
	else
		abort "invalid channel unit (V | A)"
	endif
	
	if (!stringmatch(ch_label, ""))
		cmd_dso(":channel"+ch+":label "+ch_label)
		string/g $(param_dir + ":ch" + ch + "_label") = ch_label
	endif
	
	cmd_dso(":channel"+ch+":display 1")
end

function set_trigger_dso(sweep, mode, source, level, slope, rejectnoise, filter)
	variable level
	string sweep, mode, source, slope, rejectnoise, filter
	string param_dir = "root:global_variables:agilent_dsox2012a_dso:trigger_settings"
	check_folder_dso(param_dir)
	
	// sweep settings
	if (!stringmatch(sweep, "normal") && !stringmatch(sweep, "auto"))
		abort "invalid trigger sweep (normal | auto)"
	endif
	cmd_dso(":trigger:sweep "+sweep)
	string/g $(param_dir + ":trigger_sweep") = sweep
	
	// trigger mode
	if (!stringmatch(mode, "edge") && !stringmatch(mode, "gitch") && !stringmatch(mode, "pattern") && !stringmatch(mode, "tv"))
		abort "invalid trigger mode (edge | glitch | pattern | tv)"
	endif
	cmd_dso(":trigger:mode "+mode)
	string/g $(param_dir + ":trigger_mode") = mode
	
	// trigger source
	if (!stringmatch(source, "channel*") && !stringmatch(source, "external") && !stringmatch(source, "line") && !stringmatch(source, "wgen"))
		abort "invalid trigger source (channel<n> | external | line | wgen)"
	endif
	cmd_dso(":trigger:source "+source)
	string/g $(param_dir + ":trigger_source") = source
	
	// trigger level
	cmd_dso(":trigger:level " + num2str(level))
	variable/g $(param_dir + ":trigger_level") = level
	
	// slope settings
	if (!stringmatch(slope, "positive") && !stringmatch(slope, "negative") && !stringmatch(slope, "either") && !stringmatch(slope, "alternate"))
		abort "invalid trigger slope (positive | negative | either | alternate)"
	endif
	cmd_dso(":trigger:slope "+slope)
	string/g $(param_dir + ":trigger_slope") = slope
	
	// noise rejection
	if (!stringmatch(rejectnoise, "0") && !stringmatch(rejectnoise, "1"))
		abort "invalid trigger noise rejection (1 | 0)"
	endif
	cmd_dso(":trigger:nreject "+rejectnoise)
	string/g $(param_dir + ":trigger_nreject") = rejectnoise
	
	// high pass filter
	if (!stringmatch(filter,"0") && !stringmatch(filter,"1"))
		abort "invalid trigger filter (1 | 0)"
	endif
	cmd_dso(":trigger:hfreject "+filter)
	string/g $(param_dir + ":trigger_hfreject") = filter
end

function set_acquire_dso(type)
	string type
	string param_dir = "root:global_variables:agilent_dsox2012a_dso:acquire_settings"
	check_folder_dso(param_dir)
	
	// setup acquire type
	if (!stringmatch(type,"normal") && !stringmatch(type,"average") && !stringmatch(type,"hresolution") && !stringmatch(type,"peak"))
		abort "invalid acquire type (normal | average | hresolution | peak)"
	endif
	cmd_dso(":acquire:type " + type)
	string/g $(param_dir + ":acquire_type") = type
	cmd_dso(":acquire:complete 100")
	variable/g $(param_dir + ":acquire_complete") = 100

	if (stringmatch(type, "average"))
		cmd_dso(":acquire:count 8")
	endif
end

// capture functions

function capture_all_dso()
	cmd_dso(":digitize")
end

Function capture_dso(ch)
	string ch
	if (!stringmatch(ch, "1") && !stringmatch(ch, "2"))
		abort "invalid channel number (1 | 2)"
	endif
	cmd_dso(":digitize channel"+ch)
end

function import_data_dso(ch, wname)
	string ch, wname
	nvar instr = root:global_variables:agilent_dsox2012a_dso:instr
	string param_dir = "root:global_variables:agilent_dsox2012a_dso:import_parameters"
	check_folder_dso(param_dir)
	
	// import data
	variable points = read_dso(":acquire:points?")
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
	y_or = read_dso("waveform:yorigin?")
	y_inc = read_dso("waveform:yincrement?")
	y_ref = read_dso("waveform:yreference?")
	x_or = read_dso("waveform:xorigin?")
	x_inc = read_dso("waveform:xincrement?")
	w = y_or + (y_inc * (w - y_ref))
	setscale d, 0, 0, "V", w
	setscale/p x, x_or, x_inc, "s", w
	variable/g $(param_dir + ":y_or") = y_or
	variable/g $(param_dir + ":y_inc") = y_inc
	variable/g $(param_dir + ":y_ref") = y_ref
	variable/g $(param_dir + ":x_or") = x_or
	variable/g $(param_dir + ":x_inc") = x_inc
end

// check functions

function check_trigger_dso()
	if ((read_dso(":operegister:condition?") & 8) == 0)
		return 1
	else
		return 0
	endif
end