#pragma rtGlobals=1		// Use modern global access method.

#include "tip_experiment"
#include "tip_alignment"
#include "tip_control_and_alignment"
#include "fianium v3.0_1"
#include "infinity v3.0"

menu "Tip Experiment"
	"Setup Tip Experiment", setup_tip_experiment()
	"Tip Control and Alignment", tip_control_and_alignment()
	"Tip Scanning", tip_scan_panel()
	"Fianium", fianium()
	"PIXIS", pixis#pixis_256e()
end

function setup_tip_experiment()
	tip_control_and_alignment()
	execute/q "fianium()"
end