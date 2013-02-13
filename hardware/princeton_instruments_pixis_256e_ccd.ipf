#pragma IndependentModule = pixis
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

strconstant gv_folder = "root:global_variables:pi_pi733_3cd_stage"

strconstant kinetics = "c:\\users\\hera\\desktop\\tip_exp\\pixis_256e\\kinetics.exe"
strconstant init_kinetics = "c:\\users\\hera\\desktop\\tip_exp\\pixis_256e\\init_kinetics.exe"
strconstant reset_kinetics = "c:\\users\\hera\\desktop\\tip_exp\\pixis_256e\\reset_kinetics.exe"

strconstant current_folder = "root:pixis_256e:current"
strconstant calibration_folder = "root:pixis_256e:calibration"
strconstant data_folder = "root:pixis_256e:data"

function check_folder_pixis(data_folder)
	string data_folder
	if (!datafolderexists(data_folder))
		newdatafolder $data_folder
	endif
end

function initialise()
	string gvs = "root:global_variables"
	check_folder_pixis(gvs)
	check_folder_pixis(gv_folder)
	check_folder_pixis("root:pixis_256e")
	check_folder_pixis(current_folder)
	check_folder_pixis(calibration_folder)
	check_folder_pixis(data_folder)
	
	getfilefolderinfo/p=home/q/z "pixis_256e"
	string/g $(gv_folder + ":pixis_path") = S_Path
	if (waveexists(root:pixis_256e:calibration:W_coef))
		//load_calibration_pixis()
	endif
end

function reset(hCam)
	variable hCam
	executescripttext/b/w=0.01/z reset_kinetics + " -h " + num2str(hCam)
end

function ready(exp_time)
	variable exp_time
	variable/g root:pixis_256e:current:exp_time = exp_time
	executescripttext/B/W=0.01/Z kinetics + " -t " + num2str(exp_time)
end

function read()
	svar pixis_path = root:PIXIS_256E:pixis_path
	GBLoadWave/Q/O/N=temp/T={80,80}/W=1/B pixis_path + "image.raw"
	//GBLoadWave/Q/O/N=temp/T={80,80}/W=1/B "C:Users:Hera:Desktop:Tip_Exp:pixis_256e:image.raw"
	redimension/n=(1024,256) temp0
	duplicate/o temp0, $(current_folder + ":image")
	killwaves temp0
	duplicate/o $(current_folder + ":image"), $(current_folder + ":image_raw")
	scale_kinetics()
	correct_pixis()
	if (waveexists($(current_folder + ":bkgd_image")) && waveexists($(current_folder + ":ref_image")))
		//normaliseimagePIXIS()
	endif
end

function display_image()
	dowindow/k pixis
	display/n=pixis
	appendimage/w=pixis $(current_folder + ":image")
	modifyimage image ctab= {*,*,Geo,0}, ctabAutoscale=1, lookup= $""
	label left "wavelength (\\U)"; label bottom "time (\\U)"	
end

function image(exp_time)
	variable exp_time
	variable/g $(gv_folder + ":exp_time") = exp_time
	executescripttext/B init_kinetics + " -t " + num2str(exp_time)
	read()
end

function scale_kinetics()
	wave image = $(current_folder + ":image")
	//ImageRotate/O/V image
	matrixtranspose image
	nvar exp_time = $(gv_folder + ":exp_time")
	variable shiftrate = 9.2e-6, windowsize = 1
	variable resolution = (exp_time*1e-6 + shiftrate)/windowsize
	setscale/P x, 0, resolution, "s", image
	if (waveexists($(current_folder + ":wavelength")))
		wave wavelength = $(current_folder + ":wavelength")
		setscale/i y, wavelength[0], wavelength[numpnts(wavelength)-2], "m", image
	endif
end

function correct_pixis()
	wave image = $(current_folder + ":image")
	deletepoints/M=0 250, 6, image
	image[0,4][] = 530
end

// BACKGROUND / REFERENCE ACQUISITION //

function read_bkgd(exp_time)
	variable exp_time
	image(exp_time)
	duplicate/o $(current_folder + ":image"), $(current_folder + ":bkgd_image")
	// Automatic creation of background spectrum
	wave bkgd_image = $(current_folder + ":bkgd_image")
	average(bkgd_image, dimsize(bkgd_image,0))
	make/o/n=(dimsize(bkgd_image,1)) $(current_folder + ":bkgd")
	wave bkgd = $(current_folder + ":bkgd")
	bkgd[]=bkgd_image[250][p]
