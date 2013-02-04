#pragma rtGlobals=1		// Use modern global access method.
#include "keithley_2635a_smu"
#include "agilent infiniivision 2000 x-series dso_v2"

function append_test(n)
	variable n
	string noise
	switch(n)
		case 0:			// dc_noise
			noise = "dc_noise"
			break
		case 1:			// dc_amp_noise
			noise = "dc_amp_noise"
			break
		case 2:			// ac_noise_dso
			noise = "ac_noise_dso"
			break
		case 3:			// ac_noise
			noise = "ac_noise"
	endswitch
	setdatafolder root:
	wave w_i = $("root:" + noise + ":" + noise)
	wave/z w = $(noise + "_tests")
	if (!waveexists(w))
		make/o/n=(0,0) $(noise + "_tests")
	endif
	wave w = $(noise + "_tests")
	redimension/n=(numpnts(w) + 1, numpnts(w_i)) w
	w[numpnts(w) - 1] = w_i[q]
end

// DC NOISE TESTING

// DC noise
// Circuit:
// Keithley HI - DC HI - Tip HI - open circuit - Tip LO - Keithley LO
function dc_noise_test()
	string fname = "root:dc_noise"
	if (!datafolderexists(fname))
		newdatafolder/s $fname
	else
		setdatafolder $fname
	endif
	variable n = 0
	variable/c iv
	dowindow/k noise_testing
	make/o/n=0 dc_noise_v, dc_noise_i
	setscale d, 0, 0, "A", dc_noise_i; setscale d, 0, 0, "V", dc_noise_v
	display/n=noise_testing dc_noise_i
	appendtograph/w=noise_testing/r dc_noise_v
	label left "current noise (\\U)"; label right "voltage noise (\\U)"
	label bottom "measurement"
	modifygraph mode=3, marker=8, msize=1.5, rgb(dc_noise_v)=(0,0,65280)
	open_smu()
	do
		iv = measure_iv_smu()
		redimension/n=(numpnts(dc_noise_v)+1) dc_noise_v, dc_noise_i
		dc_noise_v[n] = real(iv)
		dc_noise_i[n] = imag(iv)
		doupdate
		n += 1
	while (n < 100)
	close_smu()
	make/o/n=6 dc_noise
	wavestats/q dc_noise_v
	dc_noise[0] = V_avg
	dc_noise[1] = V_sdev
	dc_noise[2] = V_rms
	wavestats/q dc_noise_i
	dc_noise[3] = V_avg
	dc_noise[4] = V_sdev
	dc_noise[5] = V_rms
end

// DC amp noise
// Circuit:
// Keithley HI - DC HI - Tip HI - open circuit - Tip LO - DC amp - TI amp - DSO - shield return - Keithley LO
function dc_amp_noise_test()
	string fname = "root:dc_amp_noise"
	if (!datafolderexists(fname))
		newdatafolder/s $fname
	else
		setdatafolder $fname
	endif
	variable n = 0
	variable/c iv
	dowindow/k noise_testing
	make/o/n=0 dc_noise_v, dc_noise_i
	setscale d, 0, 0, "A", dc_noise_i; setscale d, 0, 0, "V", dc_noise_v
	display/n=noise_testing dc_noise_i
	appendtograph/w=noise_testing/r dc_noise_v
	label left "current noise (\\U)"; label right "voltage noise (\\U)"
	label bottom "measurement"
	modifygraph mode=3, marker=8, msize=1.5, rgb(dc_noise_v)=(0,0,65280)
	open_smu()
	do
		iv = measure_iv_smu()
		redimension/n=(numpnts(dc_noise_v)+1) dc_noise_v, dc_noise_i
		dc_noise_v[n] = real(iv)
		dc_noise_i[n] = imag(iv)
		doupdate
		n += 1
	while (n < 100)
	close_smu()
	make/o/n=6 dc_noise
	wavestats/q dc_noise_v
	dc_noise[0] = V_avg
	dc_noise[1] = V_sdev
	dc_noise[2] = V_rms
	wavestats/q dc_noise_i
	dc_noise[3] = V_avg
	dc_noise[4] = V_sdev
	dc_noise[5] = V_rms
	openDSO()
	captureDSO("1")
	importdataDSO("1", "dc_amp_noise_trace")
	closeDSO()
	wave dc_amp_noise_trace
	dc_amp_noise_trace /= 1e4 // gain
	setscale d, 0, 0, "A", dc_amp_noise_trace
	fft/out=3/dest=dc_amp_noise_trace_fft dc_amp_noise_trace
	make/o/n=3 dc_amp_noise
	wavestats/q dc_amp_noise_trace
	dc_amp_noise[0] = V_avg
	dc_amp_noise[1] = V_sdev
	dc_amp_noise[2] = V_rms
end

// AC NOISE TESTING

