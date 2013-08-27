#pragma ModuleName = hyperspec
#pragma version = 6.23
#pragma rtGlobals=3		// Use modern global access method.

#include "data_handling"
#include "pi_pi733_3cd_stage"
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
	
	// prepare scan preview
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
	
	// begin scan
	variable q1, q2
	do
		pos_a = init_a - scan_size/2							// reset A position
		pi_stage#move("A", pos_a); sleep/s move_delay			// move to right
		q1 = 0												// reset A counter
		
		pi_stage#move("B", pos_b); sleep/s move_delay
		do
			if(getkeystate(0) & 32)								// check for user abort (escape key)
				pi_stage#move("A", init_a); sleep/s move_delay
				pi_stage#move("B", init_b); sleep/s move_delay
				abort "user abort"
			endif
			// move to location and take spectra
			pi_stage#move("A", pos_a); sleep/s move_delay
			OO_read()
			// save spectra
			wave w=root:oo:data:current:spectra				// declare spectrum wave
			hs_data[q1][q2][] = w[r]
			
			if (num_spectrometers == 2)
				wave w=root:oo:data:current:spectra_2				// declare spectrum wave
				hs_data_t[q1][q2][] = w[r]
			endif
								
			doupdate
								
			pos_a += scan_step								// increment grid (a) position	
			q1 += 1											// increment counter
		while(q1 <= (scan_size/scan_step))
		
		pos_b += scan_step									// increment grid (b) position
		q2 += 1												// reset B counter
	while(q2 <= (scan_size/scan_step))
	
	pi_stage#move("A", init_a); sleep/s move_delay							// move to initial position
	pi_stage#move("B", init_b); sleep/s move_delay
	pi_stage#close_comms()
end

static function scan_newport(scan_size, scan_step)
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
	
	// prepare scan preview
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
	
	// get current pz positions
	actuators#open_comms()
	variable init_a = actuators#get_pos("x")
	variable init_b = actuators#get_pos("y")
	variable init_c = actuators#get_pos("z")
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
	
	// begin scan
	variable q1, q2
	do
		pos_a = init_a - scan_size/2							// reset A position
		actuators#move("x", pos_a); sleep/s move_delay			// move to right
		q1 = 0												// reset A counter
		
		actuators#move("y", pos_b); sleep/s move_delay
		do
			if(getkeystate(0) & 32)								// check for user abort (escape key)
				actuators#move("x", init_a); sleep/s move_delay
				actuators#move("y", init_b); sleep/s move_delay
				abort "user abort"
			endif
			// move to location and take spectra
			actuators#move("x", pos_a); sleep/s move_delay
			OO_read()
			// save spectra
			wave w=root:oo:data:current:spectra				// declare spectrum wave
			hs_data[q1][q2][] = w[r]
			
			if (num_spectrometers == 2)
				wave w=root:oo:data:current:spectra_2				// declare spectrum wave
				hs_data_t[q1][q2][] = w[r]
			endif
								
			doupdate
								
			pos_a += scan_step								// increment grid (a) position	
			q1 += 1											// increment counter
		while(q1 <= (scan_size/scan_step))
		
		pos_b += scan_step									// increment grid (b) position
		q2 += 1												// reset B counter
	while(q2 <= (scan_size/scan_step))
	
	actuators#move("x", init_a); sleep/s move_delay							// move to initial position
	actuators#move("y", init_b); sleep/s move_delay
	actuators#close_comms()
end