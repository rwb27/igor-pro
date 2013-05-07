#pragma rtGlobals=3		// Use modern global access method.

#include "data_handling"
#include "keithley_2635a_smu"
#include "agilent_dsox2000_series_dso"
#include "srs_sr830_lockin_amplifier"

// DC NOISE TESTING
function/wave dc_noise_test()
	dfref df = $data#check_folder("root:electronic_testing:dc_noise_test")
	// set up noise testing display and waves
	dowindow/k noise_testing
	make/o/n=0 df:noise_v, df:noise_i
	wave/sdfr=df noise_v, noise_i
	setscale d, 0, 0, "A", noise_i; setscale d, 0, 0, "V", noise_v
	display/n=noise_testing noise_i
	appendtograph/w=noise_testing/r noise_v
	label left "current noise (\\U)"; label right "voltage noise (\\U)"
	label bottom "measurement"
	modifygraph mode=3, marker=8, msize=1.5, rgb(noise_v)=(0,0,65280)
	
	// take measurements
	variable n = 0
	variable/c iv
	smu#open_comms()
	do
		iv = smu#measure_iv()
		redimension/n=(numpnts(noise_v)+1) noise_v, noise_i
		noise_v[n] = real(iv)
		noise_i[n] = imag(iv)
		doupdate
		n += 1
	while (n < 500)
	smu#close_comms()
	
	// record data
	make/o/n=6 df:dc_noise_results; wave/sdfr=df dc_noise_results
	wavestats/q noise_v
	dc_noise_results[0] = V_avg
	dc_noise_results[1] = V_sdev
	dc_noise_results[2] = V_rms
	wavestats/q noise_i
	dc_noise_results[3] = V_avg
	dc_noise_results[4] = V_sdev
	dc_noise_results[5] = V_rms
	
	return dc_noise_results
end

function/wave dc_amp_noise_test()
	// same as dc_noise_test()
	dfref df = $data#check_folder("root:electronic_testing:dc_amp_noise_test")
	// set up noise testing display and waves
	dowindow/k noise_testing
	make/o/n=0 df:noise_v, df:noise_i
	wave/sdfr=df noise_v, noise_i
	setscale d, 0, 0, "A", noise_i; setscale d, 0, 0, "V", noise_v
	display/n=noise_testing noise_i
	appendtograph/w=noise_testing/r noise_v
	label left "current noise (\\U)"; label right "voltage noise (\\U)"
	label bottom "measurement"
	modifygraph mode=3, marker=8, msize=1.5, rgb(noise_v)=(0,0,65280)
	
	// take measurements
	variable n = 0
	variable/c iv
	smu#open_comms()
	do
		iv = smu#measure_iv()
		redimension/n=(numpnts(noise_v)+1) noise_v, noise_i
		noise_v[n] = real(iv)
		noise_i[n] = imag(iv)
		doupdate
		n += 1
	while (n < 500)
	smu#close_comms()
	
	// record data
	make/o/n=6 df:dc_amp_noise_results; wave/sdfr=df dc_amp_noise_results
	wavestats/q noise_v
	dc_amp_noise_results[0] = V_avg
	dc_amp_noise_results[1] = V_sdev
	dc_amp_noise_results[2] = V_rms
	wavestats/q noise_i
	dc_amp_noise_results[3] = V_avg
	dc_amp_noise_results[4] = V_sdev
	dc_amp_noise_results[5] = V_rms
	
	// differs from dc_nosie_test from here
	// measure oscilloscope trace
	dso#open_comms()
	dso#autoscale()
	sleep/s 2
	dso#capture("1")
	dso#import_data("1", "dc_amp_noise_trace")
	dso#close_comms()
	// scale data
	wave/sdfr=$dso#data_path() dc_amp_noise_trace
	dc_amp_noise_trace /= 1e3 // gain
	setscale d, 0, 0, "A", dc_amp_noise_trace
	fft/out=3/dest=dc_amp_noise_trace_fft dc_amp_noise_trace
	// record data
	wavestats/q dc_amp_noise_trace
	dc_amp_noise_results[6] = V_avg
	dc_amp_noise_results[7] = V_sdev
	dc_amp_noise_results[8] = V_rms
	
	return dc_amp_noise_results
end

// AC NOISE TESTING
function/wave ac_noise_test()
	dfref df = $data#check_folder("root:electronic_testing:ac_noise_test")
	// set up noise testing display and waves
	dowindow/k noise_testing
	make/o/n=0 df:noise_r, df:noise_theta
	wave/sdfr=df noise_r, noise_theta
	setscale d, 0, 0, "A", noise_r; setscale d, 0, 0, "°", noise_theta
	display/n=noise_testing noise_r
	appendtograph/w=noise_testing/r noise_theta
	label left "3rd harmonic current noise (\\U)"; label right "phase noise (\\U)"
	label bottom "measurement"
	modifygraph mode=3, marker=8, msize=1.5, rgb(noise_theta)=(0,0,65280)
	
	// take measurements
	variable n = 0
	variable/c rtheta
	lockin#open_comms()
	do
		rtheta = lockin#measure_rtheta()
		redimension/n=(numpnts(noise_r)+1) noise_r, noise_theta
		noise_r[n] = real(rtheta) / 1e8										// divide by 100 MV/A gain
		noise_theta[n] = imag(rtheta)
		doupdate
		n += 1
	while (n < 500)
	lockin#close_comms()
	
	// record data
	make/o/n=6 df:ac_noise_results; wave/sdfr=df ac_noise_results
	wavestats/q noise_r
	ac_noise_results[0] = V_avg
	ac_noise_results[1] = V_sdev
	ac_noise_results[2] = V_rms
	wavestats/q noise_theta
	ac_noise_results[3] = V_avg
	ac_noise_results[4] = V_sdev
	ac_noise_results[5] = V_rms
	
	// differs from dc_nosie_test from here
	// measure oscilloscope trace
	dso#open_comms()
	dso#autoscale()
	sleep/s 2
	dso#capture("1")
	dso#import_data("1", "ac_noise_trace")
	dso#close_comms()
	// scale data
	wave/sdfr=$dso#data_path() ac_noise_trace
	ac_noise_trace /= 1e8 									// divide by 100 MV/A gain for current
	setscale d, 0, 0, "A", ac_noise_trace
	fft/out=3/dest=ac_noise_trace_fft ac_noise_trace
	// record data
	wavestats/q ac_noise_trace
	ac_noise_results[6] = V_avg
	ac_noise_results[7] = V_sdev
	ac_noise_results[8] = V_rms
	
	return ac_noise_results
end