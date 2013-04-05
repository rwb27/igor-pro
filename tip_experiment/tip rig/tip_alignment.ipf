#pragma ModuleName = alignment
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "data_handling"
#include "pi_pi733_3cd_stage"
#include "hp33120a_sig_gen"
#include "srs_sr830_lockin_amplifier"
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
end

function align_tips(scan_size, scan_step)
	variable scan_size, scan_step
	
	// open comms
	//pi_stage#close_comms()
	//lockin#close_comms()
	//tek#close_comms()
	pi_stage#open_comms()
	// DCO off for dynamic movement, DCO on for holding static
	pi_stage#set_dco_a(1)
	pi_stage#set_dco_b(0)
	pi_stage#set_dco_c(0)
	pi_stage#get_dco()
	lockin#open_comms()
	tek#open_comms(); tek#initialise()
	sig_gen#open_comms()
	
	// load signal information
	string sig_gen_path = sig_gen#gv_path()
	nvar frequency = $(sig_gen_path + ":frequency")
	nvar amplified_voltage = $(gv_folder + ":amplified_voltage")
	nvar amplified_offset = $(gv_folder + ":amplified_offset")
	nvar/sdfr=$gv_folder set = alignment_set
	
	// initialise piezo information
	string pi_path = pi_stage#gv_path()
	variable init_a = pi_stage#get_pos_ch("a")
	variable init_b = pi_stage#get_pos_ch("b")
	variable init_c = pi_stage#get_pos_ch("c")
	nvar/sdfr=$pi_path pos_api = pos_a
	nvar/sdfr=$pi_path pos_bpi = pos_b
	nvar/sdfr=$pi_path pos_cpi = pos_c
	variable pos_a = init_a, pos_b = init_b, pos_c = init_c
	variable gain = 1e8
	
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
	string/g $(scan_folder + ":time_stamp") = time() + " " + date()
	
	// make alignment data waves
	variable imax = scan_size/scan_step
	make/o/n=(imax, imax) $(scan_folder + ":alignment_scan_x")
	make/o/n=(imax, imax) $(scan_folder + ":alignment_scan_y")
	make/o/n=(imax, imax) $(scan_folder + ":alignment_scan_r")
	make/o/n=(imax, imax) $(scan_folder + ":alignment_scan_theta")
	make/o/n=(imax, imax) $(scan_folder + ":alignment_scan_y_psd")
	make/o/n=(imax, imax) $(scan_folder + ":x_pos")
	make/o/n=(imax, imax) $(scan_folder + ":y_pos")
	//make/o/n=(imax, imax) $(scan_folder + ":alignment_scan_y_psd_freq")
	//make/o/n=(imax, imax) $(scan_folder + ":alignment_scan_y_psd_pk2pk")
	nvar/sdfr=$tek#gv_path() num_points
	make/o/n=(imax, imax, num_points) $(scan_folder + ":alignment_trace_y_psd")
	wave x = $(scan_folder + ":alignment_scan_x")
	wave y = $(scan_folder + ":alignment_scan_y")
	wave scan_r = $(scan_folder + ":alignment_scan_r")
	wave theta = $(scan_folder + ":alignment_scan_theta")
	wave y_psd = $(scan_folder + ":alignment_scan_y_psd")
	//wave y_psd_freq = $(scan_folder + ":alignment_scan_y_psd_freq")
	//wave y_psd_pk = $(scan_folder + ":alignment_scan_y_psd_pk2pk")
	wave y_psd_trace = $(scan_folder + ":alignment_trace_y_psd")
	wave x_pos = $(scan_folder + ":x_pos")
	wave y_pos = $(scan_folder + ":y_pos")
	setscale/p x, init_b - scan_size/2, scan_step, x, y, scan_r, theta, y_psd
	setscale/p y, init_c - scan_size/2, scan_step, x, y, scan_r, theta, y_psd
	
	// plot scan
	display_scan(scan_folder)
	
	pos_b = init_b - scan_size/2
	pos_c = init_c - scan_size/2
	
	tek#get_waveform_params("2")
	lockin#aphs(); sleep/s 1
	
	variable ib = 0, ic = 0
	variable/c data
	do
		pi_stage#move("C", pos_c)
		sleep/s 0.5
		do
			pi_stage#move("B", pos_b)
			sleep/s 0.5
			x_pos[ib][ic] = pos_bpi
			y_pos[ib][ic] = pos_cpi
			data = lockin#measure_xy()
			x[ib][ic] = real(data)
			y[ib][ic] = imag(data) 
			data = lockin#measure_rtheta()
			scan_r[ib][ic] = real(data)/gain
			theta[ib][ic] = imag(data)
			wave w = tek#import_data_free("2")
			y_psd_trace[ib][ic][] = w[r]
			y_psd[ib][ic] = wavemax(w) - wavemin(w)
			//y_psd_freq[ib][ic] = tek#meas("2", "freq")
			//y_psd_pk[ib][ic] = tek#meas("2", "pk2pk")
			doupdate
			// increment B position
			pos_b += scan_step
			ib += 1
		while (ib < imax)
		// move back to initial B position
		pos_b = init_b - scan_size/2
		pi_stage#move("B", pos_b)
		ib = 0
		// increment C position
		pos_c += scan_step
		ic += 1
	while (ic < imax)
	pi_stage#move("B", init_b)
	pi_stage#move("C", init_c)
	
	fit_alignment_data(scan_folder, x)
	fit_alignment_data(scan_folder, y)
	fit_alignment_data(scan_folder, scan_r)
	fit_alignment_data(scan_folder, theta)
	fit_alignment_data(scan_folder, y_psd)
	
	// close comms
	pi_stage#close_comms()
	tek#close_comms()
	lockin#close_comms()
	sig_gen#close_comms()
