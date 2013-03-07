#pragma modulename = tip_exp_log
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "data_handling"

static strconstant gv_folder = "root:global_variables:tip_experiments"

static function log_scan_parameters(scan_folder, i)
	dfref scan_folder
	variable i
	
 	string scan_folder_str
 	dfref initial_folder = getdatafolderdfr()
 	setdatafolder scan_folder
 	scan_folder_str = getdatafolder(1)
	setdatafolder initial_folder

	string param_folder = data#check_folder(scan_folder_str + ":scan_parameters_" + num2str(i))
	string gv_path
	duplicatedatafolder $gv_folder, $(param_folder + ":experiment")
	gv_path = "root:global_variables:amplifiers"
	duplicatedatafolder $gv_path, $(param_folder + ":amplifiers")
	gv_path = smu#gv_path()
	duplicatedatafolder $gv_path, $(param_folder + ":smu")
end

function log_scan_parameters2(scan_folder)
	string scan_folder
	string param_folder = data#check_folder(scan_folder + ":scan_parameters")
	string gv_path

	// load required parameters
	// experiment parameters
	nvar append_mode = $(gv_folder + ":append_mode")
	nvar scan_step = $(gv_folder + ":scan_step")
	nvar scan_size = $(gv_folder + ":scan_size")
	nvar scan_direction = $(gv_folder + ":scan_direction")
	nvar current_set_point = $(gv_folder + ":current_set_point")
	nvar trig_g0 = $(gv_folder + ":trig_g0")
	// amplifier parameters
	gv_path = "root:global_variables:amplifiers"
	nvar gain_dso = $(gv_path + ":gain_dso")
	nvar gain_force_x = $(gv_path + ":gain_force_x")
	nvar gain_force_y = $(gv_path + ":gain_force_y")
	nvar gain_force_dso = $(gv_path + ":gain_force_dso")
	nvar bandwidth_dso = $(gv_path + ":bandwidth_dso")
	nvar bandwidth_force_x = $(gv_path + ":bandwidth_force_x")
	nvar bandwidth_force_y = $(gv_path + ":bandwidth_force_y")
	nvar bandwidth_force_dso = $(gv_path + ":bandwidth_force_dso")
	
	// save parameters to parameter folder
	// experiment parameters
	variable/g $(param_folder + ":append_mode") = append_mode
	variable/g $(param_folder + ":scan_step") = scan_step
	variable/g $(param_folder + ":scan_size") = scan_size
	variable/g $(param_folder + ":scan_direction") = scan_direction
	variable/g $(param_folder + ":current_set_point") = current_set_point
	variable/g $(param_folder + ":trig_g0") = trig_g0
	// amplifier parameters
	variable/g $(param_folder + ":gain_dso") = gain_dso
	variable/g $(param_folder + ":gain_force_x") = gain_force_x
	variable/g $(param_folder + ":gain_force_y") = gain_force_y
	variable/g $(param_folder + ":gain_force_dso") = gain_force_dso
	variable/g $(param_folder + ":bandwidth_dso") = bandwidth_dso
	variable/g $(param_folder + ":bandwidth_force_x") = bandwidth_force_x
	variable/g $(param_folder + ":bandwidth_force_y") = bandwidth_force_y
	variable/g $(param_folder + ":bandwidth_force_dso") = bandwidth_force_dso
end