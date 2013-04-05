#pragma ModuleName = dso
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "visa_comms"
static strconstant hardware_id = "agilent_dsox2012a_dso"
static strconstant resourceName = "USB0::0x0957::0x1799::MY51330673::0::INSTR"
static strconstant gv_folder = "root:global_variables:agilent_dsox2012a_dso"
static strconstant data_folder = "root:agilent_dsox2012a_dso"

static function check_folder(data_folder)
	string data_folder
	if (!datafolderexists(data_folder))
		newdatafolder $data_folder
	endif
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

static function/s gv_path()
	return gv_folder
end

static function initialise()
	check_folder(data_folder)
	visa#cmd(hardware_id, "*rst")
	sleep/s 1
	get_timebase()
	get_channel("1")
	get_channel("2")
	get_trigger()
end

static function reset()
	visa#cmd(hardware_id, "*rst")
end

static function set_general(mode, clear)
	string mode
	variable clear
	
	visa#cmd(hardware_id, ":stop")
	visa#read_str(hardware_id, "*opc?")
	if (!stringmatch(mode, "run") && !stringmatch(mode, "single") && !stringmatch(mode, "stop"))
		abort "invalid mode (run | single | stop)"
	endif
	visa#cmd(hardware_id, ":"+mode)
	
	if (clear == 1)
		visa#cmd(hardware_id, "*cls")
	endif
	
	string/g $(gv_folder + ":mode") = mode
end

static function set_timebase(mode, range, scale, delay, ref)
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

static function get_timebase()
	string param_dir = gv_folder + ":timebase_settings"
	visa#check_folder(param_dir)
	string/g $(param_dir + ":time_mode") = visa#read_str(hardware_id, ":timebase:mode?")
	variable/g $(param_dir + ":time_range") = visa#read(hardware_id, ":timebase:range?")
	variable/g $(param_dir + ":time_scale") = visa#read(hardware_id, ":timebase:scale?")
	string/g $(param_dir + ":time_reference") = visa#read_str(hardware_id, ":timebase:reference?")
	variable/g $(param_dir + ":time_delay") = visa#read(hardware_id, ":timebase:delay?")
end

static function set_window_timebase(pos, range, scale)
	variable pos, range, scale
	visa#cmd(hardware_id, ":timebase:window:position " + num2str(pos))
	visa#cmd(hardware_id, ":timebase:window:range " + num2str(range))
	visa#cmd(hardware_id, ":timebase:window:scale " + num2str(scale))
end

static function set_channel(ch, range, scale, offset, coupling, unit, ch_label, probe)
	variable range, scale, offset, probe
	string ch, coupling, unit, ch_label
	
	if (!stringmatch(ch, "1") && !stringmatch(ch, "2"))
		abort "invalid channel number (1 | 2)"
	endif
	string param_dir = gv_folder + ":ch" + ch + "_settings"
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
	
	if (stringmatch(unit, "V") || stringmatch(unit, "volt"))
		visa#cmd(hardware_id, ":channel"+ch+":units volt")
		string/g $(param_dir + ":ch" + ch + "_unit") = unit
	elseif (stringmatch(unit, "A") || stringmatch(unit, "amp"))
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

static function get_channel(ch)
	string ch
	if (!stringmatch(ch, "1") && !stringmatch(ch, "2"))
		abort "invalid channel number (1 | 2)"
	endif
	string param_dir = gv_folder + ":ch" + ch + "_settings"
	visa#check_folder(param_dir)
	variable/g $(param_dir + ":ch" + ch + "_probe") = visa#read(hardware_id, ":channel"+ch+":probe?")
	variable/g $(param_dir + ":ch" + ch + "_range") = visa#read(hardware_id, ":channel"+ch+":range?")
	variable/g $(param_dir + ":ch" + ch + "_scale") = visa#read(hardware_id, ":channel" + ch + ":scale?")
	variable/g $(param_dir + ":ch" + ch + "_offset") = visa#read(hardware_id, ":channel" + ch + ":offset?")
	string/g $(param_dir + ":ch" + ch + "_coupling") = visa#read_str(hardware_id, ":channel" + ch + ":coupling?")
	string/g $(param_dir + ":ch" + ch + "_unit") = visa#read_str(hardware_id, ":channel"+ch+":units?")
	string/g $(param_dir + ":ch" + ch + "_label") = visa#read_str(hardware_id, ":channel"+ch+":label?")
end

