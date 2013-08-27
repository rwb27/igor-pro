#pragma ModuleName = hyperspec
#pragma version = 6.23
#pragma rtGlobals=3		// Use modern global access method.

#include "data_handling"
#include "pi_pi733_3cd_stage"
#include "grid_scanning"
#include "analysis_tools"
#include "OO spectrometer v4.23"
#include "newport_actuators"

static strconstant gv_folder = "root:global_variables:hyperspectral_imaging"

static function initialise()
	data#check_folder("root:global_variables")
	data#check_folder(gv_folder)
	variable/g $(gv_folder + ":wavelength") = 0
	string/g $(gv_folder + ":image")
end

static function scan_function(i, j)
	variable i, j
	oo_read()
	nvar/sdfr=root: num_spectrometers
	svar sf = $(gv_folder + ":current_scan_folder")
	wave/sdfr=df hs_data = hyperspec_image
	wave w=root:oo:data:current:spectra				// declare spectrum wave
	hs_data[q1][q2][] = w[r]
	if (num_spectrometers == 2)
		wave/sdfr=df hs_data_t = hyperspec_image_t
		wave/sdfr=sf w=root:oo:data:current:spectra_2				// declare spectrum wave
		hs_data_t[q1][q2][] = w[r]
	endif
end

static function scan(scan_size, scan_step)
	// perform a spectral scan to obtain a hyperspectral image. //
	variable scan_size, scan_step
	data#check_folder("root:global_variables")
	data#check_folder(gv_folder)
	string data_folder = data#check_data_folder()
	string scan_folder = data#new_data_folder(data_folder + ":hyperspec_image_")
	string/g $(gv_folder + ":current_scan_folder") = scan_folder
	
	// make hyperspectral image array
	duplicate/o root:oo:data:current:wl_wave, $(scan_folder + ":wavelength")
	wave wavelength = $(scan_folder + ":wavelength")
	variable image_size = scan_size/scan_step + 1
	make/o/n=(image_size, image_size, numpnts(wavelength)) $(scan_folder + ":hyperspec_image")
	wave hs_data = $(scan_folder + ":hyperspec_image")
	hs_data = 0
	nvar num_spectrometers
	if (num_spectrometers == 2)
		make/o/n=(image_size, image_size, numpnts(wavelength)) $(scan_folder + ":hyperspec_image_t")
		wave hs_data_t = $(scan_folder + ":hyperspec_image_t")
		hs_data_t = 0
	endif
	
	display_scan(sf)
	
	// get current pz positions
	pi_stage#open_comms()
	variable init_a = pi_stage#get_pos_ch("a")
	variable init_b = pi_stage#get_pos_ch("b")
	variable init_c = pi_stage#get_pos_ch("c")
	variable move_delay = 0.1//0.05
	
	// move to initial position
	variable pos_a = init_a - scan_size/2
	variable pos_b = init_b - scan_size/2
	setscale/p x pos_a, scan_step, hs_data
	setscale/p y pos_b, scan_step, hs_data
	if (num_spectrometers == 2)
		setscale/p x pos_a, scan_step, hs_data_t
		setscale/p y pos_b, scan_step, hs_data_t
	endif
	
	grid_scan#scan_grid("a", "b", scan_size, scan_step, scan_function)
end

static function display_scan(sf)
	dfref sf
	wave/sdfr=sf hs_data = hyperspec_image
	nvar/sdfr=root: num_spectrometers
	if (num_spectrometers)
		wave/sdfr=sf hs_data_t = hyperspec_image_t
	endif
	variable wavelength_1 = wavelength_to_index(wavelength, 520)
	variable wavelength_2 = wavelength_to_index(wavelength, 633)
	variable/g $(gv_folder + ":wavelength_1") = wavelength_1
	variable/g $(gv_folder + ":wavelength_2") = wavelength_2
	
	dowindow/k hyperspectral_image
	display/n=hyperspectral_image
	appendimage hs_data; modifyimage ''#0 plane=wavelength_1
	appendimage/l=l2 hs_data; modifyimage ''#1 plane=wavelength_2
	modifygraph axisEnab(left)={0.51,1}, axisEnab(l2)={0,0.49}, freePos(l2)=0
	modifygraph width=250
	modifygraph height={aspect, 2}
	
	if (num_spectrometers == 2)
		appendimage/b=b1 hs_data_t; modifyimage ''#2 plane=wavelength_1
		appendimage/l=l2/b=b1 hs_data_t; modifyimage ''#3 plane=wavelength_2
		modifygraph axisEnab(bottom)={0, 0.45}, axisEnab(b1)={0.55, 1}
		modifygraph width=400
		modifygraph height={aspect, 1}
	endif
	
	modifygraph tick=2,mirror=1,fSize=11,standoff=0
	modifyimage ''#0 ctab= {*,*,ColdWarm,0}, ctabAutoscale=2,lookup= $""
	modifyimage ''#1 ctab= {*,*,ColdWarm,0}, ctabAutoscale=2,lookup= $""
	modifyimage ''#2 ctab= {*,*,ColdWarm,0}, ctabAutoscale=2,lookup= $""
	modifyimage ''#3 ctab= {*,*,ColdWarm,0}, ctabAutoscale=2,lookup= $""
end