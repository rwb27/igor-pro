#pragma ModuleName = alignment_daq
#pragma version = 6.32
#pragma rtGlobals=1		// Use modern global access method.

#include "pi_pi733_3cd_stage"
#include "hp33120a_sig_gen"
#include "daq_methods"
#include "software_lockin"
#include "centroid_fitting"
#include "centroid_tracking"
#include "infinity v3.0"
#include <NIDAQmxWaveScanProcs>
#include "data_handling"

static strconstant gv_folder = "root:global_variables:tip_alignment"

static function/s gv_path()
	return gv_folder
end

static function initialise()
	newdatafolder/o root:global_variables
	newdatafolder/o $gv_folder
	variable/g $(gv_folder + ":scan_size")
	variable/g $(gv_folder + ":scan_step")
	variable/g $(gv_folder + ":freq_start")
	variable/g $(gv_folder + ":freq_stop")
	variable/g $(gv_folder + ":freq_inc")
	variable/g $(gv_folder + ":frequency")
	variable/g $(gv_folder + ":amplified_voltage")
	variable/g $(gv_folder + ":amplified_offset")
	variable/g $(gv_folder + ":alignment_set")
	variable/g $(gv_folder + ":set_point_b")
	variable/g $(gv_folder + ":set_point_c")
end

static function/df init_scan_folder()
	dfref df = $data#check_data_folder()
	newdatafolder/o df:alignment_scans
	df = df:alignment_scans
	setdatafolder df
	string sname = uniquename("scan_", 11, 1)
	setdatafolder root:
	newdatafolder/o df:$sname
	dfref scan_folder = df:$sname
	string/g $(gv_folder + ":current_scan_folder") = getdatafolder(1, scan_folder)
	return scan_folder
end

