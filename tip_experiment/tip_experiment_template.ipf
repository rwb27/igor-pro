#pragma rtGlobals=1		// Use modern global access method.

#include "tip_experiment"
#include "tip_alignment"
#include "tip_control_and_alignment"

function setup_tip_experiment()
	tip_control_and_alignment()
end