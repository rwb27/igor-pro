#pragma moduleName = key_control
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "tip_experiment"

static function check_keys_tips()
	variable keys = getkeystate(0)
	if (keys == 0)					// nothing pressed
		return 0
	elseif (keys & 1)				// ctrl options - waiting for scan step changes
		dfref exp_path = tip_exp#gv_path()
		nvar/sdfr=exp_path scan_step
		do
			keys = getkeystate(0)	// stay in ctrl options while ctrl held
			if (keys & 2)			// ctrl + alt - increase scan step
				scan_step *= 2
				print "scan step =", scan_step
				sleep/s 0.2
			elseif (keys & 4)		// ctrl + shift - decrease scan step
				scan_step /= 2
				print "scan step =", scan_step
				sleep/s 0.2
			endif
		while (keys & 1)
		return 0
	elseif (keys & 2)				// alt - toggle set point
		dfref exp_path = tip_exp#gv_path()
		nvar/sdfr=exp_path set_point_reached
		set_point_reached = set_point_reached %^ 1
		print "set point reached =", set_point_reached
		sleep/s 0.2
		return 0
	elseif (keys & 4)				// shift - reverse scan direction
		dfref exp_path = tip_exp#gv_path()
		nvar/sdfr=exp_path scan_direction
		scan_direction *= -1
		tip_exp_setup#setup_triggering()
		print "scan direction =", scan_direction
		sleep/s 0.2
		return 0
	endif
end