static function set_trigger(sweep, mode, source, level, slope, rejectnoise, filter)
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
	if (!stringmatch(source, "ch*") && !stringmatch(source, "external") && !stringmatch(source, "line") && !stringmatch(source, "wgen"))
		abort "invalid trigger source (ch*<n> | external | line | wgen)"
	endif
	visa#cmd(hardware_id, ":trigger:source "+source)
	string/g $(param_dir + ":trigger_source") = source
	
	// trigger level
	visa#cmd(hardware_id, ":trigger:level " + num2str(level))
	variable/g $(param_dir + ":trigger_level") = level
	
	// slope settings
	if (!stringmatch(slope, "pos*") && !stringmatch(slope, "neg*") && !stringmatch(slope, "either") && !stringmatch(slope, "alternate"))
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

static function get_trigger()
	string param_dir = gv_folder + ":trigger_settings"
	visa#check_folder(param_dir)
	variable/g $(param_dir + ":trigger_level") = visa#read(hardware_id, ":trigger:level?")
	string/g $(param_dir + ":trigger_sweep") = visa#read_str(hardware_id, ":trigger:sweep?")
	string/g $(param_dir + ":trigger_mode") = visa#read_str(hardware_id, ":trigger:mode?")
	string/g $(param_dir + ":trigger_source") = visa#read_str(hardware_id, ":trigger:source?")
	string/g $(param_dir + ":trigger_slope") = visa#read_str(hardware_id, ":trigger:slope?")
	string/g $(param_dir + ":trigger_nreject") = visa#read_str(hardware_id, ":trigger:nreject?")
	string/g $(param_dir + ":trigger_hfreject") = visa#read_str(hardware_id, ":trigger:hfreject?")
end

static function set_acquire(type)
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

static function capture_all()
	visa#cmd(hardware_id, ":digitize")
end

static function capture(ch)
	string ch
	if (!stringmatch(ch, "1") && !stringmatch(ch, "2"))
		abort "invalid channel number (1 | 2)"
	endif
	visa#cmd(hardware_id, ":digitize channel"+ch)
end

static function/wave import_data(ch, wname)
	string ch, wname
	nvar instr = $(gv_folder + ":instr")
	string param_dir = gv_folder + ":import_parameters"
	visa#check_folder(param_dir)
	visa#check_folder(data_folder)
	
	// import data
	variable points = visa#read(hardware_id, ":acquire:points?")
	variable/g $(param_dir + ":points") = points
	
	if (stringmatch(wname, ""))
		wname = "ch" + ch + "_trace"
	endif
	
	wname = data_folder + ":" + wname
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
	return w
end

static function/wave import_data_free(ch)
	string ch
	make/free w
	nvar instr = $(gv_folder + ":instr")
	string param_dir = gv_folder + ":import_parameters"
	visa#check_folder(param_dir)
	visa#check_folder(data_folder)
	
	// import data
	variable points = visa#read(hardware_id, ":acquire:points?")
	variable/g $(param_dir + ":points") = points
	
	redimension/n=(points) w
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
	return w
end

