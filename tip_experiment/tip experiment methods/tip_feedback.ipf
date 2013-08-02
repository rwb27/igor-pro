#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma moduleName = tip_feedback

#include "pi_pi733_3cd_stage"
#include "tektronix_tds1001b"
#include "srs_sr830_lockin_amplifier"
#include "srs_sr830_lockin_amplifier_2"
#include "tip_alignment"
#include "hp33120a_sig_gen"
#include "OO spectrometer v4.2"
#include "centroid_tracking"

static function start_hold_position(set_point, set_type, voltage, scan_step, scan_size)
	variable set_point, voltage, scan_step, scan_size
	string set_type
	// setup
	newdatafolder/o root:tip_position
	dfref df = root:tip_position
	variable/g df:set_point=set_point, df:voltage=voltage, df:scan_step=scan_step, df:scan_size=scan_size
	string/g df:set_type=set_type
	//// open comms
	sig_gen#open_comms()
	pi_stage#open_comms()
	lockin2#open_comms()
	//// set voltage
	sig_gen#set_amplitude(voltage/20)
	//// set piezo controller
	pi_stage#set_dco_a(0)	// should be on since holding static but tests indicate it may be better off
	pi_stage#set_dco_b(0)
	pi_stage#set_dco_c(0)
	//// create required alignment waves
	variable imax = scan_size/scan_step
	make/o/n=(imax, imax) df:alignment_scan_fr
	make/o/n=(imax, imax) df:alignment_scan_ftheta
	make/o/n=(imax) df:x_ax
	make/o/n=(imax) df:y_ax
	//// scale alignment waves
	wave/sdfr=df fr = alignment_scan_fr, ftheta = alignment_scan_ftheta
	wave/sdfr=df x_ax, y_ax
	setscale d, 0, 0, "V", fr; setscale d, 0, 0, "°", ftheta
	setscale d, 0, 0, "m", x_ax; setscale d, 0, 0 ,"m", y_ax
	//// display scan window
	display_scan()
	//// setup equipment
	lockin2#purge()
	lockin2#aphs()				// auto-phase lock-in amplifier
	//// create measurement waves
	make/o/n=0 df:amplitude, df:position_a, df:position_b, df:position_c
	make/d/o/n=0 df:dtime
	setscale d, 0, 0, "dat", df:dtime
	wave/sdfr=df amplitude, position_a, position_b, position_c, dtime
	dowindow/k amp_show
	display/n=amp_show amplitude vs dtime
	appendtograph/r position_a vs dtime
	//appendtograph/r position_b vs dtime
	//appendtograph/r position_c vs dtime
	variable/g df:set_value = 0, df:scan_valid = 0
	CtrlNamedBackground feedback, period=60*60, proc=tip_feedback#background_loop
	CtrlNamedBackground feedback, start
end

static function stop_hold_position()
	// shut down
	CtrlNamedBackground feedback, stop
	//// close comms
	sig_gen#close_comms()
	pi_stage#close_comms()
	lockin2#close_comms()
end

static function background_loop(s)
	struct WMBackgroundStruct &s
	//// check for manual escape
	variable keys = getkeystate(0)
	if (keys & 32)	
		abort
	elseif (keys & 4)
		return 0
	endif
	//// run feedback
	dfref df = root:tip_position
	nvar/sdfr=df set_point, scan_step, scan_size
	svar/sdfr=df set_type
	print "aligning tips"
	align_tips(scan_size, scan_step)
	doupdate
	print "moving to centre"
	move_to_centre()
	print "adjusting position"
	adjust_position(set_point, set_type)
	print "updating measurements"
	//// measure position
	pi_stage#get_pos()
	nvar/z/sdfr=df set_value
	string pi_path = pi_stage#gv_path()	
	nvar/sdfr=$pi_path pos_a, pos_b, pos_c
	wave/sdfr=df amplitude, position_a, position_b, position_c, dtime
	variable i = numpnts(amplitude)
	redimension/n=(i+1) amplitude, position_a, position_b, position_c, dtime
	dtime[i] = datetime
	amplitude[i] = set_value
	position_a[i] = pos_a
	position_b[i] = pos_b
	position_c[i] = pos_c
	doupdate
	return 0
