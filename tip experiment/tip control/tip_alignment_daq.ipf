#pragma ModuleName = alignment_daq
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "data_handling"
#include "pi_pi733_3cd_stage"
#include "hp33120a_sig_gen"
#include "srs_sr830_lockin_amplifier"
#include "srs_sr830_lockin_amplifier_2"
#include "software_lockin"
#include "centroid_fitting"
#include "infinity v3.0"
#include <NIDAQmxWaveScanProcs>

static strconstant gv_folder = "root:global_variables:tip_alignment"

static function/s gv_path()
	return gv_folder
end

static function initialise()
	data#check_gvpath(gv_folder)
	variable/g $(gv_folder + ":scan_size")
	variable/g $(gv_folder + ":scan_step")
	variable/g $(gv_folder + ":freq_start")
	variable/g $(gv_folder + ":freq_stop")
	variable/g $(gv_folder + ":freq_inc")
	variable/g $(gv_folder + ":frequency")
	variable/g $(gv_folder + ":amplified_voltage")
	variable/g $(gv_folder + ":amplified_offset")
	variable/g $(gv_folder + ":alignment_set")
	variable/g $(gv_folder + ":electronic_alignment")
	variable/g $(gv_folder + ":force_alignment")
	variable/g $(gv_folder + ":set_point_a")
	variable/g $(gv_folder + ":set_point_b")
	variable/g $(gv_folder + ":set_point_c")
end

static function align_tips(scan_size, scan_step)
	variable scan_size, scan_step
	
	// SETUP
	// open comms
	pi_stage#open_comms()
	lockin#open_comms(); lockin2#open_comms()
	
	// load signal information
	string sig_gen_path = sig_gen#gv_path()
	nvar frequency = $(sig_gen_path + ":frequency")
	nvar amplified_voltage = $(gv_folder + ":amplified_voltage")
	nvar amplified_offset = $(gv_folder + ":amplified_offset")
	nvar/sdfr=$gv_folder set = alignment_set
	nvar/sdfr=$gv_folder electronic_alignment
	nvar/sdfr=$gv_folder force_alignment
	
	// turn dco off before you have recorded the initial position to keep things consistent with end set
	// DCO off for dynamic movement, DCO on for holding static
	pi_stage#set_dco_a(0)			// should be on since holding static but tests indicate it may be better off
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
	string scan_folder = data#check_data_folder()
	scan_folder = data#check_folder(scan_folder + ":alignment_scans")
	scan_folder = data#new_data_folder(scan_folder + ":scan_")
	string/g $(gv_folder + ":current_scan_folder") = scan_folder
	dfref sf = $scan_folder
	
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
	variable/g sf:electronic_alignment = electronic_alignment
	variable/g sf:force_alignment = force_alignment
	string/g sf:time_stamp = time() + " " + date()
	
	// make alignment data waves
	variable imax = scan_size/scan_step
	make/o/n=(imax) sf:position_x, sf:position_y
	wave/sdfr=sf position_x, position_y
	position_x = pos_b + scan_step*x
	position_y = pos_c + scan_step*x
	
	// lock-in 1
	make/o/n=(imax, imax) sf:alignment_scan_x, sf:alignment_scan_y
	make/o/n=(imax, imax) sf:alignment_scan_r, sf:alignment_scan_theta
	wave/sdfr=sf x = alignment_scan_x, y = alignment_scan_y
	wave/sdfr=sf scan_r = alignment_scan_r, theta = alignment_scan_theta
	setscale/p x, pos_b, scan_step, x, y, scan_r, theta
	setscale/p y, pos_c, scan_step, x, y, scan_r, theta
	setscale d, 0, 0, "°", theta
	
	// lock-in 2
	if (force_alignment)
		make/o/n=(imax, imax) sf:alignment_scan_fx, sf:alignment_scan_fy
		make/o/n=(imax, imax) sf:alignment_scan_fr, sf:alignment_scan_ftheta
		wave/sdfr=sf fx = alignment_scan_fx, fy = alignment_scan_fy
		wave/sdfr=sf fr = alignment_scan_fr, ftheta = alignment_scan_ftheta
		setscale/p x, pos_b, scan_step, fx, fy, fr, ftheta
		setscale/p y, pos_c, scan_step, fx, fy, fr, ftheta
		setscale d, 0, 0, "°", ftheta 
	endif
	
	display_scan(scan_folder)			// display scan
	
	variable time_constant
	if (force_alignment)
		lockin2#purge()
		lockin2#aphs()				// auto-phase lock-in amplifier
		time_constant = lockin2#get_time_constant()
	endif
	
	// MEASUREMENTS
	variable ib = 0, ic = 0, inc=1
	variable/c data
	pi_stage#move("b", pos_b)
	pi_stage#move("c", pos_c)
	sleep/s 1
	
	// take alignment image
	Infinity_Image()
	duplicate/o root:infinity:infimg, sf:image
	
	variable dt = 1.0/100e3, sample_points = 0.1 * (1.0/dt)	// 100 kHz for 0.1 s
	make/o/n=(sample_points) root:force_y, root:ref
	wave force_y, ref
	setscale/p x, 0, dt, "s", force_y, ref
	
	do
		//pi_stage#move("C", pos_c)
		//sleep/s 0.25
		do
			//pi_stage#move("B", pos_b)
			//sleep/s 0.25
			
			DAQmx_Scan/dev="dev1"/bkg WAVES="force_y, 1/diff, -10, 10; ref, 4/diff, -1, 1;"
			sleep/s time_constant*3
			// force lock-in measurements //
			if (force_alignment)
				data = lockin2#measure_xy()
				fx[ib][ic] = real(data)
				fy[ib][ic] = imag(data) 
				data = lockin2#measure_rtheta()
				fr[ib][ic] = real(data)
				ftheta[ib][ic] = imag(data)
			endif
			
			fDAQmx_ScanWait("dev1")
			data = soft_lock#measure(force_y, ref, harmonic=2)
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
	if (force_alignment)
		lockin2#close_comms()
	endif

	// ANALYSIS
	// fit electronic scan
	fit_alignment_data(sf, x)
	fit_alignment_data(sf, y)
	fit_alignment_data(sf, scan_r)
	fit_alignment_data(sf, theta)
	
	// fit force scan
	if (force_alignment)
		fit_alignment_data(sf, fx)
		fit_alignment_data(sf, fy)
		fit_alignment_data(sf, fr)
		fit_alignment_data(sf, ftheta)
	endif
	saveexperiment
