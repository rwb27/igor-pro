#pragma ModuleName = alignment
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "data_handling"
#include "pi_pi733_3cd_stage"
#include "hp33120a_sig_gen"
#include "srs_sr830_lockin_amplifier"
#include "srs_sr830_lockin_amplifier_2"
#include "tektronix_tds1001b"
#include "fit_functions"

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

function align_tips(scan_size, scan_step)
	variable scan_size, scan_step
	
	// SETUP
	// open comms
	pi_stage#open_comms()
	lockin#open_comms(); lockin2#open_comms()
	tek#open_comms(); tek#initialise()
	sig_gen#open_comms()
	
	// load signal information
	string sig_gen_path = sig_gen#gv_path()
	nvar frequency = $(sig_gen_path + ":frequency")
	nvar amplified_voltage = $(gv_folder + ":amplified_voltage")
	nvar amplified_offset = $(gv_folder + ":amplified_offset")
	nvar/sdfr=$gv_folder set = alignment_set
	nvar/sdfr=$gv_folder electronic_alignment
	nvar/sdfr=$gv_folder force_alignment
	variable gain = 1e8				// 100 MV/A transimpedance amplifier
	
	// turn dco off before you have recorded the initial position to keep things consistent with end set
	// DCO off for dynamic movement, DCO on for holding static
	pi_stage#set_dco_a(1)			// should be on since holding static but tests indicate it may be better off
	pi_stage#set_dco_b(0)
	pi_stage#set_dco_c(0)
	sleep/s 1
	
	// initialise piezo positions
	string pi_path = pi_stage#gv_path()
	pi_stage#get_pos()					// read dco on position	
	nvar/sdfr=$pi_path pos_a0 = pos_a		// load read piezo positions
	nvar/sdfr=$pi_path pos_b0 = pos_b
	nvar/sdfr=$pi_path pos_c0 = pos_c
	nvar/sdfr=$gv_folder set_point_a, set_point_b, set_point_c
	variable init_a = set_point_a //pos_a0 //pi_stage#get_pos_ch("a")	// set initial piezo position
	variable init_b = set_point_b //pos_b0 //pi_stage#get_pos_ch("b")
	variable init_c =set_point_c //pos_c0 //pi_stage#get_pos_ch("c")
	variable pos_a = init_a, pos_b = init_b, pos_c = init_c	// set variable to change as initial position
	
	print "\rTips initially at:", init_b, init_c, "(", pos_b0, pos_c0, ")"	// quote initial positions with dco on
	pi_stage#move("b", init_b); pi_stage#move("c", init_c)	// move stage to position with dco on
	sleep/s 1
	print "Starting scan at:", pos_b, pos_c, "(", pos_b0, pos_c0, ")"	// quote initial positions with dco on
	
	// get starting positions
	pos_b = init_b - scan_size/2
	pos_c = init_c - scan_size/2
	
	// initialise dso parameters
	dfref tek_path = $tek#gv_path()
	variable/g tek_path:num_points = 2500
	
	// store the current scan
	string scan_folder = data#check_data_folder()
	scan_folder = data#check_folder(scan_folder + ":alignment_scans")
	scan_folder = data#new_data_folder(scan_folder + ":scan_")
	string/g $(gv_folder + ":current_scan_folder") = scan_folder
	
	// store scan parameters
	variable/g $(scan_folder + ":scan_size") = scan_size
	variable/g $(scan_folder + ":scan_step") = scan_step
	variable/g $(scan_folder + ":frequency") = frequency
	variable/g $(scan_folder + ":voltage") = amplified_voltage
	variable/g $(scan_folder + ":offset") = amplified_offset
	variable/g $(scan_folder + ":init_pos_a") = init_a
	variable/g $(scan_folder + ":init_pos_b") = init_b
	variable/g $(scan_folder + ":init_pos_c") = init_c
	variable/g $(scan_folder + ":alignment_set") = set
	variable/g $(scan_folder + ":electronic_alignment") = electronic_alignment
	variable/g $(scan_folder + ":force_alignment") = force_alignment
	string/g $(scan_folder + ":time_stamp") = time() + " " + date()
	
	// make alignment data waves
	variable imax = scan_size/scan_step
	
	// lock-in 1
	if (electronic_alignment)
		make/o/n=(imax, imax) $(scan_folder + ":alignment_scan_x")
		make/o/n=(imax, imax) $(scan_folder + ":alignment_scan_y")
		make/o/n=(imax, imax) $(scan_folder + ":alignment_scan_r")
		make/o/n=(imax, imax) $(scan_folder + ":alignment_scan_theta")
		wave/sdfr=$scan_folder x = alignment_scan_x
		wave/sdfr=$scan_folder y = alignment_scan_y
		wave/sdfr=$scan_folder scan_r = alignment_scan_r
		wave/sdfr=$scan_folder theta = alignment_scan_theta
		setscale/p x, pos_b, scan_step, x, y, scan_r, theta
		setscale/p y, pos_c, scan_step, x, y, scan_r, theta
		setscale d, 0, 0, "\\degree", theta
	endif
	
	nvar/sdfr=$tek#gv_path() num_points
	make/o/n=(imax, imax, num_points) $(scan_folder + ":alignment_trace_y_psd")
	make/o/n=(imax, imax) $(scan_folder + ":alignment_scan_y_psd")
	wave y_psd = $(scan_folder + ":alignment_scan_y_psd")
	wave y_psd_trace = $(scan_folder + ":alignment_trace_y_psd")
	setscale/p x, pos_b, scan_step, y_psd, y_psd_trace
	setscale/p y, pos_c, scan_step, y_psd, y_psd_trace
	
	// lock-in 2
	if (force_alignment)
		make/o/n=(imax, imax) $(scan_folder + ":alignment_scan_fx")
		make/o/n=(imax, imax) $(scan_folder + ":alignment_scan_fy")
		make/o/n=(imax, imax) $(scan_folder + ":alignment_scan_fr")
		make/o/n=(imax, imax) $(scan_folder + ":alignment_scan_ftheta")
		wave/sdfr=$scan_folder fx = alignment_scan_fx
		wave/sdfr=$scan_folder fy = alignment_scan_fy
		wave/sdfr=$scan_folder fr = alignment_scan_fr
		wave/sdfr=$scan_folder ftheta = alignment_scan_ftheta
		setscale/p x, pos_b, scan_step, fx, fy, fr, ftheta
		setscale/p y, pos_c, scan_step, fx, fy, fr, ftheta
		setscale d, 0, 0, "\\degree", ftheta 
	endif
	
	display_scan(scan_folder)			// display scan
	
	tek#get_waveform_params("2")			// get oscilloscope waveform scaling parameters
	if (electronic_alignment)
		lockin#aphs()				// auto-phase lock-in amplifier
	endif
	if (force_alignment)
		lockin2#aphs()				// auto-phase lock-in amplifier
	endif
	sleep/s 1					// wait for auto-phase to complete
	
	// MEASUREMENTS
	variable ib = 0, ic = 0
	variable/c data
	pi_stage#move("b", pos_b)
	pi_stage#move("c", pos_c)
	sleep/s 2
	do
		//pi_stage#move("C", pos_c)
		//sleep/s 0.25
		do
			//pi_stage#move("B", pos_b)
			//sleep/s 0.25
			// electronic lock-in measurements //
			if (electronic_alignment)
				data = lockin#measure_xy()
				x[ib][ic] = real(data)
				y[ib][ic] = imag(data) 
				data = lockin#measure_rtheta()
				scan_r[ib][ic] = real(data)/gain
				theta[ib][ic] = imag(data)
			endif
			// force lock-in measurements //
			if (force_alignment)
				data = lockin2#measure_xy()
				fx[ib][ic] = real(data)
				fy[ib][ic] = imag(data) 
				data = lockin2#measure_rtheta()
				fr[ib][ic] = real(data)/gain
				ftheta[ib][ic] = imag(data)
			endif
			// oscilloscope force measurement //
			wave w = tek#import_data_free("2")
			y_psd_trace[ib][ic][] = w[r]
			y_psd[ib][ic] = wavemax(w) - wavemin(w)
			
			doupdate
			// increment B position //
			pos_b += scan_step
			ib += 1
			// move to new position //
			pi_stage#move("b", pos_b)
			//sleep/s 0.5
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
	
	//pi_stage#move("b", init_b); pi_stage#move("c", init_c)		// move back to initial position with dco off
	//print "scan ending at", init_b, init_c, "(", pos_b0, pos_c0, ")"
	
	// dco possibly causes some deviation from the correct alignment position
	//pi_stage#set_dco(1)	// set dco on
	//sleep/s 2
	//pi_stage#get_pos()
	//print "(dco=0) ending at", init_b, init_c, "(", pos_b0, pos_c0, ")"
	pi_stage#move("b", init_b); pi_stage#move("c", init_c)		// move back to initial position with dco on
	sleep/s 1
	pi_stage#get_pos()
	print "Ending scan at:", init_b, init_c, "(", pos_b0, pos_c0, ")"
	
	// close comms
	pi_stage#close_comms()
	tek#close_comms()
	if (electronic_alignment)
		lockin#close_comms()
	endif
	if (force_alignment)
		lockin2#close_comms()
	endif
	sig_gen#close_comms()

	// ANALYSIS
	// fit electronic scan
	if (electronic_alignment)
		fit_alignment_data($scan_folder, x)
		fit_alignment_data($scan_folder, y)
		fit_alignment_data($scan_folder, scan_r)
		fit_alignment_data($scan_folder, theta)
		fit_alignment_data($scan_folder, y_psd)
	endif
	
	// fit force scan
	if (force_alignment)
		fit_alignment_data($scan_folder, fx)
		fit_alignment_data($scan_folder, fy)
		fit_alignment_data($scan_folder, fr)
		fit_alignment_data($scan_folder, ftheta)
	endif