end

function fit_alignment_data(scan_folder, data)
	string scan_folder
	wave data
	
	dowindow/f tip_alignment
	setdatafolder $scan_folder
	
	variable z0, a0, x0, sigx, y0, sigy, corr
	imagestats data
	variable ix = dimsize(data, 0)-1, iy = dimsize(data, 1)-1
	z0 = 1/4 * (data[0][0] + data[ix][0] + data[0][iy] + data[ix][iy])
	a0 = data[ix/2][iy/2] - z0
	x0 = dimoffset(data, 0) + ix/2 * dimdelta(data, 0)
	sigx = 0.5
	y0 = dimoffset(data, 1) + iy/2 * dimdelta(data, 1)
	sigy = 0.5
	corr = 0
	
	// Constraints on fit
	// Note: {K0,K1,K2,K3,K4,K5,K6} = {z0,a0,x0,sigx,y0,sigy,corr}
	make/o/t/n=0 $(scan_folder + ":t_constraints")
	wave/t t_constraints = $(scan_folder + ":t_constraints")
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
	
	make/d/n=7/o $(scan_folder + ":w_coef")
	wave w_coef = $(scan_folder + ":w_coef")
	w_coef[0] = {z0, a0, x0, sigx, y0, sigy, corr}
	//funcfitmd/nthr=0/q gauss2d w_coef  data /d/c=t_constraints
	curvefit/x=1/nthr=0/q gauss2d, kwcwave=w_coef, data /d/c=t_constraints
	wave w_sigma
	setdatafolder root:
	//modifycontour $(scan_folder + ":fit_" + data) labels=0, ctabLines={*,*,Geo32,0}
	
	variable/g $(scan_folder + ":x0") = w_coef[2]
	variable/g $(scan_folder + ":y0") = w_coef[4]
	variable/g $(gv_folder + ":x0") = w_coef[2]
	variable/g $(gv_folder + ":y0") = w_coef[4]
end