// AC noise on DSO
// Circuit:
// SigGen - x20 amp - AC HI - Tip HI - open circuit - Tip LO - AC LO - TI amp - DSO
function ac_noise_dso_test()
	string fname = "root:ac_noise_dso"
	if (!datafolderexists(fname))
		newdatafolder/s $fname
	else
		setdatafolder $fname
	endif
	openDSO()
	captureDSO("1")
	importdataDSO("1", "ac_noise_trace")
	closeDSO()
	wave ac_noise_trace
	ac_noise_trace /= 1e8 // gain
	setscale d, 0, 0, "A", ac_noise_trace
	fft/out=3/dest=ac_noise_trace_fft ac_noise_trace
	dowindow/k noise_testing
	display/n=noise_testing ac_noise_trace
	label left "current (\\U)"; label bottom "time (\\U)"
	modifygraph rgb=(0,0,0)
	make/o/n=4 ac_noise_dso
	wavestats/q ac_noise_trace
	ac_noise_dso[0] = V_avg
	ac_noise_dso[1] = V_sdev
	ac_noise_dso[2] = V_rms
	ac_noise_dso[3] = V_adev
end

// AC noise on Lock-In Amp
// Circuit:
// SigGen - x20 amp - AC HI - Tip HI - open circuit - Tip LO - AC LO - TI amp - filter - lock-in
function ac_noise_test()
	string fname = "root:ac_noise"
	if (!datafolderexists(fname))
		newdatafolder/s $fname
	else
		setdatafolder $fname
	endif
	
end

function compare_systems()
	setdatafolder root:
	wave old_ac = old_ac_noise_dso_tests, no_ac = no_ac_noise_dso_tests, new_ac = new_ac_noise_dso_tests
	dowindow/k noise_comparison_avg
	display/n=noise_comparison_avg
	appendtograph new_ac[][0], old_ac[][0], no_ac[][0]
	errorbars/y=4/t=0.5 new_ac_noise_dso_tests, Y wave=(new_ac[][1], new_ac[][1])
	errorbars/y=4/t=0.5 old_ac_noise_dso_tests, Y wave=(old_ac[][1], old_ac[][1])
	errorbars/y=4/t=0.5 no_ac_noise_dso_tests, Y wave=(no_ac[][1], no_ac[][1])
	modifygraph mode=4,marker=8,msize=1.5
	modifygraph rgb(new_ac_noise_dso_tests)=(0,0,0), rgb(no_ac_noise_dso_tests) = (1,1,1)
	legend/c/n=text0/a=lt "\\s(new_ac_noise_dso_tests) new switchbox\r\\s(old_ac_noise_dso_tests) old switchbox\r\\s(no_ac_noise_dso_tests) no switchbox"
	label left "average current offset (\\U)"; label bottom "test #"
	
	dowindow/k noise_comparison_sdev
	display/n=noise_comparison_sdev
	appendtograph new_ac[][1], old_ac[][1], no_ac[][1]
	modifygraph mode=4,marker=8,msize=1.5
	modifygraph rgb(new_ac_noise_dso_tests)=(0,0,0), rgb(no_ac_noise_dso_tests) = (1,1,1)
	legend/c/n=text0/a=lt "\\s(new_ac_noise_dso_tests) new switchbox\r\\s(old_ac_noise_dso_tests) old switchbox\r\\s(no_ac_noise_dso_tests) no switchbox"
	label left "st. dev. current offset (\\U)"; label bottom "test #"
	
	dowindow/k noise_comparison_rms
	display/n=noise_comparison_rms
	appendtograph new_ac[][2], old_ac[][2], no_ac[][2]
	modifygraph mode=4,marker=8,msize=1.5
	modifygraph rgb(new_ac_noise_dso_tests)=(0,0,0), rgb(no_ac_noise_dso_tests) = (1,1,1)
	legend/c/n=text0/a=lt "\\s(new_ac_noise_dso_tests) new switchbox\r\\s(old_ac_noise_dso_tests) old switchbox\r\\s(no_ac_noise_dso_tests) no switchbox"
	label left "r.m.s. current offset (\\U)"; label bottom "test #"
end
//////////////

function ac_noise_over_time(s)
	struct WMBackgroundStruct &s
	if (!waveexists(ac_noise))
		make/o/n=(0,3) ac_noise
		make/o/n=0 datetimes
		make/t/o/n=0 dates_times
		variable/g start_t = datetime, elapsed_t
	endif
	nvar start_t, elapsed_t
	variable i
	
	openDSO()
	captureDSO("1")
	importdataDSO("1", "ac_noise_trace")
	closeDSO()
	
	elapsed_t = datetime - start_t
	elapsed_t /= (60 * 60)			// convert secs to hours
	
	wave ac_noise_trace
	i = numpnts(datetimes)
	redimension/n=(i + 1) datetimes, dates_times
	redimension/n=(i + 1, 3) ac_noise
	datetimes[i] = datetime
	dates_times[i] = time() + " " + date()
	wavestats/q ac_noise_trace
	ac_noise[i][0] = V_avg
	ac_noise[i][1] = V_sdev
	ac_noise[i][2] = V_rms
	if (elapsed_t > 168)			// 1 week = 7 days * 24 hours = 168 hours
		return 1
	else
		return 0
	endif
end

function start_bkgd_noise_test()
	variable num_ticks = 60 * 60 * 15	// 15 mins
	ctrlnamedbackground noise_test, period = num_ticks, proc = ac_noise_over_time
	ctrlnamedbackground noise_test, start
end

function stop_bkgd_noise_test()
	ctrlnamedbackground noise_test, stop
end