end

function fit_alignment_data(scan_folder, data)
	dfref scan_folder
	wave data
	
	dowindow/f tip_alignment
	setdatafolder scan_folder
	
	variable z0, a0, x0, sigx, y0, sigy, corr
	imagestats data
	
	variable ix = dimsize(data, 0)-1, iy = dimsize(data, 1)-1
	z0 = 0.25 * (data[0][0] + data[ix][0] + data[0][iy] + data[ix][iy])		// background
	a0 = data[ix/2][iy/2] - z0										// amplitude
	x0 = dimoffset(data, 0) + ix/2 * dimdelta(data, 0)					// x centre
	sigx = 0.25													// x width
	y0 = dimoffset(data, 1) + iy/2 * dimdelta(data, 1)					// y centre
	sigy = 0.25													// y width
	corr = 0														// correlation
	
	// constraints on fit
	// note: {K0,K1,K2,K3,K4,K5,K6} = {z0, a0, x0, sigx, y0, sigy, corr}
	make/o/t/n=0 scan_folder:t_constraints
	wave/t/sdfr=scan_folder t_constraints
	variable q = 0		// Constraint counter
	
	// Constraint -- x0 and y0 must lie within the scan area
	redimension/n=(q+2) t_constraints
	t_constraints[q] = "K2 > " + num2str(dimOffset(data,0)) ; q = q+1
	t_constraints[q] = "K2 < " + num2str(dimOffset(data,0)+dimsize(data,0)*dimDelta(data,0)); q = q+1
	redimension/n=(q+2) t_constraints
	t_constraints[q] = "K4 > " + num2str(dimOffset(data,1)); q = q+1
	t_constraints[q] = "K4 < " + num2str(dimOffset(data,1)+dimsize(data,1)*dimDelta(data,1)); q = q+1
	
	// Constraint -- sigx and sigy must be between 50nm and 1um
	redimension/n=(q+2) t_constraints
	t_constraints[q] = "K3 > 0.05"; q = q+1
	t_constraints[q] = "K3 < 1"; q = q+1
	redimension/n=(q+2) t_constraints
	t_constraints[q] = "K5 > 0.05"; q = q+1
	t_constraints[q] = "K5 < 1"; q = q+1
	
	// Constraint -- corr must be between -1 and 1
	redimension/n=(q+2) t_constraints
	t_constraints[q] = "K6 > -1"; q = q+1
	t_constraints[q] = "K6 < 1"; q = q+1
	
	make/d/n=7/o scan_folder:w_coef
	wave/sdfr=scan_folder w_coef
	w_coef[0] = {z0, a0, x0, sigx, y0, sigy, corr}
	funcfitmd/nthr=0/q gauss2d_elliptic w_coef  data /d/c=t_constraints
	//curvefit/x=1/nthr=0/q gauss2d, kwcwave=w_coef, data /d/c=t_constraints
	modifycontour/w=tip_alignment $("fit_" + nameofwave(data)) labels=0//, ctabLines={*,*,Geo,0}
	wave w_sigma
	setdatafolder root:
	
	string expr = "(.*)_(.*)", wave_id, rest_of_wavename
	splitstring/e=(expr) nameofwave(data), rest_of_wavename, wave_id
	duplicate/o w_coef, scan_folder:$(wave_id + "_w_coef")
	variable/g scan_folder:$(wave_id + "_x0") = w_coef[2]
	variable/g scan_folder:$(wave_id + "_y0") = w_coef[4]
	
	//variable/g scan_folder:x0 = w_coef[2]
	//variable/g scan_folder:y0 = w_coef[4]
	
	//data#check_gvpath(gv_folder)
	//variable/g $(gv_folder):x0 = w_coef[2]
	//variable/g $(gv_folder):y0 = w_coef[4]
