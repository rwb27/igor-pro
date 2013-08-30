#pragma ModuleName = tip_alignment
#pragma version = 6.32
#pragma rtGlobals=1		// Use modern global access method.

#include "pi_pi733_3cd_stage"
#include "hp33120a_sig_gen"
#include "grid_scanning"
#include "centroid_tracking"
#include "infinity v3.0"
#include <NIDAQmxWaveScanProcs>
#include "data_handling"
// sub-modules
#include "resonance_scan_lockin"
#include "centroid_fitting"
#include "tip_alignment_panel_lockin"

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
	grid_scan#initialise()
	dfref gs_folder = grid_scan#gv_path()
	variable/g gs_folder:set_point_b	, gs_folder:set_point_c
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

static function scan_function(i,j)
	variable i, j
	svar scan_folder = $(gv_folder + ":current_scan_folder")
	dfref sf = $scan_folder
	wave/sdfr=sf x = force_scan_x, y = force_scan_y
	wave/sdfr=sf scan_r = force_scan_r, theta = force_scan_theta
	wave/sdfr=sf current_x = current_scan_x, current_y = current_scan_y
	wave/sdfr=sf current_r = current_scan_r, current_theta = current_scan_theta
	variable/c data
	nvar/sdfr=lockin2#gv_path() time_constant
	sleep/s time_constant*3
	data = lockin2#measure_xy()
	x[i][j] = real(data)
	y[i][j] = imag(data)
	data = lockin2#measure_rtheta()
	scan_r[i][j] = real(data)
	theta[i][j] = imag(data)
	data = lockin#measure_xy()
	current_x[i][j] = real(data)
	current_y[i][j] = imag(data)
	data = lockin#measure_rtheta()
	current_r[i][j] = real(data)
	current_theta[i][j] = imag(data)
end

static function align_tips(scan_size, scan_step)
	variable scan_size, scan_step
	
	// SETUP	
	// load signal information
	string sig_gen_path = sig_gen#gv_path()
	nvar frequency = $(sig_gen_path + ":frequency")
	nvar amplified_voltage = $(gv_folder + ":amplified_voltage")
	nvar amplified_offset = $(gv_folder + ":amplified_offset")
	nvar/sdfr=$gv_folder set = alignment_set, electronic_alignment, force_alignment
	
	// store the current scan
	dfref sf = init_scan_folder()
	
	lockin#open_comms()
	lockin2#open_comms()
	
	// pi stuff
	pi_stage#open_comms()
	pi_stage#get_pos()
	pi_stage#close_comms()
	string pi_path = pi_stage#gv_path()
	nvar/sdfr=$pi_path pos_a0 = pos_a
	nvar/sdfr=$gv_folder set_point_b, set_point_c
	variable init_a = pos_a0, init_b = set_point_b, init_c = set_point_c
	
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
	position_x = init_b  - scan_size/2 + scan_step*x
	position_y = init_c  - scan_size/2 + scan_step*x

	make/o/n=(imax, imax) sf:force_scan_x, sf:force_scan_y
	make/o/n=(imax, imax) sf:force_scan_r, sf:force_scan_theta
	wave/sdfr=sf x = force_scan_x, y = force_scan_y
	wave/sdfr=sf scan_r = force_scan_r, theta = force_scan_theta
	setscale/p x, init_b  - scan_size/2, scan_step, x, y, scan_r, theta
	setscale/p y, init_c  - scan_size/2, scan_step, x, y, scan_r, theta
	setscale d, 0, 0, "°", theta
	
	make/o/n=(imax, imax) sf:current_scan_x, sf:current_scan_y
	make/o/n=(imax, imax) sf:current_scan_r, sf:current_scan_theta
	wave/sdfr=sf current_x = current_scan_x, current_y = current_scan_y
	wave/sdfr=sf current_r = current_scan_r, current_theta = current_scan_theta
	setscale/p x, init_b  - scan_size/2, scan_step, current_x, current_y, current_r, current_theta
	setscale/p y, init_c  - scan_size/2, scan_step, current_x, current_y, current_r, current_theta
	setscale d, 0, 0, "°", current_theta
	
	display_scan(sf)			// display scan
	
	// take alignment image
	Infinity_Image()
	duplicate/o root:infinity:infimg, sf:image
	
	variable time_constant
	if (electronic_alignment)
		lockin#purge()
		lockin#aphs()				// auto-phase lock-in amplifier
		time_constant = lockin#get_time_constant()
	endif
	if (force_alignment)
		lockin2#purge()
		lockin2#aphs()				// auto-phase lock-in amplifier
		time_constant = lockin2#get_time_constant()
	endif
	
	grid_scan#scan_grid("b", "c", scan_size, scan_step, scan_function)
	
	lockin#close_comms()
	lockin2#close_comms()

	// ANALYSIS
	// fit electronic scan
	centroid_fitting#fit_alignment_scan(sf, x)
	print centroid#get_centroids(x, position_x, position_y)
	centroid_fitting#fit_alignment_scan(sf, y)
	print centroid#get_centroids(y, position_x, position_y)
	centroid_fitting#fit_alignment_scan(sf, scan_r)
	print centroid#get_centroids(scan_r, position_x, position_y)
	centroid_fitting#fit_alignment_scan(sf, theta)
	print centroid#get_centroids(theta, position_x, position_y)
end

static function display_scan(sf)
	dfref sf
	wave/sdfr=sf x = force_scan_x, y = force_scan_y
	wave/sdfr=sf r = force_scan_r, theta = force_scan_theta
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

static function set_centroid(x0, y0)
	variable x0, y0
	svar/sdfr=$gv_folder current_scan_folder
	dfref df = $current_scan_folder
	variable/g df:x0 = x0
	variable/g df:y0 = y0
	dfref gvf = $data#check_gvpath(gv_folder)
	variable/g gvf:x0 = x0
	variable/g gvf:y0 = y0
	variable/g gvf:set_point_b = x0
	variable/g gvf:set_point_c = y0
	dfref gvf = grid_scan#gv_path()
	variable/g gvf:set_point_b = x0
	variable/g gvf:set_point_c = y0
	print "Tips centred at:", x0, y0
end

static function move_to_centre()
	nvar x0 = $(gv_folder + ":x0")
	nvar y0 = $(gv_folder + ":y0")
	pi_stage#open_comms()
	pi_stage#move("B", x0)
	pi_stage#move("C", y0)
	pi_stage#close_comms()
end