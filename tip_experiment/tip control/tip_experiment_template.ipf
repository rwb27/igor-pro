#pragma rtGlobals=3		// Use modern global access method.

// tip control procedures and panels
#include "tip_alignment"
#include "tip_control_and_alignment"
// regularly used procedures
#include "fianium v3.0_1"
#include "infinity v3.0"
// tip experiment
#include "tip_experiment"

menu "Tip Experiment"
	"Tip Control and Alignment", tip_control_and_alignment()
	"Tip Scanning", tip_scan_panel()
	"Fianium", fianium()
	"PIXIS", pixis#pixis_256e()
end