end

function gauss2d_elliptic(w, x, y) : fitfunc
	wave w
	variable x, y
	return w[0]+w[1]*exp(-1/2/(1-w[6]^2)*((x-w[2])^2/w[3]^2+(y-w[4])^2/w[5]^2)-2*w[6]*(x-w[2])*(y-w[4])/w[3]/w[5])
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
		wave y_psd = $(scan_folder + ":alignment_scan_y_psd")
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
	display/n=tip_alignment
	
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
		appendimage y_psd
		modifyimage ''#0 ctab={*,*,geo,0}
		modifyimage ''#1 ctab={*,*,geo,0}
		modifyimage ''#2 ctab={*,*,geo,0}
		modifyimage ''#3 ctab={*,*,geo,0}
		modifyimage ''#4 ctab={*,*,geo,0}
		modifygraph width=80
		modifygraph height=5*80
	endif
	
	// force alignment scans
	if (force_alignment)
		appendimage/l=lx/b=b1 fx
		appendimage/l=ly/b=b1 fy
		appendimage/l=lr/b=b1 fr
		appendimage/l=ltheta/b=b1 ftheta
		modifyimage ''#5 ctab={*,*,geo,0}
		modifyimage ''#6 ctab={*,*,geo,0}
		modifyimage ''#7 ctab={*,*,geo,0}
		modifyimage ''#8 ctab={*,*,geo,0}
		modifygraph width=2*80
		modifygraph axisEnab(bottom)={0,0.49}, freePos(bottom)=0
		modifygraph axisEnab(b1)={0.51,1.0}, freePos(b1)=0
	endif
	
	modifygraph axisEnab(lx)={0.8,1.0}, freePos(lx)=0
	modifygraph axisEnab(ly)={0.6,0.79}, freePos(ly)=0
	modifygraph axisEnab(lr)={0.4,0.59}, freePos(lr)=0
	modifygraph axisEnab(ltheta)={0.2,0.39}, freePos(ltheta)=0
	modifygraph axisEnab(left)={0,0.19}, freePos(left)=0
	
	modifygraph lblposmode=4, lblpos=40
	modifygraph lblpos(bottom)=30
	
	label lr "tip focus (\\F'Symbol'm\\F'Arial'm)"
	label bottom "tip height (\\F'Symbol'm\\F'Arial'm)"
	modifygraph tick=0, minor=1, btLen=4, stLen=2
	modifygraph mirror=1, fSize=10, standoff=0, axOffset=-1, axOffset(bottom)=0
