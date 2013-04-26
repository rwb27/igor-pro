#pragma ModuleName = afm
#pragma version = 6.31
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "data_handling"
#include "pi_pi733_3cd_stage"
#include "hp33120a_sig_gen"
#include "srs_sr830_lockin_amplifier"
#include "srs_sr830_lockin_amplifier_2"
#include "tip_control_and_alignment"

static strconstant gv_folder = "root:global_variables:tip_alignment"

function measure_signal()
	// setup the current scan
	string scan_folder = data#check_data_folder()
	scan_folder = data#check_folder(scan_folder + ":alignment_scans")
	scan_folder = data#new_data_folder(scan_folder + ":voltage_scan_")
	dfref sf = $scan_folder

	// set up which voltages to test //
	make/o/n=0 sf:voltage_range
	wave/sdfr=sf voltage_range
	variable i, V = 2
	do
		i = numpnts(voltage_range)
		redimension/n=(i+1) voltage_range
		voltage_range[i] = V
		if (V >= 3.950 && V < 4.000)
			V += 0.001
		elseif (V == 3.9)
			V += 0.05
		elseif (V == 4.0)
			V += 0.1
		else
			V += 0.1
		endif
	while (V <= 18)
	setscale d, 0, 0, "V", voltage_range
	
	// load scan parameters and signal information
	nvar/sdfr=$gv_folder electronic_alignment
	nvar/sdfr=$gv_folder force_alignment
	variable gain = 1e8				// 100 MV/A transimpedance amplifier
	variable/g $(scan_folder + ":electronic_alignment") = electronic_alignment
	variable/g $(scan_folder + ":force_alignment") = force_alignment
	string/g $(scan_folder + ":time_stamp") = time() + " " + date()
	
	// create data waves //
	if (electronic_alignment)
		make/o/n=(numpnts(voltage_range)) sf:scan_x, sf:scan_y, sf:scan_r, sf:scan_theta
		wave/sdfr=sf scan_x, scan_y, scan_r, scan_theta
		setscale d, 0, 0, "A", scan_r
		setscale d, 0, 0, "°", scan_theta
	endif
	if (force_alignment)
		make/o/n=(numpnts(voltage_range)) sf:scan_fx, sf:scan_fy, sf:scan_fr, sf:scan_ftheta
		wave/sdfr=sf scan_fx, scan_fy, scan_fr, scan_ftheta
		setscale d, 0, 0, "V", scan_fr
		setscale d, 0, 0, "°", scan_ftheta
	endif
	
	// display data //
	dowindow/k voltage_scan
	display/n=voltage_scan
	if (electronic_alignment)
		appendtograph/l scan_r vs voltage_range
		appendtograph/r scan_theta vs voltage_range
	endif
	if (force_alignment)
		appendtograph/l=force_l scan_fr vs voltage_range
		appendtograph/r=force_r scan_ftheta vs voltage_range
	endif
	modifygraph axisEnab(left)={0.5,1.0}, freePos(left)=0
	modifygraph axisEnab(right)={0.5,1.0}, freePos(right)=0
	modifygraph axisEnab(force_l)={0.0,0.5}, freePos(force_l)=0
	modifygraph axisEnab(force_r)={0.0,0.5}, freePos(force_r)=0
	modifygraph log(left)=1, log(force_l)=1
	modifygraph rgb=(0,0,0), lstyle(scan_theta)=2, lstyle(scan_ftheta)=2
	label left "3f current (\\U)"
	label right "phase (\\U)"
	label force_l "amplitude (\\U)"
	label force_r "phase (\\U)"
	label bottom "voltage (\\U)"
	modifygraph lblPosMode=1
	
	// setup measurements //
	// open comms
	sig_gen#open_comms()
	lockin#open_comms()
	lockin2#open_comms()
	
	if (electronic_alignment)
		lockin#aphs()				// auto-phase lock-in amplifier
	endif
	if (force_alignment)
		lockin2#aphs()				// auto-phase lock-in amplifier
	endif
	
	// take measurements //
	variable/c data
	for (i = numpnts(voltage_range) - 1; i >= 0; i -= 1)
		sig_gen#set_amplitude(voltage_range[i]/20)
		sleep/s 1
		// electronic lock-in measurements //
		if (electronic_alignment)
			data = lockin#measure_xy()
			scan_x[i] = real(data)
			scan_y[i] = imag(data) 
			data = lockin#measure_rtheta()
			scan_r[i] = real(data)/gain
			scan_theta[i] = imag(data)
		endif
		// force lock-in measurements //
		if (force_alignment)
			data = lockin2#measure_xy()
			scan_fx[i] = real(data)
			scan_fy[i] = imag(data) 
			data = lockin2#measure_rtheta()
			scan_fr[i] = real(data)
			scan_ftheta[i] = imag(data)
		endif
		doupdate
	endfor
	
	// close comms
	sig_gen#close_comms()
	lockin#close_comms()
	lockin2#close_comms()
end