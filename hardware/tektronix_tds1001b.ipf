#pragma ModuleName = tek
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "visa"
static strconstant hardware_id = "tektronix_tds1001b_dso"
static strconstant resourceName = ""
static strconstant gv_folder = "root:global_variables:tektronix_tds1001b_dso"
static strconstant data_folder = "root:tektronix_tds1001b_dso"

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
	nvar/z n = $(gv_folder + ":num_points")
	if (!nvar_exists(n))
		variable/g $(gv_folder + ":num_points") = 500
	endif
	visa#cmd(hardware_id, "dat:sou ch1\n")
	visa#cmd(hardware_id, "dat:star 1\n")
	visa#cmd(hardware_id, "dat:stop " + num2str(n) + "\n")
	visa#cmd(hardware_id, "dat:wid 2\n")
	visa#cmd(hardware_id, "dat:enc ribinary\n")
	visa#cmd(hardware_id, "dat:sou ch2\n")
	visa#cmd(hardware_id, "dat:star 1\n")
	visa#cmd(hardware_id, "dat:stop " + num2str(n) + "\n")
	visa#cmd(hardware_id, "dat:wid 2\n")
	visa#cmd(hardware_id, "dat:enc ribinary\n")
	visa#cmd(hardware_id, "head off\n")

	//get_timebase()
	//get_channel("1")
	//get_channel("2")
	//get_trigger()
end

static function reset()
	visa#cmd(hardware_id, "*rst")
end

static function waveform_params(ch)
	string ch
	visa#cmd(hardware_id, "dat:sou ch" + ch + "\n")
	variable y0 = visa#read(hardware_id, "wfmp:yze?\n")
	variable ym = visa#read(hardware_id, "wfmp:ymul?\n")
	variable yo = visa#read(hardware_id, "wfmp:yof?\n")
	variable x0 = visa#read(hardware_id, "wfmp:xze?\n")
	variable xinc = visa#read(hardware_id, "wfmp:xin?\n")
	variable/g $(gv_folder + ":y_zero_" + ch) = y0
	variable/g $(gv_folder + ":y_multi_" + ch) = ym
	variable/g $(gv_folder + ":y_off_" + ch) = yo
	variable/g $(gv_folder + ":x_zero") = x0
	variable/g $(gv_folder + ":x_inc") = xinc
end

static function import_data(ch, wname)
	string ch, wname
	visa#cmd(hardware_id, "*opc?\n")
	visa#cmd(hardware_id, "dat:sou ch" + ch + "\n")
	visa#cmd(hardware_id, "curve?\n")
	nvar instr = $("root:global_variables:" + hardware_id + ":instr")
	nvar/z n = $(gv_folder + ":num_points")
	if (!nvar_exists(n))
		variable/g $(gv_folder + ":num_points") = 500
	endif
	make/o/n=(n) $(data_folder + ":" + wname)
	wave w = $(data_folder + ":" + wname)
	VISAreadbinarywave/type=(0x10) instr, w
	
	variable y0 = visa#read(hardware_id, "wfmp:yze?\n")
	variable ym = visa#read(hardware_id, "wfmp:ymul?\n")
	variable yo = visa#read(hardware_id, "wfmp:yof?\n")
	variable x0 = visa#read(hardware_id, "wfmp:xze?\n")
	variable xinc = visa#read(hardware_id, "wfmp:xin?\n")
	variable/g $(gv_folder + ":y_zero_" + ch) = y0
	variable/g $(gv_folder + ":y_multi_" + ch) = ym
	variable/g $(gv_folder + ":y_off_" + ch) = yo
	variable/g $(gv_folder + ":x_zero") = x0
	variable/g $(gv_folder + ":x_inc") = xinc
	setscale/p x, x0, xinc, w

	return w
end

static function import_data_fast(ch, wname)
	string ch, wname
	visa#cmd(hardware_id, "*opc?\n")
	visa#cmd(hardware_id, "dat:sou ch" + ch + "\n")
	visa#cmd(hardware_id, "curve?\n")
	nvar instr = $("root:global_variables:" + hardware_id + ":instr")
	nvar/z n = $(gv_folder + ":num_points")
	if (!nvar_exists(n))
		variable/g $(gv_folder + ":num_points") = 500
	endif
	make/o/n=(n) $(data_folder + ":" + wname)
	wave w = $(data_folder + ":" + wname)
	VISAreadbinarywave/type=(0x10) instr, w
	
	nvar y0 = $(gv_folder + ":y_zero_" + ch)
	nvar ym = $(gv_folder + ":y_multi_" + ch)
	nvar yo = $(gv_folder + ":y_off_" + ch)
	nvar x0 = $(gv_folder + ":x_zero")
	nvar xinc = $(gv_folder + ":x_inc")
	setscale/p x, x0, xinc, w
	
	return w
end

static function set_offset(ch, offset)
	string ch
	variable offset
	visa#cmd(hardware_id, "ch" + ch + ":pos " + num2str(offset))
	variable/g $(gv_folder + ":ch" + ch + "_offset") = offset
end

static function auto_adjust_offset(ch)
	string ch
	import_data(ch, data_folder+":auto_adjust_temp")
	wave w = $(data_folder+":auto_adjust_temp")
	set_offset(ch, mean(w))
end

static function import_data_free(ch)									// import data fast with free waves
	string ch
	visa#cmd(hardware_id, "*opc?\n")
	visa#cmd(hardware_id, "dat:sou ch" + ch + "\n")
	visa#cmd(hardware_id, "curve?\n")
	nvar instr = $("root:global_variables:" + hardware_id + ":instr")
	nvar/z n = $(gv_folder + ":num_points")
	if (!nvar_exists(n))
		variable/g $(gv_folder + ":num_points") = 500
	endif
	make/free/n=(n) tek_tds1001b_wave
	VISAreadbinarywave/type=(0x10) instr, tek_tds1001b_wave
	nvar y0 = $(gv_folder + ":y_zero_" + ch)
	nvar ym = $(gv_folder + ":y_multi_" + ch)
	nvar yo = $(gv_folder + ":y_off_" + ch)
	nvar x0 = $(gv_folder + ":x_zero")
	nvar xinc = $(gv_folder + ":x_inc")
	setscale/p x, x0, xinc, tek_tds1001b_wave
	return tek_tds1001b_wave
end

static function wave_mean(ch)
	string ch
	wave w
	w = import_data_free(ch)
	return mean(w)
end

static function/c wave_stats(ch)
	string ch
	wave w
	w = import_data_free(ch)
	wavestats/q w
	variable/c stats = cmplx(V_avg, V_stdev)
	return stats
end