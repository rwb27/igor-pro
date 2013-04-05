#pragma modulename = tip_exp_log
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "data_handling"
#include "keithley_2635a_smu"
#include "agilent_dsox2000_series_dso"

static strconstant gv_folder = "root:global_variables:tip_experiment"

static function log_scan_parameters(scan_folder, i)
	dfref scan_folder
	variable i
	
 	string scan_folder_str
 	dfref initial_folder = getdatafolderdfr()
 	setdatafolder scan_folder
 	scan_folder_str = getdatafolder(1)
	setdatafolder initial_folder

	string param_folder = data#check_folder(scan_folder_str + "scan_parameters_" + num2str(i))
	string gv_path
	duplicatedatafolder $gv_folder, $(param_folder + ":experiment")
	gv_path = "root:global_variables:amplifiers"
	duplicatedatafolder $gv_path, $(param_folder + ":amplifiers")
	gv_path = smu#gv_path()
	duplicatedatafolder $gv_path, $(param_folder + ":smu")
	
	make/t/o/n=(0,2) $(scan_folder_str + "scan_parameters_" + num2str(i))
	wave/t params = $(scan_folder_str + "scan_parameters_" + num2str(i))
	append_to_params(params, $gv_folder)
	append_to_params(params, root:global_variables:amplifiers)
	append_to_params(params, $smu#gv_path())
	dfref dso = $dso#gv_path()
	append_to_params(params, dso)
	append_to_params(params, dso:timebase_settings)
	append_to_params(params, dso:ch1_settings)
	append_to_params(params, dso:ch2_settings)
	append_to_params(params, dso:trigger_settings)
end

static function append_to_params(params, param_folder)
	wave/t params
	dfref param_folder
	variable i = 0, j = 0
	// transfer variables in current folder to a text wave
	variable num_vars = countobjectsdfr(data_folder_path, 2)
	if (num_vars != 0)
		string vname
		for(i = j; i < j + num_vars; i += 1)
			// save variables to wave
			nvar/sdfr=param_folder v = $getindexedobjnamedfr(param_folder, 2, i)
			vname = getindexedobjnamedfr(param_folder, 2, i)
			redimension/n=(dimsize(params, 0)+1, 2) params
			params[i][0] = vname
			params[i][1] = num2str(v)
		endfor
	endif
	
	j = i
	// transfer strings in current folder to a text wave
	variable num_strs = countobjectsdfr(param_folder, 3)
	if (num_strs != 0)
		string sname
		for(i = 0; i < num_strs; i += 1)
			// save strings to wave
			svar/sdfr=param_folder s = $getindexedobjnamedfr(param_folder, 3, i)
			sname = getindexedobjnamedfr(param_folder, 3, i)
			redimension/n=(dimsize(params, 0)+1, 2) params
			params[i+j][0] = sname
			params[i+j][1] = s
		endfor
	endif
end

static function log_scan_parameters2(scan_folder)
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