end

////////////////////////////////////////

static function align_tips(scan_size, scan_step)
	variable scan_size, scan_step
	// setup
	dfref df = root:tip_position
	//// initialise piezo positions
	string pi_path = pi_stage#gv_path()
	string align_path = alignment#gv_path()
	nvar/sdfr=$align_path set_point_a, set_point_b, set_point_c
	pi_stage#get_pos()					// read dco on position	
	nvar/sdfr=$pi_path pos_a0 = pos_a		// load read piezo positions
	nvar/sdfr=$pi_path pos_b0 = pos_b
	nvar/sdfr=$pi_path pos_c0 = pos_c
	variable init_a = set_point_a //pos_a0 //pi_stage#get_pos_ch("a")	// set initial piezo position
	variable init_b = set_point_b //pos_b0 //pi_stage#get_pos_ch("b")
	variable init_c = set_point_c //pos_c0 //pi_stage#get_pos_ch("c")
	variable pos_a = init_a, pos_b = init_b, pos_c = init_c	// set variable to change as initial position
	
	//// set starting positions
	pos_b = init_b - scan_size/2; pos_c = init_c - scan_size/2
	
	// make alignment data waves
	wave/sdfr=df fr = alignment_scan_fr, ftheta = alignment_scan_ftheta, x_ax, y_ax
	x_ax = pos_b + scan_step*x
	y_ax = pos_c + scan_step*x
	setscale/p x, pos_b, scan_step, fr, ftheta
	setscale/p y, pos_c, scan_step, fr, ftheta
	variable time_constant = lockin2#get_time_constant()
	
	// measurements
	variable ib = 0, ic = 0, inc=1
	variable/c data
	variable imax = scan_size/scan_step
	do
		pi_stage#move("C", pos_c)
		do
			pi_stage#move("B", pos_b)
			sleep/s time_constant*4
			data = lockin2#measure_rtheta()
			fr[ib][ic] = real(data)
			ftheta[ib][ic] = imag(data)	
			doupdate
			// increment B position //
			pos_b += scan_step
			ib += 1
		while (ib < imax)
		// move back to initial B position //
		pos_b = init_b - scan_size/2
		pi_stage#move("b", pos_b)
		ib = 0
		// increment C position //
		pos_c += scan_step
		ic += 1
	while (ic < imax)

	// finish
	pi_stage#move("b", init_b); pi_stage#move("c", init_c)
	// analysis
	centroid#get_centroids(fr, x_ax, y_ax)
	centroid#get_centroids(ftheta, x_ax, y_ax)
	return 0
end

static function display_scan()
	dfref df = root:tip_position
	wave/sdfr=df fr = alignment_scan_fr, ftheta = alignment_scan_ftheta
	dowindow/k tip_alignment
	display/n=tip_alignment
	appendimage/l=lr fr
	appendimage/l=ltheta ftheta
	modifyimage ''#0 ctab={*,*,geo,0}
	modifyimage ''#1 ctab={*,*,geo,0}
	modifygraph width=2*40
	modifygraph axisEnab(lr)={0.51,1.0}, freePos(lr)=0
	modifygraph axisEnab(ltheta)={0.0,0.49}, freePos(ltheta)=0
	modifygraph lblposmode=4, lblpos=40
	modifygraph lblpos(bottom)=30
	label lr "tip focus (\\F'Symbol'm\\F'Arial'm)"
	label bottom "tip height (\\F'Symbol'm\\F'Arial'm)"
	modifygraph tick=0, minor=1, btLen=4, stLen=2
	modifygraph mirror=1, fSize=10, standoff=0, axOffset=-1, axOffset(bottom)=0
end

static function move_to_centre()
	dfref df = root:tip_position
	nvar x0 = df:ftheta_x0, y0 = df:ftheta_y0
	pi_stage#move("B", x0)
	pi_stage#move("C", y0)
	print "moving to", x0, y0
	string align_path = alignment#gv_path()
	nvar/sdfr=$align_path set_point_b, set_point_c
	set_point_b = x0; set_point_c = y0
