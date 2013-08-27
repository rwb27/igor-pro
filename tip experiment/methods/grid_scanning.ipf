#pragma moduleName = grid_scan
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "pi_pi733_3cd_stage"

static strconstant gv_folder = "root:global_variables:pi_pi733_3cd_stage:grid_scanning"

static function/df gv_path()
	return $gv_folder
end

static function initialise()
	newdatafolder/o root:global_variables
	dfref pi_path = $(pi_stage#gv_path())
	newdatafolder/o pi_path
	newdatafolder/o $gv_folder
	variable/g $(gv_folder + ":set_point_b")
	variable/g $(gv_folder + ":set_point_c")
end

function default_func(i,j)
	variable i,j
	print "valid function not given"
	return -1
end

function scan_grid(scan_size, scan_step, scan_function)
	variable scan_size, scan_step
	funcref default_func scan_function
	
	pi_stage#open_comms()
	pi_stage#set_dco_a(0)
	pi_stage#set_dco_b(0)
	pi_stage#set_dco_c(0)
	sleep/s 0.5
	
	// initialise piezo positions
	string pi_path = pi_stage#gv_path()
	pi_stage#get_pos()					// read dco on position	
	nvar/sdfr=$pi_path pos_a0 = pos_a, pos_b0 = pos_b, pos_c0 = pos_c // load read piezo positions
	nvar/sdfr=$gv_folder set_point_b, set_point_c
	variable init_a = pos_a0, init_b = set_point_b, init_c = set_point_c // set initial piezo position
	variable pos_a = init_a, pos_b = init_b, pos_c = init_c	// set variable to change as initial position
	
	// get starting positions
	pos_b = init_b - scan_size/2
	pos_c = init_c - scan_size/2
	//grid scan
	pi_stage#move("b", pos_b)
	pi_stage#move("c", pos_c)
	sleep/s 1
	
	variable imax = scan_size/scan_step, ib = 0, ic = 0
	do
		pi_stage#move("C", pos_c)
		do
			pi_stage#move("B", pos_b)
			scan_function(ib,ic)
			doupdate
			// increment B position //
			pos_b += scan_step
			ib += 1
		while (ib < imax)
		// move back to initial B position //
		pos_b = init_b - scan_size/2
		ib = 0
		// increment C position //
		pos_c += scan_step
		ic += 1
	while (ic < imax)

	pi_stage#move("b", init_b); pi_stage#move("c", init_c)
	sleep/s 0.5
	pi_stage#get_pos()
	pi_stage#close_comms()
end