static function check_trigger(force)
	variable force
	if ((visa#read(hardware_id, ":operegister:condition?") & 8) == 0)
		return 1
	else
		if (force)
			visa#cmd(hardware_id, ":trigger:force")
		endif
		return 0
	endif
end

static function arm_trigger()
	visa#cmd(hardware_id, ":single")
end

static function wave_mean(ch)
	string ch
	wave w = import_data_free(ch)
	return mean(w)
end

// Panel Controls

static function capture_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch(ba.eventcode)
		case 2:
			open_comms()
			capture_all()
			close_comms()
			break
	endswitch
	return 0
end

static function import_data_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch(ba.eventcode)
		case 2:
			open_comms()
			import_data("1", "")
			import_data("2", "")
			close_comms()
			break
	endswitch
	return 0
end

static function run_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch(ba.eventcode)
		case 2:
			open_comms()
			set_general("run", 0)
			close_comms()
			break
	endswitch
	return 0
end

static function single_acq_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch(ba.eventcode)
		case 2:
			open_comms()
			set_general("single", 0)
			close_comms()
			break
	endswitch
	return 0
end

static function stop_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch(ba.eventcode)
		case 2:
			open_comms()
			set_general("stop", 0)
			close_comms()
			break
	endswitch
	return 0
end

static function set_timebase_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch(ba.eventcode)
		case 2:
			svar/sdfr=$gv_folder mode = :timebase_settings:time_mode
			nvar/sdfr=$gv_folder range = :timebase_settings:time_range
			nvar/sdfr=$gv_folder scale = :timebase_settings:time_scale
			nvar/sdfr=$gv_folder delay = :timebase_settings:time_delay
			svar/sdfr=$gv_folder ref = :timebase_settings:time_reference
			open_comms()
			set_timebase(mode, range, scale, delay, ref)
			close_comms()
			break
	endswitch
	return 0
end

static function get_timebase_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch(ba.eventcode)
		case 2:
			open_comms()
			get_timebase()
			close_comms()
			break
	endswitch
	return 0
end

static function set_ch1_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			nvar/sdfr=$gv_folder range = :ch1_settings:ch1_range
			nvar/sdfr=$gv_folder scale = :ch1_settings:ch1_scale
			nvar/sdfr=$gv_folder offset = :ch1_settings:ch1_offset
			svar/sdfr=$gv_folder coupling = :ch1_settings:ch1_coupling
			svar/sdfr=$gv_folder unit = :ch1_settings:ch1_unit
			svar/sdfr=$gv_folder ch_label = :ch1_settings:ch1_label
			nvar/sdfr=$gv_folder probe = :ch1_settings:ch1_probe
			open_comms()
			set_channel("1", range, scale, offset, coupling, unit, ch_label, probe)
			close_comms()
			break
	endswitch
	return 0
end

static function get_ch1_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch(ba.eventcode)
		case 2:
			open_comms()
			get_channel("1")
			close_comms()
			break
	endswitch
	return 0
end

static function set_ch2_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			nvar/sdfr=$gv_folder range = :ch2_settings:ch2_range
			nvar/sdfr=$gv_folder scale = :ch2_settings:ch2_scale
			nvar/sdfr=$gv_folder offset = :ch2_settings:ch2_offset
			svar/sdfr=$gv_folder coupling = :ch2_settings:ch2_coupling
			svar/sdfr=$gv_folder unit = :ch2_settings:ch2_unit
			svar/sdfr=$gv_folder ch_label = :ch2_settings:ch2_label
			nvar/sdfr=$gv_folder probe = :ch2_settings:ch2_probe
			open_comms()
			set_channel("2", range, scale, offset, coupling, unit, ch_label, probe)
			close_comms()
			break
	endswitch
	return 0
end

static function get_ch2_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch(ba.eventcode)
		case 2:
			open_comms()
			get_channel("2")
			close_comms()
			break
	endswitch
	return 0
end

static function set_trigger_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch(ba.eventcode)
		case 2:
			svar/sdfr=$gv_folder sweep = :trigger_settings:trigger_sweep
			svar/sdfr=$gv_folder mode = :trigger_settings:trigger_mode
			svar/sdfr=$gv_folder source = :trigger_settings:trigger_source
			nvar/sdfr=$gv_folder level = :trigger_settings:trigger_level
			svar/sdfr=$gv_folder slope = :trigger_settings:trigger_slope
			svar/sdfr=$gv_folder rejectnoise = :trigger_settings:trigger_nreject
			svar/sdfr=$gv_folder filter = :trigger_settings:trigger_hfreject
			open_comms()
			set_trigger(sweep, mode, source, level, slope, rejectnoise, filter)
			close_comms()
			break
	endswitch
	return 0
end

static function get_trigger_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch(ba.eventcode)
		case 2:
			open_comms()
			get_trigger()
			close_comms()
			break
	endswitch
	return 0
end

// Panel

static function/c insert_dso_panel(left, top) : panel
	variable left, top
	
	dfref gv_path = $gv_folder
	
	variable l_size = 390, t_size = 320
	groupbox dso_group, pos={left, top}, size={l_size, t_size}, frame=0, title="Agilent DSOX-2000 Series DSO"
	groupbox dso_group, labelBack=(56576,56576,56576), fsize=12, fStyle=1
	left += 5; top += 17
	
	// buttons
	titlebox dso_controls title="DSO Controls", pos={left, top}, frame=0, fSize=11, fstyle=1
	top += 17
	titlebox dso_mode title="Mode:", pos={left, top}, frame=0, fSize=11; left+= 50
	button dso_run,pos={left, top}, size={40,20}, fColor=(32768,65280,0), proc=dso#run_button, title="Run";	top += 20
	button dso_single,pos={left, top}, size={40,20}, fColor=(65280,65280,0), proc=dso#single_acq_button, title="Single"; top += 20
	button dso_stop,pos={left, top}, size={40,20}, fColor=(65280,0,0), proc=dso#stop_button, title="Stop";
	left -= 50; top += 20
	titlebox dso_timebase title="TimeBase:", pos={left, top}, frame=0, fSize=11; left+= 55
	button dso_set_timebase,pos={left, top}, size={30,20}, proc=dso#set_timebase_button, title="Set";	left += 30
	button dso_get_timebase,pos={left, top}, size={30,20}, proc=dso#get_timebase_button, title="Get"
	left -= 55 + 30; top += 20
	titlebox dso_ch1 title="Channel 1:", pos={left, top}, frame=0, fSize=11; left+= 55
	button dso_set_ch1,pos={left, top}, size={30,20}, proc=dso#set_ch1_button, title="Set";	left += 30
	button dso_get_ch1,pos={left, top}, size={30,20}, proc=dso#get_ch1_button, title="Get"
	left -= 55 + 30; top += 20
	titlebox dso_ch2 title="Channel 2:", pos={left, top}, frame=0, fSize=11; left+= 55
	button dso_set_ch2,pos={left, top}, size={30,20}, proc=dso#set_ch2_button, title="Set";	left += 30
	button dso_get_ch2,pos={left, top}, size={30,20}, proc=dso#get_ch2_button, title="Get"
	left -= 55 + 30; top += 20
	titlebox dso_trigger title="Trigger:", pos={left, top}, frame=0, fSize=11; left+= 55
	button dso_set_trigger,pos={left, top}, size={30,20}, proc=dso#set_trigger_button, title="Set";	left += 30
	button dso_get_trigger,pos={left, top}, size={30,20}, proc=dso#get_trigger_button, title="Get"
	left -= 55 + 30; top += 20

	button dso_capture,pos={left, top}, size={50,20}, proc=dso#capture_button, title="Capture";	left += 50
	button dso_import,pos={left, top}, size={50,20}, proc=dso#import_data_button, title="Import"
	left -= 50; top -= 17 + 20 + 20 + 20 + 20 + 20 + 20 + 20
	
	// set and display variables
	left += 120
	titlebox dso_params title="Parameters", pos={left, top}, frame=0, fSize=11, fstyle=1
	top += 17
		// timebase
	dfref tb_path = $(gv_folder + ":timebase_settings")
	titlebox timebase title="TimeBase", pos={left, top}, frame=0, fSize=11, fstyle=1
	top += 17
	setvariable timebase_set_mode, pos={left, top}, size={125,15}, bodywidth=70, title="mode"
	setvariable timebase_set_mode, value= tb_path:time_mode
	top += 17
	setvariable timebase_set_range, pos={left, top}, size={125,15}, bodywidth=70, title="range"
	setvariable timebase_set_range, value= tb_path:time_range
	top += 17
	setvariable timebase_set_scale, pos={left, top}, size={125,15}, bodywidth=70, title="scale"
	setvariable timebase_set_scale, value= tb_path:time_scale
	top += 17
	setvariable timebase_set_delay, pos={left, top}, size={125,15}, bodywidth=70, title="delay"
	setvariable timebase_set_delay, value= tb_path:time_delay
	top += 17
	setvariable timebase_set_reference, pos={left, top}, size={125,15}, bodywidth=70, title="reference"
	setvariable timebase_set_reference, value= tb_path:time_reference
	top -= 17*5
		// trigger
	dfref trig_path = $(gv_folder + ":trigger_settings")
	left += 135
	titlebox trigger title="Trigger", pos={left, top}, frame=0, fSize=11, fstyle=1
	top += 17
	setvariable trigger_set_sweep, pos={left, top}, size={125,15}, bodywidth=70, title="sweep"
	setvariable trigger_set_sweep, value= trig_path:trigger_sweep
	top += 17
	setvariable trigger_set_mode, pos={left, top}, size={125,15}, bodywidth=70, title="mode"
	setvariable trigger_set_mode, value= trig_path:trigger_mode
	top += 17
	setvariable trigger_set_source, pos={left, top}, size={125,15}, bodywidth=70, title="source"
	setvariable trigger_set_source, value= trig_path:trigger_source
	top += 17
	setvariable trigger_set_level, pos={left, top}, size={125,15}, bodywidth=70, title="level"
	setvariable trigger_set_level, value= trig_path:trigger_level
	top += 17
	setvariable trigger_set_slope, pos={left, top}, size={125,15}, bodywidth=70, title="slope"
	setvariable trigger_set_slope, value= trig_path:trigger_slope
	top += 17
	setvariable trigger_set_nreject, pos={left, top}, size={125,15}, bodywidth=70, title="nreject"
	setvariable trigger_set_nreject, value= trig_path:trigger_nreject
	top += 17
	setvariable trigger_set_hfreject, pos={left, top}, size={125,15}, bodywidth=70, title="hfreject"
	setvariable trigger_set_hfreject, value= trig_path:trigger_hfreject
	top -= 17*7
		// channel 1
	dfref ch1_path = $(gv_folder + ":ch1_settings")
	left -= 135; top += 17*8
	titlebox ch1 title="Channel 1", pos={left, top}, frame=0, fSize=11, fstyle=1
	top += 17
	setvariable ch1_set_range, pos={left, top}, size={125,15}, bodywidth=70, title="range"
	setvariable ch1_set_range, value= ch1_path:ch1_range
	top += 17
	setvariable ch1_set_scale, pos={left, top}, size={125,15}, bodywidth=70, title="scale"
	setvariable ch1_set_scale, value= ch1_path:ch1_scale
	top += 17
	setvariable ch1_set_offset, pos={left, top}, size={125,15}, bodywidth=70, title="offset"
	setvariable ch1_set_offset, value= ch1_path:ch1_offset
	top += 17
	setvariable ch1_set_coupling, pos={left, top}, size={125,15}, bodywidth=70, title="coupling"
	setvariable ch1_set_coupling, value= ch1_path:ch1_coupling
	top += 17
	setvariable ch1_set_unit, pos={left, top}, size={125,15}, bodywidth=70, title="unit"
	setvariable ch1_set_unit, value= ch1_path:ch1_unit
	top += 17
	setvariable ch1_set_label, pos={left, top}, size={125,15}, bodywidth=70, title="label"
	setvariable ch1_set_label, value= ch1_path:ch1_label
	top += 17
	setvariable ch1_set_probe, pos={left, top}, size={125,15}, bodywidth=70, title="probe"
	setvariable ch1_set_probe, value= ch1_path:ch1_probe
	top += 17
	top -= 17*8
	
		// channel 2
	dfref ch2_path = $(gv_folder + ":ch2_settings")
	left += 135
	titlebox ch2 title="Channel 2", pos={left, top}, frame=0, fSize=11, fstyle=1
	top += 17
	setvariable ch2_set_range, pos={left, top}, size={125,15}, bodywidth=70, title="range"
	setvariable ch2_set_range, value= ch2_path:ch2_range
	top += 17
	setvariable ch2_set_scale, pos={left, top}, size={125,15}, bodywidth=70, title="scale"
	setvariable ch2_set_scale, value= ch2_path:ch2_scale
	top += 17
	setvariable ch2_set_offset, pos={left, top}, size={125,15}, bodywidth=70, title="offset"
	setvariable ch2_set_offset, value= ch2_path:ch2_offset
	top += 17
	setvariable ch2_set_coupling, pos={left, top}, size={125,15}, bodywidth=70, title="coupling"
	setvariable ch2_set_coupling, value= ch2_path:ch2_coupling
	top += 17
	setvariable ch2_set_unit, pos={left, top}, size={125,15}, bodywidth=70, title="unit"
	setvariable ch2_set_unit, value= ch2_path:ch2_unit
	top += 17
	setvariable ch2_set_label, pos={left, top}, size={125,15}, bodywidth=70, title="label"
	setvariable ch2_set_label, value= ch2_path:ch2_label
	top += 17
	setvariable ch2_set_probe, pos={left, top}, size={125,15}, bodywidth=70, title="probe"
	setvariable ch2_set_probe, value= ch2_path:ch2_probe
	top += 17
	top -= 17*8*2
	
	// display only values
	//left += 135
	//titlebox dso_display title="Display Parameters", pos={left, top}, frame=0, fSize=11, fstyle=1
	//top += 17
	//valdisplay dso_current_step, pos={left, top}, size={115,15}, bodyWidth=50, title="current step"
	//valdisplay dso_current_step, limits={0,0,0}, barmisc={0,1000}
	//valdisplay dso_current_step, value= #"gv_path:current_step"
	
	return cmplx(l_size, t_size)
end