end

static function adjust_position(set_point, set_type)
	variable set_point
	string set_type
	dfref df = root:tip_position
	nvar/sdfr=df set_value, scan_valid
	if (!scan_valid)
		return 0
	endif
	variable dz
	if (stringmatch(set_type, "amp"))
		set_value = real(lockin2#measure_rtheta())
		dz = -2*(set_value - set_point) + 1e-3
	elseif (stringmatch(set_type, "phase"))
		set_value = imag(lockin2#measure_rtheta())
		dz = -2*(set_value - set_point) + 1e-3
	endif
	dz = 1e-3
	if (set_point <= set_value)				// too far away from sample
		print "set value =", set_value, "set point =",  set_point
		print "moving in", 1000*dz
		pi_stage#move_rel("A", -dz)	// move in 1 nm
	elseif (set_point > set_value)			// too close to sample
		print set_value, set_point
		print "moving out", 1000*dz
		pi_stage#move_rel("A", dz)		// move out 1 nm
	endif
	return 0
end

// Gaussian Fitting Algorithms //
static function fit_alignment_data(data)
	wave data
	dfref df = root:tip_position
	dowindow/f tip_alignment
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
	make/o/t/n=0 df:t_constraints
	wave/t/sdfr=df t_constraints
	variable q = 0		// Constraint counter
	// Constraint -- x0 and y0 must lie within the scan area
	redimension/n=(q+2) t_constraints
	t_constraints[q] = "K2 > " + num2str(dimOffset(data,0)) ; q = q+1
	t_constraints[q] = "K2 < " + num2str(dimOffset(data,0)+dimsize(data,0)*dimDelta(data,0)); q = q+1
	redimension/n=(q+2) t_constraints
	t_constraints[q] = "K4 > " + num2str(dimOffset(data,1)); q = q+1
	t_constraints[q] = "K4 < " + num2str(dimOffset(data,1)+dimsize(data,1)*dimDelta(data,1)); q = q+1
	// Constraint -- sigx and sigy must be between 50nm and 1um
	//redimension/n=(q+2) t_constraints
	//t_constraints[q] = "K3 > 0.05"; q = q+1
	//t_constraints[q] = "K3 < 1"; q = q+1
	//redimension/n=(q+2) t_constraints
	//t_constraints[q] = "K5 > 0.05"; q = q+1
	//t_constraints[q] = "K5 < 1"; q = q+1
	
	// Constraint -- corr must be between -1 and 1
	redimension/n=(q+2) t_constraints
	t_constraints[q] = "K6 > -1"; q = q+1
	t_constraints[q] = "K6 < 1"; q = q+1
	
	make/d/n=7/o df:w_coef
	wave/sdfr=df w_coef
	w_coef[0] = {z0, a0, x0, sigx, y0, sigy, corr}
	funcfitmd/nthr=0/q gauss2d_elliptic w_coef  data /d/c=t_constraints
	//curvefit/x=1/nthr=0/q gauss2d, kwcwave=w_coef, data /d/c=t_constraints
	modifycontour/w=tip_alignment $("fit_" + nameofwave(data)) labels=0//, ctabLines={*,*,Geo,0}
	wave w_sigma
	
	string expr = "(.*)_(.*)", wave_id, rest_of_wavename
	splitstring/e=(expr) nameofwave(data), rest_of_wavename, wave_id
	duplicate/o w_coef, df:$(wave_id + "_w_coef")
	duplicate/o w_sigma, df:$(wave_id + "_w_sigma")
	print w_sigma[2], wave_id
	variable/g df:$(wave_id + "_x0") = w_coef[2]
	variable/g df:$(wave_id + "_y0") = w_coef[4]
end

static function gauss2d_elliptic(w, x, y) : fitfunc
	wave w
	variable x, y
	return w[0]+w[1]*exp(-1/2/(1-w[6]^2)*((x-w[2])^2/w[3]^2+(y-w[4])^2/w[5]^2)-2*w[6]*(x-w[2])*(y-w[4])/w[3]/w[5])
end