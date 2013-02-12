#pragma rtGlobals=1		// Use modern global access method.
//
// v2, 12/02/13, AS
//

strconstant kinetics = "c:\\users\\hera\\desktop\\tip_exp\\pixis_256e\\kinetics.exe"
strconstant init_kinetics = "c:\\users\\hera\\desktop\\tip_exp\\pixis_256e\\init_kinetics.exe"
strconstant reset_kinetics = "c:\\users\\hera\\desktop\\tip_exp\\pixis_256e\\reset_kinetics.exe"
strconstant gv_folder = "root:global_variables:princeton_inst_pixis_256e"

function check_folder_pixis(data_folder)
	string data_folder
	if (!datafolderexists(data_folder))
		newdatafolder $data_folder
	endif
end

function init_pixis()
	string data_folder = "root:global_variables"
	check_folder_pixis(data_folder)
	//data_folder += ":princeton_instruments_pixis_256e_ccd"
	//check_folder_pixis(data_folder)
	check_folder_pixis(gv_folder)
	check_folder_pixis("root:pixis_256e")
	check_folder_pixis("root:pixis_256e:current")
	check_folder_pixis("root:pixis_256e:calibration")
	check_folder_pixis("root:pixis_256e:data")
	getfilefolderinfo/p=home/q/z "pixis_256e"
	string/g $(gv_folder + ":pixis_path") = S_Path
	if (waveexists(root:pixis_256e:calibration:W_coef))
		//load_calibration_pixis()
	endif
end

// control functions

function reset_pixis(hCam)
	variable hCam
	executescripttext/b/w=0.01/z reset_kinetics + " -h " + num2str(hCam)
end

function ready_pixis(exp_time)
	variable exp_time
	variable/g root:pixis_256e:current:exp_time = exp_time
	executescripttext/B/W=0.01/Z kinetics + " -t " + num2str(exp_time)
end

function read_pixis()
	svar pixis_path = root:PIXIS_256E:pixis_path
	GBLoadWave/Q/O/N=temp/T={80,80}/W=1/B pixis_path + "image.raw"
	//GBLoadWave/Q/O/N=temp/T={80,80}/W=1/B "C:Users:Hera:Desktop:Tip_Exp:pixis_256e:image.raw"
	redimension/n=(1024,256) temp0
	duplicate/o temp0, root:pixis_256e:current:image
	killwaves temp0
	duplicate/o root:PIXIS_256E:current:image, root:pixis_256e:current:image_raw
	scale_kinetics_pixis()
	correct_pixis()
	if (waveexists(root:PIXIS_256E:current:bkgd_image) && waveexists(root:PIXIS_256E:current:ref_image))
		//normaliseimagePIXIS()
	endif
end

function display_pixis()
	dowindow/k pixis
	display/n=pixis
	appendimage/w=pixis root:pixis_256e:current:image
	modifyimage image ctab= {*,*,Geo,0}, ctabAutoscale=1,lookup= $""
	label left "wavelength (\\U)"; label bottom "time (\\U)"	
end

function image_pixis(exp_time)
	variable exp_time
	variable/g root:PIXIS_256E:current:exp_time = exp_time
	executescripttext/B init_kinetics + " -t " + num2str(exp_time)
	read_pixis()
end

function scale_kinetics_pixis()
	wave image = root:PIXIS_256E:current:image
	//ImageRotate/O/V image
	matrixtranspose image
	nvar exp_time = root:PIXIS_256E:current:exp_time
	variable shiftrate = 9.2e-6, windowsize = 1
	variable resolution = (exp_time*1e-6 + shiftrate)/windowsize
	setscale/P x, 0, resolution, "s", image
	if (waveexists(root:PIXIS_256E:current:wavelength))
		wave wavelength = root:PIXIS_256E:current:wavelength
		setscale/i y, wavelength[0], wavelength[numpnts(wavelength)-2], "m", image
	endif
end

function correct_pixis()
	wave image = root:PIXIS_256E:current:image
	deletepoints/M=0 250, 6, image
	image[0,4][] = 530
end