end

static function display_scan(scan_folder)
	string scan_folder
	nvar/sdfr=$gv_folder electronic_alignment
	nvar/sdfr=$gv_folder force_alignment
	
	if (electronic_alignment)
		wave x = $(scan_folder + ":alignment_scan_x")
		wave y = $(scan_folder + ":alignment_scan_y")
		wave r = $(scan_folder + ":alignment_scan_r")
		wave theta = $(scan_folder + ":alignment_scan_theta")
		//wave y_psd = $(scan_folder + ":alignment_scan_y_psd")
	endif
	if (force_alignment)
		wave fx = $(scan_folder + ":alignment_scan_fx")
		wave fy = $(scan_folder + ":alignment_scan_fy")
		wave fr = $(scan_folder + ":alignment_scan_fr")
		wave ftheta = $(scan_folder + ":alignment_scan_ftheta")
	endif
	
	// force alignment
	wave fx = $(scan_folder + ":alignment_scan_fx")
	wave fy = $(scan_folder + ":alignment_scan_fy")
	wave fr = $(scan_folder + ":alignment_scan_fr")
	wave ftheta = $(scan_folder + ":alignment_scan_ftheta")
	
	dowindow/k tip_alignment
	display/n=tip_alignment/k=1
	
	//textbox/c/n=textx/f=0/a=LT/x=10/y=3 "\\f02x"
	//textbox/c/n=texty/f=0/a=LT/x=10/y=22 "\\f02y"
	//textbox/c/n=textr/f=0/a=LT/x=10/y=40 "\\f02r"
	//textbox/c/n=texttheta/f=0/a=LT/x=10/y=58 "\\f02\\F'Symbol'q"
	//textbox/c/n=textypsd/f=0/a=LT/x=1/y=75 "\\f02psd_y"
	
	if (electronic_alignment)
		appendimage/l=lx x
		appendimage/l=ly y
		appendimage/l=lr r
		appendimage/l=ltheta theta
		//appendimage y_psd
		modifyimage ''#0 ctab={*,*,geo,0}
		modifyimage ''#1 ctab={*,*,geo,0}
		modifyimage ''#2 ctab={*,*,geo,0}
		modifyimage ''#3 ctab={*,*,geo,0}
		//modifyimage ''#4 ctab={*,*,geo,0}
		modifygraph width=80
		modifygraph height=4*80
	endif
	
	// force alignment scans
	if (force_alignment)
		appendimage/l=lx/b=b1 fx
		appendimage/l=ly/b=b1 fy
		appendimage/l=lr/b=b1 fr
		appendimage/l=ltheta/b=b1 ftheta
		modifyimage ''#4 ctab={*,*,geo,0}
		modifyimage ''#5 ctab={*,*,geo,0}
		modifyimage ''#6 ctab={*,*,geo,0}
		modifyimage ''#7 ctab={*,*,geo,0}
		modifygraph width=2*80
		modifygraph axisEnab(bottom)={0,0.49}, freePos(bottom)=0
		modifygraph axisEnab(b1)={0.51,1.0}, freePos(b1)=0
	endif
	
	modifygraph axisEnab(lx)={0.75,1.0}, freePos(lx)=0
	modifygraph axisEnab(ly)={0.5,0.74}, freePos(ly)=0
	modifygraph axisEnab(lr)={0.25,0.49}, freePos(lr)=0
	modifygraph axisEnab(ltheta)={0.0,0.24}, freePos(ltheta)=0
	//modifygraph axisEnab(left)={0,0.19}, freePos(left)=0
	
	modifygraph lblposmode=4, lblpos=40
	modifygraph lblpos(bottom)=30
	
	label lr "tip focus (\\F'Symbol'm\\F'Arial'm)"
	label bottom "tip height (\\F'Symbol'm\\F'Arial'm)"
	modifygraph tick=0, minor=1, btLen=4, stLen=2
	modifygraph mirror=1, fSize=10, standoff=0, axOffset=-1, axOffset(bottom)=0
end

static function move_to_centre()
	nvar x0 = $(gv_folder + ":x0")
	nvar y0 = $(gv_folder + ":y0")
	pi_stage#move("B", x0)
	pi_stage#move("C", y0)
end