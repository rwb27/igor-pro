#pragma modulename = tip_exp_display
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

static strconstant gv_folder = "root:global_variables:tip_experiments"

function make_axis_wave(w, wname)
	// function by MH
	wave w
	string wname
	dfref w_df = getwavesdatafolderdfr(w)
	make/o/n=(numpnts(w)) w_df:$wname
	wave/sdfr=w_df w_ax = $wname
	w_ax = 0.5*(w[p+1] + w[p])
	insertpoints 0,1, w_ax							// Amend first point
	w_ax[0] = 2*w[0] - w_ax[1]
	w_ax[numpnts(w_ax) - 1] = 2*w[numpnts(w) - 1] - w_ax[numpnts(w_ax)  -2]	// Amend final point
	return 0
end

static function display_scan(scan_folder)
	dfref scan_folder
	nvar num_spectrometers
	
	// load necessary waves
	wave/sdfr=scan_folder steps
	wave/sdfr=scan_folder displacement
	wave/sdfr=scan_folder current
	wave/sdfr=scan_folder voltage
	wave/sdfr=scan_folder psd_x
	wave/sdfr=scan_folder psd_y
	wave/sdfr=scan_folder psd_x_stdev
	wave/sdfr=scan_folder psd_y_stdev
	wave/sdfr=scan_folder spec2d
	if (num_spectrometers == 2)
		wave/sdfr=scan_folder spec2d_t
	endif
	
	// make image axes
	wave/sdfr=scan_folder wavelength
	make_axis_wave(wavelength, "wavelength_ax")
	wave/sdfr=scan_folder wavelength_ax
	make_axis_wave(steps, "steps_ax")
	wave/sdfr=scan_folder steps_ax
	
	dowindow/k tip_exp_data
	display/n=tip_exp_data
	
	// append all necessary traces
	appendtograph/l=disp displacement
	appendtograph/l=force_l psd_y
	appendtograph/r=force_r psd_x
	appendtograph/l=smu current
	appendimage spec2d vs {*, wavelength_ax}
	
	// organise trace position
	modifygraph axisenab(left)={0.3, 0.7}, axisenab(disp)={0, 0.1}, axisenab(smu)={0.1, 0.29}
	modifygraph axisenab(force_l)={0.71, 1}, axisenab(force_r)={0.71, 1}
	
	// change figure size
	modifygraph width = 300, height = {aspect, 2}
end