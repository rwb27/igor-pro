#pragma ModuleName = alignment
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "data_handling"
#include "pi_pi733_3cd_stage"
#include "hp33120a_sig_gen
#include "srs_sr830_lockin_amplifier"
#include "fit_functions"

static strconstant gv_folder = "root:global_variables:tip_alignment"

function align_tips(scan_size, scan_step)
	variable scan_size, scan_step
	
	// initialise piezo information
	string pi_path = pi_stage#gv_path()
	pi_stage#get_pos()					// 'b' is up/down, 'c' is focus
	nvar init_a = pi_path + ":pos_a"
	nvar init_b = pi_path + ":pos_b"
	nvar init_c = pi_path + ":pos_c"
	variable pos_b, pos_c
	variable ib, ic, imax = scan_size/scan_step
	variable/c data
	
	// store the current scan
	string scan_folder = data#create_data_folder()
	scan_folder = data#check_folder(scan_folder + ":alignment_scans")
	scan_folder = data#new_data_folder(scan_folder + ":scan_")
	
	// store scan parameters
	variable/g scan_folder + ":scan_size" = scan_size
	variable/g scan_folder + ":scan_step" = scan_step
	variable/g scan_folder + ":frequency"
	variable/g scan_folder + ":voltage"
	variable/g scan_folder + ":offset"
	variable/g scan_folder + ":init_pos_a" = init_a
	variable/g scan_folder + ":init_pos_b" = init_b
	variable/g scan_folder + ":init_pos_c" = init_c
	string/g scan_folder + ":time_stamp" = time() + " " + date()
	
	// make alignment data waves
	make/o/n=(imax, imax) $(scan_folder + ":alignment_scan_x")
	make/o/n=(imax, imax) $(scan_folder + ":alignment_scan_y")
	make/o/n=(imax, imax) $(scan_folder + ":alignment_scan_r")
	make/o/n=(imax, imax) $(scan_folder + ":alignment_scan_theta")
	make/o/n=(imax, imax) $(scan_folder + ":alignment_scan_y_psd")
	
end