end

static function display_scan2(scan_folder)
	string scan_folder
	wave x = $(scan_folder + ":alignment_scan_x")
	wave y = $(scan_folder + ":alignment_scan_y")
	wave r = $(scan_folder + ":alignment_scan_r")
	wave theta = $(scan_folder + ":alignment_scan_theta")
	wave y_psd = $(scan_folder + ":alignment_scan_y_psd")
	nvar/sdfr=$scan_folder voltage, init_pos_a
	
	dowindow/k tip_alignment
	display/n=tip_alignment
	modifygraph width=125
	modifygraph height=89*5 + 10
	textbox/c/n=params/f=0/a=mt/y=1 "\\f02V\\f00 = \\{" + num2str(voltage) + "} V, \\f02a\\f00 = \\{" + num2str(init_pos_a) + "} \F'Symbol'm\F'Arial'm"
	textbox/c/n=textx/f=0/a=LT/x=10/y=3 "\\f02x"
	textbox/c/n=texty/f=0/a=LT/x=10/y=22 "\\f02y"
	textbox/c/n=textr/f=0/a=LT/x=10/y=40 "\\f02r"
	textbox/c/n=texttheta/f=0/a=LT/x=10/y=58 "\\f02\\F'Symbol'q"
	textbox/c/n=textypsd/f=0/a=LT/x=1/y=75 "\\f02psd_y"
	
	display/host=#/w=(0,0.02,1,1)
	appendimage/l=lx x
	appendimage/l=ly y
	appendimage/l=lr r
	appendimage/l=ltheta theta
	appendimage y_psd
	modifyimage ''#0 ctab={*,*,geo,0}
	modifyimage ''#1 ctab={*,*,geo,0}
	modifyimage ''#2 ctab={*,*,geo,0}
	modifyimage ''#3 ctab={*,*,geo,0}
	modifyimage ''#4 ctab={*,*,geo,0}
	modifygraph width=80
	modifygraph height={aspect, 5}
	label lr "tip focus (\\F'Symbol'm\\F'Arial'm)"
	label bottom "tip height (\\F'Symbol'm\\F'Arial'm)"
	modifygraph tick=0, minor=1, btLen=4, stLen=2
	modifygraph mirror=1, fSize=10, standoff=0, axOffset=-1, axOffset(bottom)=0
	modifygraph axisEnab(lx)={0.8,1.0}, freePos(lx)=0
	modifygraph axisEnab(ly)={0.6,0.79}, freePos(ly)=0
	modifygraph axisEnab(lr)={0.4,0.59}, freePos(lr)=0
	modifygraph axisEnab(ltheta)={0.2,0.39}, freePos(ltheta)=0
	modifygraph axisEnab(left)={0,0.19}, freePos(left)=0
	modifygraph lblposmode=4, lblpos=40
	modifygraph lblpos(bottom)=30
	setactivesubwindow ##