static function align_tips(scan_size, scan_step)
	variable scan_size, scan_step
	
	// SETUP
	// open comms
	pi_stage#open_comms()
	
	// load signal information
	string sig_gen_path = sig_gen#gv_path()
	nvar frequency = $(sig_gen_path + ":frequency")
	nvar amplified_voltage = $(gv_folder + ":amplified_voltage")
	nvar amplified_offset = $(gv_folder + ":amplified_offset")
	nvar/sdfr=$gv_folder set = alignment_set
	
	// turn dco off before you have recorded the initial position to keep things consistent with end set
	// DCO off for dynamic movement, DCO on for holding static
	pi_stage#set_dco_a(0)
	pi_stage#set_dco_b(0)
	pi_stage#set_dco_c(0)
	sleep/s 1
	
	// initialise piezo positions
	string pi_path = pi_stage#gv_path()
	pi_stage#get_pos()					// read dco on position	
	nvar/sdfr=$pi_path pos_a0 = pos_a, pos_b0 = pos_b, pos_c0 = pos_c // load read piezo positions
	nvar/sdfr=$gv_folder set_point_b, set_point_c
	variable init_a = pos_a0, init_b = set_point_b, init_c = set_point_c // set initial piezo position
	variable pos_a = init_a, pos_b = init_b, pos_c = init_c	// set variable to change as initial position
	
	print "\rTips initially at:", init_b, init_c, "(", pos_b0, pos_c0, ")"	// quote initial positions with dco on
	pi_stage#move("b", init_b); pi_stage#move("c", init_c)	// move stage to position with dco on
	sleep/s 1
	print "Starting scan at:", pos_b, pos_c, "(", pos_b0, pos_c0, ")"	// quote initial positions with dco on
	
	// get starting positions
	pos_b = init_b - scan_size/2
	pos_c = init_c - scan_size/2
	
	// store the current scan
	dfref sf = init_scan_folder()
	
	// store scan parameters
	variable/g sf:scan_size = scan_size
	variable/g sf:scan_step = scan_step
	variable/g sf:frequency = frequency
	variable/g sf:voltage = amplified_voltage
	variable/g sf:offset = amplified_offset
	variable/g sf:init_pos_a = init_a
	variable/g sf:init_pos_b = init_b
	variable/g sf:init_pos_c = init_c
	variable/g sf:alignment_set = set
	string/g sf:time_stamp = time() + " " + date()
	
	// make alignment data waves
	variable imax = scan_size/scan_step
	make/o/n=(imax) sf:position_x, sf:position_y
	wave/sdfr=sf position_x, position_y
	position_x = pos_b + scan_step*x
	position_y = pos_c + scan_step*x

	make/o/n=(imax, imax) sf:alignment_scan_x, sf:alignment_scan_y
	make/o/n=(imax, imax) sf:alignment_scan_r, sf:alignment_scan_theta
	wave/sdfr=sf x = alignment_scan_x, y = alignment_scan_y
	wave/sdfr=sf scan_r = alignment_scan_r, theta = alignment_scan_theta
	setscale/p x, pos_b, scan_step, x, y, scan_r, theta
	setscale/p y, pos_c, scan_step, x, y, scan_r, theta
	setscale d, 0, 0, "°", theta
	
	display_scan(sf)			// display scan
	
	// MEASUREMENTS
	variable ib = 0, ic = 0, inc=1
	variable/c data
	pi_stage#move("b", pos_b)
	pi_stage#move("c", pos_c)
	sleep/s 1
	
	// take alignment image
	Infinity_Image()
	duplicate/o root:infinity:infimg, sf:image
	
	daq#create_daq_waves(5, 50e3, 0.1)
	wave/sdfr=root: force_x = daq_0, force_y = daq_1, current = daq_3, ref = daq_4
	
	do
		//pi_stage#move("C", pos_c)
		//sleep/s 0.25
		do
			//pi_stage#move("B", pos_b)
			//sleep/s 0.25
			
			DAQmx_Scan/dev="dev1" WAVES="daq_1, 1/diff, -10, 10; daq_4, 4/diff, -1, 1;"			
			data = daq#lockin(force_y, ref, harmonic=2)
			x[ib][ic] = real(data)
			y[ib][ic] = imag(data)
			data = r2polar(data)
			scan_r[ib][ic] = real(data)
			theta[ib][ic] = imag(data)
				
			doupdate
			// increment B position //
			pos_b += scan_step
			ib += 1
			// move to new position //
			pi_stage#move("b", pos_b)
		while (ib < imax)
		// move back to initial B position //
		pos_b = init_b - scan_size/2
		pi_stage#move("b", pos_b)
		ib = 0
		
		// increment C position //
		pos_c += scan_step
		ic += 1
		// move to new position //
		pi_stage#move("c", pos_c)
		//sleep/s 0.5
	while (ic < imax)

	// move to initial positions with the dco in the same confiuration as the experiment was taken
	pi_stage#move("b", init_b); pi_stage#move("c", init_c)		// move back to initial position with dco on
	sleep/s 1
	pi_stage#get_pos()
	print "Ending scan at:", init_b, init_c, "(", pos_b0, pos_c0, ")"
	
	// close comms
	pi_stage#close_comms()

	// ANALYSIS
	// fit electronic scan
	fit_alignment_scan(sf, x)
	print get_centroids(x, position_x, position_y)
	fit_alignment_scan(sf, y)
	print get_centroids(y, position_x, position_y)
	fit_alignment_scan(sf, scan_r)
	print get_centroids(scan_r, position_x, position_y)
	fit_alignment_scan(sf, theta)
	print get_centroids(theta, position_x, position_y)
	saveexperiment
end

static function display_scan(sf)
	dfref sf
	wave/sdfr=sf x = alignment_scan_x, y = alignment_scan_y
	wave/sdfr=sf r = alignment_scan_r, theta = alignment_scan_theta
	dowindow/k tip_alignment
	display/n=tip_alignment/k=1
	appendimage/l=lx x
	appendimage/l=ly y
	appendimage/l=lr r
	appendimage/l=ltheta theta
	modifyimage ''#0 ctab={*,*,geo,0}
	modifyimage ''#1 ctab={*,*,geo,0}
	modifyimage ''#2 ctab={*,*,geo,0}
	modifyimage ''#3 ctab={*,*,geo,0}
	modifygraph width=80
	modifygraph height=4*80
	modifygraph axisEnab(lx)={0.75,1.0}, axisEnab(ly)={0.5,0.74}, axisEnab(lr)={0.25,0.49}, axisEnab(ltheta)={0.0,0.24}
	modifygraph lblposmode=4, lblpos=40, lblpos(bottom)=30, freepos=0
	label lr "tip focus (\\F'Symbol'm\\F'Arial'm)"
	label bottom "tip height (\\F'Symbol'm\\F'Arial'm)"
	modifygraph tick=0, minor=1, btLen=4, stLen=2
	modifygraph mirror=1, fSize=10, standoff=0, axOffset=-1, axOffset(bottom)=0
end

static function move_to_centre()
	nvar x0 = $(gv_folder + ":x0")
	nvar y0 = $(gv_folder + ":y0")
	pi_stage#open_comms()
	pi_stage#move("B", x0)
	pi_stage#move("C", y0)
	pi_stage#close_comms()
end