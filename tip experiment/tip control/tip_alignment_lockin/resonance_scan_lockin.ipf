#pragma moduleName = tip_res
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "hp33120a_sig_gen"
#include "srs_sr830_lockin_amplifier"
#include "srs_sr830_lockin_amplifier_2"

static strconstant gv_folder = "root:global_variables:tip_alignment"

static function/df init_scan_folder()
	dfref df = $data#check_data_folder()
	newdatafolder/o df:resonance_scans
	df = df:resonance_scans
	setdatafolder df
	string sname = uniquename("scan_", 11, 1)
	setdatafolder root:
	newdatafolder/o df:$sname
	dfref scan_folder = df:$sname
	string/g $(gv_folder + ":current_scan_folder") = getdatafolder(1, scan_folder)
	return scan_folder
end

function resonance_scan(freq_start, freq_stop, freq_inc)
	variable freq_start, freq_stop, freq_inc
	// error checks
	if (freq_start == 0 || freq_stop == 0 || freq_inc == 0)
		abort "enter frequency ranges"
	endif
	
	dfref sf = init_scan_folder()
	
	// open communications
	sig_gen#open_comms()
	lockin#open_comms(); lockin2#open_comms()
	
	// store scan parameters
	nvar amplified_voltage = $(gv_folder + ":amplified_voltage")
	nvar amplified_offset = $(gv_folder + ":amplified_offset")
	nvar/sdfr=$gv_folder set = alignment_set
	variable/g sf:freq_start = freq_start
	variable/g sf:freq_stop = freq_stop
	variable/g sf:freq_inc = freq_inc
	variable/g sf:voltage = amplified_voltage
	variable/g sf:offset = amplified_offset
	variable/g sf:alignment_set = set
	string/g sf:time_stamp = time() + " " + date()
	
	// make alignment data waves
	make/o/n=0 sf:frequency
	wave/sdfr=sf frequency
	
	make/o/n=0 sf:force_scan_r, sf:force_scan_theta
	wave/sdfr=sf scan_r = force_scan_r, theta = force_scan_theta
	setscale d, 0 ,0, "V", scan_r
	setscale d, 0, 0, "°", theta
	
	make/o/n=0 sf:current_scan_r, sf:current_scan_theta
	wave/sdfr=sf current_r = current_scan_r, current_theta = current_scan_theta
	setscale d, 0, 0, "V", current_r
	setscale d, 0, 0, "°", current_theta
	
	dowindow/k tip_resonance
	display/k=1/n=tip_resonance
	appendtograph/l scan_r vs frequency
	appendtograph/r theta vs frequency
	appendtograph/l=lr current_r vs frequency
	appendtograph/l=lt current_theta vs frequency
	
	label left "force"; label lr "3w current (pA)"; label lt "phase (deg)"; label bottom "frequency (Hz)"
	modifygraph mirror=0,tick=2,standoff=0
	modifygraph mode=0,rgb(''#1)=(0,15872,65280)
	modifygraph cmplxMode(''#1)=1, cmplxMode(''#0)=2
	modifygraph freepos=0, lblpos=0
	modifygraph axisEnab(lr)={0.33, 0.66}, axisEnab(lt)={0,0.32}
	modifygraph axisEnab(left)={0.67, 1.0}, axisEnab(right)={0.67, 1.0}
	modifygraph width=200, height={aspect, 2}
	modifygraph muloffset(''#1)={0,10000}
	showinfo
	
	variable time_constant
	lockin#purge()
	lockin#aphs()	
	time_constant = lockin#get_time_constant()
	
	lockin2#purge()
	lockin2#aphs()
	time_constant = lockin2#get_time_constant()
	
	variable freq = freq_start
	variable/c data
	variable i = 0
	do
		sig_gen#set_frequency(freq); sleep/s 0.1
		redimension/n=(i+1) frequency
		frequency[i] = freq
		sleep/s time_constant*3
		
		// electronic alignment
		data = lockin#measure_rtheta()
		redimension/n=(i+1) current_r, current_theta
		current_r[i] = real(data)
		current_theta[i] = imag(data)
		
		// force alignment
		data = lockin2#measure_rtheta()
		redimension/n=(i+1) scan_r, theta
		scan_r[i] = real(data)
		theta[i] = imag(data)
		
		doupdate
		i += 1
		freq += freq_inc
	while (freq <= freq_stop)
	
	// close communications
	sig_gen#close_comms()
	lockin#close_comms(); lockin2#close_comms()
end