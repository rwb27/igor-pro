#pragma moduleName = grid_scan
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "pi_pi733_3cd_stage"

static strconstant gv_folder = "root:global_variables:pi_pi733_3cd_stage:grid_scanning"

static function/df gv_path()
	dfref df = $gv_folder
	return df
end

static function initialise()
	newdatafolder/o root:global_variables
	newdatafolder/o $pi_stage#gv_path()
	newdatafolder/o $gv_folder
	variable/g $(gv_folder + ":set_point_a")
	variable/g $(gv_folder + ":set_point_b")
	variable/g $(gv_folder + ":set_point_c")
end

function default_func(i,j)
	variable i,j
	print "valid function not given"
	return -1
end

function test_func(i,j)
	variable i, j
	nvar/sdfr=$pi_stage#gv_path() pos_a, pos_b, pos_c
	print i, j, pos_a, pos_b, pos_c
end

function scan_grid(axis1, axis2, scan_size, scan_step, scan_function)
	string axis1, axis2
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
	//nvar/sdfr=$pi_path pos_a0 = pos_a, pos_b0 = pos_b, pos_c0 = pos_c // load read piezo positions
	nvar/sdfr=$gv_folder set_point_i = $("set_point_"+axis1), set_point_j = $("set_point_"+axis2)
	variable init_i = set_point_i, init_j = set_point_j
	variable pos_i = init_i, pos_j = init_j
	
	// get starting positions
	pos_i = init_i - scan_size/2
	pos_j = init_j - scan_size/2
	//grid scan
	pi_stage#move(axis1, pos_i)
	pi_stage#move(axis2, pos_j)
	sleep/s 1
	
	variable imax = scan_size/scan_step, ib = 0, ic = 0
	do
		pi_stage#move(axis2, pos_j)
		do
			pi_stage#move(axis1, pos_i)
			scan_function(ib,ic)
			doupdate
			// increment B position //
			pos_i += scan_step
			ib += 1
		while (ib < imax)
		// move back to initial B position //
		pos_i = init_i - scan_size/2
		ib = 0
		// increment C position //
		pos_j += scan_step
		ic += 1
	while (ic < imax)

	pi_stage#move(axis1, init_i); pi_stage#move(axis2, init_j)
	sleep/s 0.5
	pi_stage#get_pos()
	pi_stage#close_comms()
end