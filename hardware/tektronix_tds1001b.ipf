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

function reset()
	visa#cmd(hardware_id, "*rst")
end

function import_data(ch, wname)
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
	return w
end