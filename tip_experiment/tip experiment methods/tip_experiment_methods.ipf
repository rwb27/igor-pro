#pragma ModuleName = methods
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "pi_pi733_3cd_stage"
#include "data_handling"
static strconstant gv_folder = "root:global_variables:methods"

static function/s gv_path()
	return gv_folder
end

static function initialise()
	data#check_gvpath(gv_folder)
	variable/g $(gv_folder + ":hold_value")
end

function start_hold_position()
	pi_stage#stop()
	variable num_ticks = 30
	ctrlnamedbackground hold, period=num_ticks, proc=hold_position
	ctrlnamedbackground hold, start
end

function stop_hold_position()
	ctrlnamedbackground hold, stop
end

function hold_position(s)
	struct wmbackgroundstruct &s
	nvar scan_folder = $(":current_scan_folder")
	nvar current_value = $(":current"), hold_value = $(":current_set_point")
	variable step
	// linear method
	step = 0.001
	// exponential method
	// each 0.1 nm is 10 times conductance
	step = 0.001 * (current_value/hold_value)
	if (current_value < hold_value)
		pi_stage#move_rel("A", -step)			// apply more force
	elseif (current_value > hold_value)
		pi_stage#move_rel("A", step)			// apply less force
	endif
	return 0
end