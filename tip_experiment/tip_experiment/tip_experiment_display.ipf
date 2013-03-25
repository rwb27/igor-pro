#pragma modulename = tip_exp_display
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

static strconstant gv_folder = "root:global_variables:tip_experiment"

function make_axis_wave(w, wname)
	// function by MH
	wave w
	string wname
	dfref w_df = getwavesdatafolderdfr(w)
	make/o/n=(numpnts(w)) w_df:$wname
	wave/sdfr=w_df w_ax = $wname
	w_ax = w[p]//0.5*(w[p+1] + w[p])
	insertpoints 0,1, w_ax							// Amend first point
	w_ax[0] = 2*w[0] - w[1]
	//w_ax[numpnts(w_ax) - 1] = 2*w[numpnts(w) - 1] - w_ax[numpnts(w_ax)  -2]	// Amend final point
	return 0
end

static function display_scan(scan_folder)
	dfref scan_folder
	dfref spec_path = root:oo:globalvariables
	nvar/sdfr=spec_path numspectrometers
	nvar/sdfr=$gv_folder dual_pol_meas
	
	// load necessary waves
	wave/sdfr=scan_folder steps
	wave/sdfr=scan_folder displacement
	wave/sdfr=scan_folder current
	wave/sdfr=scan_folder voltage
	wave/sdfr=scan_folder psd_x
	wave/sdfr=scan_folder psd_y
	//wave/sdfr=scan_folder psd_x_stdev
	//wave/sdfr=scan_folder psd_y_stdev
	wave/sdfr=scan_folder spec2d
	wave/sdfr=scan_folder wavelength
	if (numspectrometers == 2 || (numspectrometers == 1 && dual_pol_meas == 1))
		wave/sdfr=scan_folder spec2d_t
		wave/sdfr=scan_folder wavelength_t
	endif
	
	// make image axes
	make_axis_wave(wavelength, "wavelength_ax")
	wave/sdfr=scan_folder wavelength_ax
	//make_axis_wave(steps, "steps_ax")
	//wave/sdfr=scan_folder steps_ax
	if (numspectrometers == 2 || (numspectrometers == 1 && dual_pol_meas == 1))
		make_axis_wave(wavelength_t, "wavelength_ax_t")
		wave/sdfr=scan_folder wavelength_ax_t
	endif
	
	dowindow/k tip_exp_data
	display/n=tip_exp_data
	showtools/a; showinfo
	
	// define image sizes
	variable image_width = 250, image_length = 400
	variable extra_width = 250, extra_length = 400
	variable spacer = 20
	
	// change figure size
	modifygraph width = extra_width + image_width - spacer, height = image_length
	
	// append spectra
	display/w=(extra_width-spacer, 0, extra_width+image_width-spacer, image_length)/host=#; renamewindow #, g0
	appendimage spec2d vs {wavelength_ax, *}
	label bottom "wavelength (\\u)"; label left "step"
	modifyimage spec2d ctab= {*,*,geo,0}, ctabAutoscale=1
	setaxis bottom 450e-9,950e-9
	//modifygraph swapxy=1
	modifygraph freepos=0, lblposmode=2
	modifygraph mirror=1, minor=1, fsize=9, btlen=4, stlen=2
	setactivesubwindow ##
	
	// append transverse spectra
	if (numspectrometers == 2 || (numspectrometers == 1 && dual_pol_meas == 1))
		modifygraph width = extra_width + 2*image_width - 2*spacer
		display/w=(extra_width+image_width-2*spacer, 0, extra_width+2*image_width-2*spacer, image_length)/host=#; renamewindow #, g1
		appendimage spec2d_t vs {wavelength_ax_t, *}
		label bottom "wavelength (\\u)"; label left "step"
		modifyimage spec2d_t ctab= {*,*,geo,0}, ctabAutoscale=1
		setaxis bottom 450e-9,950e-9
		//modifygraph swapxy=1
		modifygraph freepos=0, lblposmode=2
		modifygraph mirror=1, minor=1, fsize=9, btlen=4, stlen=2
		setactivesubwindow ##
	endif
	
	// append extra information
	display/w=(0, 0, extra_width, extra_length)/host=#; renamewindow #, g2
	appendtograph/l=disp displacement
	appendtograph/l=force_l psd_y
	appendtograph/r=force_r psd_x
	appendtograph/l=smu current
	modifygraph rgb(displacement)=(0,0,0)
	modifygraph mode(current)=3, marker(current)=8, msize(current)=1.2, rgb(current)=(0,0,0)
	modifygraph mode(psd_x)=3, marker(psd_x)=8, msize(psd_x)=1.2, rgb(psd_x)=(0,0,65280)
	modifygraph mode(psd_y)=3, marker(psd_y)=8, msize(psd_y)=1.2, rgb(psd_y)=(65280,0,0)
	label bottom "step"; label disp "displacement (\\u)"
	label force_l "\s(psd_y) y_psd (\\u)"; label force_r "\s(psd_x) x_psd (\\u)"; label smu "current (\\u)"
	modifygraph freepos=0, lblposmode=2
	modifygraph mirror=1, mirror(force_l)=0, mirror(force_r)=0
	modifygraph minor=1, fsize=9, btlen=4, stlen=2
	modifygraph axisenab(disp)={0.8, 1.0}, axisenab(smu)={0.0, 0.4}
	modifygraph axisenab(force_l)={0.4, 0.8}, axisenab(force_r)={0.4, 0.8}
	setaxis/a
	modifygraph swapxy=1
	setactivesubwindow ##
end