static function display_scan(scan_folder)
	string scan_folder
	wave x = $(scan_folder + ":alignment_scan_x")
	wave y = $(scan_folder + ":alignment_scan_y")
	wave r = $(scan_folder + ":alignment_scan_r")
	wave theta = $(scan_folder + ":alignment_scan_theta")
	wave y_psd = $(scan_folder + ":alignment_scan_y_psd")
	
	dowindow/k tip_alignment
	display/n=tip_alignment
	
	textbox/c/n=textx/f=0/a=LT/x=10/y=3 "\\f02x"
	textbox/c/n=texty/f=0/a=LT/x=10/y=22 "\\f02y"
	textbox/c/n=textr/f=0/a=LT/x=10/y=40 "\\f02r"
	textbox/c/n=texttheta/f=0/a=LT/x=10/y=58 "\\f02\\F'Symbol'q"
	textbox/c/n=textypsd/f=0/a=LT/x=1/y=75 "\\f02psd_y"
	
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
	lockin#open_comms()
	tek#open_comms(); tek#initialise()
	
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
	
	// make alignment data waves
	make/o/n=0 $(scan_folder + ":resonance_scan_r"), $(scan_folder + ":resonance_scan_theta")
	make/o/n=0 $(scan_folder + ":resonance_scan_y_psd")
	make/o/n=0 $(scan_folder + ":frequency")
	wave res_scan_r = $(scan_folder + ":resonance_scan_r"), res_scan_theta = $(scan_folder + ":resonance_scan_theta")
	wave res_scan_y_psd = $(scan_folder + ":resonance_scan_y_psd")
	wave frequency = $(scan_folder + ":frequency")
	dowindow/k tip_resonance
	display/n=tip_resonance
	appendtograph res_scan_y_psd vs frequency
	appendtograph/l=lr res_scan_r vs frequency
	appendtograph/l=lt res_scan_theta vs frequency
	
	label left "force"; label lr "3w current (pA)"; label lt "phase (deg)"; label bottom "frequency (Hz)"
	modifygraph mirror=0,tick=2,standoff=0
	modifygraph mode=0,rgb(''#1)=(0,15872,65280)
	modifygraph cmplxMode(''#1)=1, cmplxMode(''#0)=2
	modifygraph axisEnab(left)={0.68, 1.0}, axisEnab(lr)={0.34,0.66}, axisEnab(lt)={0, 0.32}
	modifygraph freePos(lt)=0, freepos(lr)=0, lblpos(lt)=0, lblpos(lr)=0
	modifygraph width=250, height={aspect, 1.5}
	modifygraph muloffset(''#1)={0,10000}
	showinfo
	
	variable freq = freq_start
	variable/c data
	variable i = 0
	tek#get_waveform_params("2")
	lockin#aphs(); sleep/s 1
	do
		sig_gen#set_frequency(freq); sleep/s 0.5
		data = lockin#measure_rtheta()
		redimension/n=(i+1) res_scan_r, res_scan_theta, res_scan_y_psd, frequency
		res_scan_r[i] = real(data); res_scan_theta[i] = imag(data)
		
		wave w = tek#import_data_free("2")
		res_scan_y_psd[i] = wavemax(w) - wavemin(w)
		
		frequency[i] = freq
		doupdate
		i += 1
		freq += freq_inc
	while (freq <= freq_stop)
	
	// close communications
	pi_stage#open_comms()
	sig_gen#open_comms()
	lockin#open_comms()
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
			wave data = $(scan_folder + ":alignment_scan_x")
			fit_alignment_data(scan_folder, data)
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
			wave data = $(scan_folder + ":alignment_scan_y")
			fit_alignment_data(scan_folder, data)
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
			wave data = $(scan_folder + ":alignment_scan_r")
			fit_alignment_data(scan_folder, data)
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
			wave data = $(scan_folder + ":alignment_scan_theta")
			fit_alignment_data(scan_folder, data)
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
			wave data = $(scan_folder + ":alignment_scan_y_psd")
			fit_alignment_data(scan_folder, data)
			break
		case -1:
			break
	endswitch
	return 0
end