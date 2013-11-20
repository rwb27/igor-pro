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
	nvar/z/sdfr=root:oo:globalvariables numspectrometers
	if (!nvar_exists(numspectrometers))
		nvar/sdfr=scan_folder numspectrometers
	endif
	nvar/sdfr=$gv_folder dual_pol_meas
	
	// load necessary waves
	wave/sdfr=scan_folder steps
	wave/sdfr=scan_folder displacement
	wave/sdfr=scan_folder current
	wave/sdfr=scan_folder conductance
	wave/sdfr=scan_folder psd_x
	wave/sdfr=scan_folder psd_y
	wave/sdfr=scan_folder spec2d
	wave/sdfr=scan_folder wavelength
	if (numspectrometers == 2)
		wave/sdfr=scan_folder spec2d_t
		wave/sdfr=scan_folder wavelength_t
	endif
	
	// make image axes
	make_axis_wave(wavelength, "wavelength_ax")
	wave/sdfr=scan_folder wavelength_ax
	setscale d, 0, 0, "m", wavelength_ax
	//make_axis_wave(steps, "steps_ax")
	//wave/sdfr=scan_folder steps_ax
	if (numspectrometers == 2)
		make_axis_wave(wavelength_t, "wavelength_ax_t")
		wave/sdfr=scan_folder wavelength_ax_t
		setscale d, 0, 0, "m", wavelength_ax_t
	endif
	
	dowindow/k tip_exp_data
	display/k=1/n=tip_exp_data
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
	if (numspectrometers == 2)
		modifygraph width = extra_width + 2*image_width - 2*spacer
		display/w=(extra_width+image_width-2*spacer, 0, extra_width+2*image_width-2*spacer, image_length)/host=#; renamewindow #, g1
		appendimage spec2d_t vs {wavelength_ax_t, *}
		label bottom "wavelength (\\U)"; label left "step"
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
	appendtograph/r=smu_g conductance
	modifygraph rgb(displacement)=(0,0,0)
	modifygraph mode(conductance)=3, marker(conductance)=8, msize(conductance)=1.2, rgb(conductance)=(0,0,0)
	modifygraph mode(current)=3, marker(current)=8, msize(current)=1.2, rgb(current)=(0,0,0)
	modifygraph mode(psd_x)=3, marker(psd_x)=8, msize(psd_x)=1.2, rgb(psd_x)=(0,0,65280)
	modifygraph mode(psd_y)=3, marker(psd_y)=8, msize(psd_y)=1.2, rgb(psd_y)=(65280,0,0)
	label bottom "step"; label disp "disp. (\\U)"
	label force_l "\s(psd_y) y_psd (\\U)"; label force_r "\s(psd_x) x_psd (\\U)"; label smu "current (\\U)"
	label smu_g "conductance (\\U)"
	modifygraph freepos=0, lblposmode=2
	modifygraph mirror=1, mirror(force_l)=0, mirror(force_r)=0
	modifygraph nticks(disp)=2
	modifygraph minor=1, fsize=8, btlen=4, stlen=2
	modifygraph axisenab(disp)={0.82, 1.0}, axisenab(smu)={0.0, 0.4}, axisenab(smu_g)={0.0, 0.4}
	modifygraph axisenab(force_l)={0.42, 0.8}, axisenab(force_r)={0.42, 0.8}
	setaxis/a
	modifygraph swapxy=1
	setactivesubwindow ##
end

function display_time_res_scan(scan_folder, i)
	dfref scan_folder
	variable i // instance
	
	scan_folder = scan_folder:time_resolved_data
	
	// load necessary waves
	wave/sdfr=scan_folder spec = $("qc_spec_"+num2str(i))
	wave/sdfr=scan_folder spec_wl = $("qc_spec_"+num2str(i))+"_wavelength"
	wave/sdfr=scan_folder spec_time = $("qc_spec_"+num2str(i)+"_time")
	wave/sdfr=scan_folder current = $("qc_trace_"+num2str(i))
	wave/sdfr=scan_folder conductance = $("qcg_trace_"+num2str(i))
	wave/sdfr=scan_folder qc_time = $("qc_trace_"+num2str(i)+"_time")
	wave/sdfr=scan_folder force = $("qc_force_"+num2str(i))
	wave/sdfr=scan_folder force_time = $("qc_force_"+num2str(i)+"_time")
	
	// make image axes
	//spec_wl *= 1e-9
	make_axis_wave(spec_wl, nameofwave(spec_wl)+"_ax")
	wave/sdfr=scan_folder spec_wl_ax = $(nameofwave(spec_wl)+"_ax")
	setscale d, 0, 0, "m", spec_wl_ax
	make_axis_wave(spec_time, nameofwave(spec_time)+"_ax")
	wave/sdfr=scan_folder spec_time_ax = $(nameofwave(spec_time)+"_ax")
	setscale d, 0, 0, "s", spec_time_ax
	
	dowindow/k tip_exp_data
	display/k=1/n=tip_exp_data
	showtools/a; showinfo
	
	// define image sizes
	variable image_width = 300, image_height = 200
	variable dso_width = 300, dso_height = 150
	variable spacer = 20
	
	// change figure size
	modifygraph width = image_width, height = image_height+dso_height+spacer
	
	// append spectra
	// left, top, right, bottom
	display/w=(0, 0, image_width, image_height)/host=#; renamewindow #, g0
	appendimage spec vs {spec_time_ax, spec_wl_ax}
	label left "wavelength (\\U)"; label bottom "time (\\U)"
	modifyimage ''#0 ctab= {*,*,geo,0}, ctabAutoscale=1
	//modifygraph swapxy=1
	modifygraph freepos=0, lblposmode=2
	modifygraph mirror=1, minor=1, fsize=9, btlen=4, stlen=2
	setactivesubwindow ##
	
	// append extra information
	display/w=(0, image_height, dso_width, image_height+dso_height+spacer)/host=#; renamewindow #, g2
	appendtograph/l conductance vs qc_time
	appendtograph/r force vs force_time
	reordertraces ''#0,{''#1}
	modifygraph rgb(''#0)=(0,0,0)
	
	//modifygraph mode(conductance)=3, marker(conductance)=8, msize(conductance)=1.2, rgb(conductance)=(0,0,0)
	//modifygraph mode(current)=3, marker(current)=8, msize(current)=1.2, rgb(current)=(0,0,0)
	//modifygraph mode(psd_x)=3, marker(psd_x)=8, msize(psd_x)=1.2, rgb(psd_x)=(0,0,65280)
	//modifygraph mode(psd_y)=3, marker(psd_y)=8, msize(psd_y)=1.2, rgb(psd_y)=(65280,0,0)
	label bottom "time (\\U)"; label left "conductance (\\U)"; label right "force (\\U)"
	
	modifygraph freepos=0, lblposmode=2
	modifygraph mirror=1
	modifygraph minor=1, fsize=8, btlen=4, stlen=2
	setaxis/a=2 left; setaxis/a=2 right
	setactivesubwindow ##
end