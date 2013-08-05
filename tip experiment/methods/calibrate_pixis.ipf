#pragma modulename = calibrate
#pragma rtGlobals=1		// Use modern global access method.

#include "data_handling"

function find_peaks(spec, cal_spec, cal_spec_wavelength)
	wave spec, cal_spec, cal_spec_wavelength
	dfref spec_dfr = getwavesdatafolderdfr(spec)
	make/o/n=(numpnts(spec)) spec_dfr:wavelength = x
	wave wavelength = spec_dfr:wavelength
	dowindow/k calibrations
	display/n=calibrations
	appendtograph spec vs wavelength
	cursor/p A, spec, leftx(spec)+100
	appendtograph/r/b=cal cal_spec vs cal_spec_wavelength
	cursor B, cal_spec, leftx(cal_spec)+100
	setaxis/a=2 left; setaxis/a=2 right
	modifygraph axisenab(bottom) = {0, 0.49}, axisenab(cal) = {0.51, 1}, freepos(cal) = 0
	modifygraph width = 500, height = {aspect, 0.3}
	modifygraph rgb('')=(0,0,0)
	showinfo
	doupdate
	
	variable num_peaks
	prompt num_peaks, "number of peaks"
	doprompt "find peaks", num_peaks
	make/o/n=(num_peaks) spec_dfr:spec_peaks, spec_dfr:cal_spec_peaks
	wave spec_peaks = spec_dfr:spec_peaks, cal_spec_peaks = spec_dfr:cal_spec_peaks

	variable i
	for (i = 0; i < num_peaks; i += 1)
		newpanel /k=2 /w=(187,368,437,531) as "find peaks"
		dowindow/c tmp_panel					// Set to an unlikely name
		autopositionwindow/e/m=1/r=calibrations			// Put panel near the graph
		drawtext 21,20,"Adjust the cursors and then"
		drawtext 21,40,"Click Continue."
		drawtext 21, 60, num2str(i)
		button button0,pos={80,58},size={92,20},title="Continue"
		button button0,proc=kill_panel
		pauseforuser tmp_panel, calibrations
		dowindow/k tmp_panel
		spec_peaks[i] = pcsr(A)
		cal_spec_peaks[i] = hcsr(B)
	endfor
end

function kill_panel(ctrlname) : buttoncontrol
	string ctrlname
	dowindow/k tmp_panel
end

function calibrate_peaks(spec)
	wave spec
	dfref spec_dfr = getwavesdatafolderdfr(spec)
	wave wavelength = spec_dfr:wavelength
	wave spec_peaks = spec_dfr:spec_peaks, cal_spec_peaks = spec_dfr:cal_spec_peaks
	display/n=cal_fit cal_spec_peaks vs spec_peaks
	modifygraph rgb=(0,0,0)
	curvefit/nthr=0/q line  cal_spec_peaks /X=spec_peaks /D
	wave w_coef
	wave wavelength = spec_dfr:wavelength
	wavelength = w_coef[1] * x + w_coef[0]
	save_data(wavelength, "pixis_wavelength", "calibrations")
end

function calibrate_spec(spec, cal_spec, cal_spec_wavelength)
	wave spec, cal_spec, cal_spec_wavelength
	find_peaks(spec, cal_spec, cal_spec_wavelength)
	calibrate_peaks(spec)
end