end

function read_ref(exp_time)
	variable exp_time
	image(exp_time)
	duplicate/o $(current_folder + ":image"), $(current_folder + ":ref_image")
	// Automatic creation of reference spectrum
	wave ref_image = $(current_folder + ":ref_image")
	average(ref_image, dimsize(ref_image,0))
	make/o/n=(dimsize(ref_image,1)) $(current_folder + ":ref")
	wave ref = $(current_folder + ":ref")
	ref[]=ref_image[250][p]
end

function average(image, rows)
	wave image
	variable rows
	redimension/s image
	variable j, k
	make/free/o/n=(dimsize(image, 1)) temp = 0
	for (j = 0; j < dimsize(image,0); j += rows)
		k = 0
		do
			temp[] += image[j+k][p]
			k += 1
		while (k < rows)
		temp /= rows
		k = 0
		do
			image[j+k][] = temp[q]
			k += 1
		while (k < rows)
		temp = 0
	endfor
end

// REFERENCE NORMALISATION //

function normaliseimagePIXIS()
	wave image = $(current_folder + ":image")
	wave bkgd = $(current_folder + ":bkgd_image")
	wave ref = $(current_folder + ":ref_image")
	redimension/s image; redimension/s bkgd; redimension/s ref
	
	duplicate/free ref, t_ref
	image -= bkgd
	t_ref -= bkgd
	image /= t_ref
	
	if (0)
		variable j, k
		for (j = 0; j < dimsize(image,0); j += 1)
			for (k = 0; k < dimsize(image,1); k += 1)
				image[j][k] -= bkgd[k]
				image[j][k] /= (ref[k]-bkgd[k])
			endfor
		endfor
	endif
end

// CALIBRATION FUNCTIONS //

function createcalibrationPIXIS()
	if (!waveexists(root:'Princeton Instruments PIXIS':Calibration:SpecCal))
		abort "Load Spectrum Calibration"
	endif
	if (waveexists(root:'Princeton Instruments PIXIS':Calibration:exp_peaks) && waveexists(root:'Princeton Instruments PIXIS':Calibration:cal_peaks))
		Wave exp_peaks=root:'Princeton Instruments PIXIS':Calibration:exp_peaks
		Wave cal_peaks=root:'Princeton Instruments PIXIS':Calibration:cal_peaks
		Make/O/N=(numpnts(cal_peaks)) root:'Princeton Instruments PIXIS':Calibration:wl_peaks
		Wave wl_peaks=root:'Princeton Instruments PIXIS':Calibration:wl_peaks
		Wave wl_wave=root:'Princeton Instruments PIXIS':Calibration:wl_wave
		variable i
		for(i=0;i<numpnts(cal_peaks);i+=1)
			wl_peaks[i]=wl_wave[cal_peaks[i]]
		endfor
		CurveFit/Q poly 3, wl_peaks /X=exp_peaks /D
	else
		string error=""
		if (!waveexists(root:'Princeton Instruments PIXIS':Calibration:cal_peaks))
			make/o/n=0 root:'Princeton Instruments PIXIS':Calibration:cal_peaks
			error+="Enter Calibration Peaks\n"
		endif
		if (!waveexists(root:'Princeton Instruments PIXIS':Calibration:exp_peaks))
			make/o/n=0 root:'Princeton Instruments PIXIS':Calibration:exp_peaks
			error+="Enter Experiment Peaks\n"
		endif
		abort error
	endif
end

function loadcalibrationPIXIS()
	wave image = root:PIXIS_256E:current:image	
	make/o/n=(dimsize(image,1)+1) root:PIXIS_256E:current:wavelength
	wave wavelength = root:PIXIS_256E:current:wavelength
	wave W_coef = root:PIXIS_256E:calibration:W_coef
	variable i = 0
	do
		wavelength[i]  =(W_coef[1]*i) + W_coef[0]
		i += 1
	while (i < numpnts(wavelength))
	wavelength *= 1e-9
	setscale d 0,0,"m", wavelength
end