end

function move_to_centre()
	//string scan_folder
	//nvar x0 = $(scan_folder + ":x0")
	//nvar y0 = $(scan_folder + ":y0")
	nvar x0 = $(gv_folder + ":x0")
	nvar y0 = $(gv_folder + ":y0")
	pi_stage#move("B", x0)
	pi_stage#move("C", y0)
end

function resonance_scan(freq_start, freq_stop, freq_inc)
	variable freq_start, freq_stop, freq_inc
	
	// error checks
	if (freq_start == 0 || freq_stop == 0 || freq_inc == 0)
		abort "enter frequency ranges"
	endif
	
	// store the current scan
	string scan_folder = data#check_data_folder()
	scan_folder = data#check_folder(scan_folder + ":resonance_scans")
	scan_folder = data#new_data_folder(scan_folder + ":scan_")
	
	// open communications
	pi_stage#open_comms()
	sig_gen#open_comms()
	lockin#open_comms(); lockin2#open_comms()
	tek#open_comms(); tek#initialise()
	
	// load scan parameters
	nvar/sdfr=$gv_folder set = alignment_set
	nvar/sdfr=$gv_folder electronic_alignment
	nvar/sdfr=$gv_folder force_alignment
	variable gain = 1e8			// 100 MV/A transimpedance amplifier
	
	// get position information
	string pi_path = pi_stage#gv_path()
	pi_stage#get_pos()					// 'b' is up/down, 'c' is focus
	nvar init_a = $(pi_path + ":pos_a")
	nvar init_b = $(pi_path + ":pos_b")
	nvar init_c = $(pi_path + ":pos_c")
	
	// store scan parameters
	variable/g $(scan_folder + ":voltage")
	variable/g $(scan_folder + ":offset")
	variable/g $(scan_folder + ":freq_start") = freq_start
	variable/g $(scan_folder + ":freq_stop") = freq_stop
	variable/g $(scan_folder + ":freq_inc") = freq_inc
	variable/g $(scan_folder + ":init_pos_a") = init_a
	variable/g $(scan_folder + ":init_pos_b") = init_b
	variable/g $(scan_folder + ":init_pos_c") = init_c
	string/g $(scan_folder + ":time_stamp") = time() + " " + date()
	variable/g $(scan_folder + ":alignment_set") = set
	variable/g $(scan_folder + ":electronic_alignment") = electronic_alignment
	variable/g $(scan_folder + ":force_alignment") = force_alignment
	
	// make alignment data waves
	make/o/n=0 $(scan_folder + ":frequency")
	wave frequency = $(scan_folder + ":frequency")
	
	if (electronic_alignment)
		make/o/n=0 $(scan_folder + ":resonance_scan_r"), $(scan_folder + ":resonance_scan_theta")
		wave res_scan_r = $(scan_folder + ":resonance_scan_r"), res_scan_theta = $(scan_folder + ":resonance_scan_theta")
		setscale d, 0, 0, "A", res_scan_r
		setscale d, 0, 0, "\degree", res_scan_theta
	endif
	if (force_alignment)
		make/o/n=0 $(scan_folder + ":resonance_scan_fr"), $(scan_folder + ":resonance_scan_ftheta")
		wave res_scan_fr = $(scan_folder + ":resonance_scan_fr"), res_scan_ftheta = $(scan_folder + ":resonance_scan_ftheta")
		setscale d, 0, 0, "V", res_scan_fr
		setscale d, 0, 0, "\degree", res_scan_ftheta
	endif
	
	make/o/n=0 $(scan_folder + ":resonance_scan_y_psd")
	wave res_scan_y_psd = $(scan_folder + ":resonance_scan_y_psd")
	
	dowindow/k tip_resonance
	display/n=tip_resonance
	appendtograph res_scan_y_psd vs frequency
	if (force_alignment)
		appendtograph/l=force_mag res_scan_fr vs frequency
		appendtograph/r=force_phase res_scan_ftheta vs frequency
	endif
	if (electronic_alignment)
		appendtograph/l=lr res_scan_r vs frequency
		appendtograph/l=lt res_scan_theta vs frequency
	endif
	
	label left "force"; label lr "3w current (pA)"; label lt "phase (deg)"; label bottom "frequency (Hz)"
	modifygraph mirror=0,tick=2,standoff=0
	modifygraph mode=0,rgb(''#1)=(0,15872,65280)
	modifygraph cmplxMode(''#1)=1, cmplxMode(''#0)=2
	modifygraph axisEnab(left)={0.5, 0.74}, axisEnab(lr)={0.25,0.49}, axisEnab(lt)={0, 0.24}
	
	modifygraph axisEnab(force_mag)={0.75, 1.0}, axisEnab(force_phase)={0.75, 1.0}
	modifygraph freePos(force_mag)=0, freepos(force_mag)=0, lblpos(force_phase)=0, lblpos(force_phase)=0
	
	modifygraph freePos(lt)=0, freepos(lr)=0, lblpos(lt)=0, lblpos(lr)=0
	modifygraph width=200, height={aspect, 2}
	modifygraph muloffset(''#1)={0,10000}
	showinfo
	
	variable freq = freq_start
	variable/c data
	variable i = 0
	tek#get_waveform_params("2")
	if (electronic_alignment)
		lockin#aphs()
	endif
	if (force_alignment)
		lockin2#aphs()
	endif
	sleep/s 1
	do
		sig_gen#set_frequency(freq); sleep/s 0.5
		redimension/n=(i+1) frequency
		frequency[i] = freq
		
		// electronic alignment
		if (electronic_alignment)
			data = lockin#measure_rtheta()
			redimension/n=(i+1) res_scan_r, res_scan_theta
			res_scan_r[i] = real(data)/gain; res_scan_theta[i] = imag(data)
		endif
		
		// force alignment
		if (force_alignment)
			data = lockin2#measure_rtheta()
			redimension/n=(i+1) res_scan_fr, res_scan_ftheta
			res_scan_fr[i] = real(data); res_scan_ftheta[i] = imag(data)
		endif
		
		wave w = tek#import_data_free("2")
		redimension/n=(i+1) res_scan_y_psd
		res_scan_y_psd[i] = wavemax(w) - wavemin(w)
		
		doupdate
		i += 1
		freq += freq_inc
	while (freq <= freq_stop)
	
	// close communications
	pi_stage#open_comms()
	sig_gen#open_comms()
	if (electronic_alignment)
		lockin#open_comms()
	endif
	if (force_alignment)
		lockin2#close_comms()
	endif
	tek#close_comms()
end

// Panel Controls

function align_tips_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			nvar scan_size = $(gv_folder + ":scan_size"), scan_step = $(gv_folder + ":scan_step")
			align_tips(scan_size, scan_step)
			break
		case -1:
			break
	endswitch
	return 0
end

function move_to_centre_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			pi_stage#open_comms()
			move_to_centre()
			pi_stage#close_comms()
			break
		case -1:
			break
	endswitch
	return 0
end

function resonance_scan_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			nvar freq_start = $(gv_folder + ":freq_start"), freq_stop = $(gv_folder + ":freq_stop")
			nvar freq_inc = $(gv_folder + ":freq_inc")
			resonance_scan(freq_start, freq_stop, freq_inc)
			break
		case -1:
			break
	endswitch
	return 0
end

function fit_alignment_data_x_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			svar scan_folder = $(gv_folder + ":current_scan_folder")
			string var = "x"
			wave wdata = $(scan_folder + ":alignment_scan_" + var)
			fit_alignment_data($scan_folder, wdata)
			nvar/sdfr=$scan_folder x0 = $(var + "_x0"), y0 = $(var + "_y0")
			set_centroid(x0, y0)
			break
		case -1:
			break
	endswitch
	return 0
end

function fit_alignment_data_y_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			svar scan_folder = $(gv_folder + ":current_scan_folder")
			string var = "y"
			wave wdata = $(scan_folder + ":alignment_scan_" + var)
			fit_alignment_data($scan_folder, wdata)
			nvar/sdfr=$scan_folder x0 = $(var + "_x0"), y0 = $(var + "_y0")
			set_centroid(x0, y0)
			break
		case -1:
			break
	endswitch
	return 0
end

function fit_alignment_data_r_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			svar scan_folder = $(gv_folder + ":current_scan_folder")
			string var = "r"
			wave wdata = $(scan_folder + ":alignment_scan_" + var)
			fit_alignment_data($scan_folder, wdata)
			nvar/sdfr=$scan_folder x0 = $(var + "_x0"), y0 = $(var + "_y0")
			set_centroid(x0, y0)
			break
		case -1:
			break
	endswitch
	return 0
end

function fit_alignment_data_theta_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			svar scan_folder = $(gv_folder + ":current_scan_folder")
			string var = "theta"
			wave wdata = $(scan_folder + ":alignment_scan_" + var)
			fit_alignment_data($scan_folder, wdata)
			nvar/sdfr=$scan_folder x0 = $(var + "_x0"), y0 = $(var + "_y0")
			set_centroid(x0, y0)
			break
		case -1:
			break
	endswitch
	return 0
end

function fit_alignment_data_y_psd_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			svar scan_folder = $(gv_folder + ":current_scan_folder")
			string var = "y_psd"
			wave wdata = $(scan_folder + ":alignment_scan_" + var)
			fit_alignment_data($scan_folder, wdata)
			nvar/sdfr=$scan_folder x0 = $"psd_x0", y0 = $"psd_y0"
			set_centroid(x0, y0)
			break
		case -1:
			break
	endswitch
	return 0
end

// fit force alignment buttons
function fit_alignment_data_fx_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			svar scan_folder = $(gv_folder + ":current_scan_folder")
			string var = "fx"
			wave wdata = $(scan_folder + ":alignment_scan_" + var)
			fit_alignment_data($scan_folder, wdata)
			nvar/sdfr=$scan_folder x0 = $(var + "_x0"), y0 = $(var + "_y0")
			set_centroid(x0, y0)
			break
		case -1:
			break
	endswitch
	return 0
end

function fit_alignment_data_fy_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			svar scan_folder = $(gv_folder + ":current_scan_folder")
			string var = "fy"
			wave wdata = $(scan_folder + ":alignment_scan_" + var)
			fit_alignment_data($scan_folder, wdata)
			nvar/sdfr=$scan_folder x0 = $(var + "_x0"), y0 = $(var + "_y0")
			set_centroid(x0, y0)
			break
		case -1:
			break
	endswitch
	return 0
end

function fit_alignment_data_fr_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			svar scan_folder = $(gv_folder + ":current_scan_folder")
			string var = "fr"
			wave wdata = $(scan_folder + ":alignment_scan_" + var)
			fit_alignment_data($scan_folder, wdata)
			nvar/sdfr=$scan_folder x0 = $(var + "_x0"), y0 = $(var + "_y0")
			set_centroid(x0, y0)
			break
		case -1:
			break
	endswitch
	return 0
end

function fit_alignment_data_fthet_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			svar scan_folder = $(gv_folder + ":current_scan_folder")
			string var = "ftheta"
			wave wdata = $(scan_folder + ":alignment_scan_" + var)
			fit_alignment_data($scan_folder, wdata)
			nvar/sdfr=$scan_folder x0 = $(var + "_x0"), y0 = $(var + "_y0")
			set_centroid(x0, y0)
			break
		case -1:
			break
	endswitch
	return 0
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
	print "Tips centred at:", x0, y0
end
