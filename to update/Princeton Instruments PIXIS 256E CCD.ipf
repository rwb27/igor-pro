#pragma rtGlobals=1		// Use modern global access method.
#include "General Functions"

//exe_path = home + PIXIS folder + image.raw
//image_path = home +PIXIS folder + exe file

function testPIXIS()
	openDSO()
	variable t = 60
	checkfolder("root:PIXIS_256E:data")
	string dataname = "root:PIXIS_256E:data:t_"
	do
		cmdDSO(":SINGle")
		readyPIXIS(70)
		sleep/s t
		cmdDSO(":TRIGger:FORCe")
		sleep/s 1
		readPIXIS()
		duplicate/o root:PIXIS_256E:current:image, $(dataname+num2str(t))
		doupdate
		t += 60
	while (t < 10 * 60)
	closeDSO()
end

// BASIC COMMANDS //

function initPIXIS()
	checkfolder("root:PIXIS_256E")
	checkfolder("root:PIXIS_256E:current")
	checkfolder("root:PIXIS_256E:calibration")
	getfilefolderinfo/p=home/q/z "PIXIS_256E"
	string/g root:PIXIS_256E:pixis_path = S_Path
	if (waveexists(root:PIXIS_256E:calibration:W_coef))
		loadcalibrationPIXIS()
	endif
end

function resetPIXIS(hCam)
	variable hCam
	executescripttext/B/W=0.01/Z "c:\\users\\hera\\as2180\\pixis_256e\\reset_kinetics.exe -h "+num2str(hCam)
end

function readyPIXIS(exp_time)
	variable exp_time
	variable/g root:PIXIS_256E:current:exp_time = exp_time
	executescripttext/B/W=0.01/Z "c:\\users\\hera\\as2180\\pixis_256e\\kinetics.exe -t "+num2str(exp_time)
end

function readPIXIS()
	svar pixis_path = root:PIXIS_256E:pixis_path
	//GBLoadWave/Q/O/N=temp/T={80,80}/W=1/B pixis_path+"Image.raw"
	GBLoadWave/Q/O/N=temp/T={80,80}/W=1/B "C:Users:Hera:as2180:PIXIS_256E:Image.raw"
	redimension/n=(1024,256) temp0
	duplicate/o temp0, root:PIXIS_256E:current:image
	killwaves temp0
	duplicate/o root:PIXIS_256E:current:image, root:PIXIS_256E:current:image_raw
	scalekineticsPIXIS()
	correctPIXIS()
	if (waveexists(root:PIXIS_256E:current:bkgd_image) && waveexists(root:PIXIS_256E:current:ref_image))
		normaliseimagePIXIS()
	endif
end

function displayPIXIS()
	dowindow/k pixis
	display/n=pixis
	appendimage/w=pixis root:PIXIS_256E:current:image
	modifyimage image ctab= {*,*,Geo,0}, ctabAutoscale=1,lookup= $""
	label left "Wavelength (\\U)"; label bottom "Time (\\U)"	
end

function imagePIXIS(exp_time)
	variable exp_time
	variable/g root:PIXIS_256E:current:exp_time = exp_time
	//executescripttext/B/W=0.01/Z "c:\\users\\hera\\as2180\\pixis_256e\\init_kinetics.exe -t "+num2str(exp_time)
	executescripttext/B "c:\\users\\hera\\as2180\\pixis_256e\\init_kinetics.exe -t "+num2str(exp_time)
	readPIXIS()
end

function scalekineticsPIXIS()
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

function correctPIXIS()
	wave image = root:PIXIS_256E:current:image
	deletepoints/M=0 250, 6, image
	image[0,4][] = 530
end

// BACKGROUND / REFERENCE ACQUISITION //

function readbkgdPIXIS(exp_time)
	variable exp_time
	imagePIXIS(exp_time)
	duplicate/o root:PIXIS_256E:current:image, root:PIXIS_256E:current:bkgd_image
	// Automatic creation of background spectrum
	wave bkgd_image = root:PIXIS_256E:current:bkgd_image
	averagepixis(bkgd_image, dimsize(bkgd_image,0))
	make/o/n=(dimsize(bkgd_image,1)) root:PIXIS_256E:current:bkgd
	wave bkgd = root:PIXIS_256E:current:bkgd
	bkgd[]=bkgd_image[250][p]
end

function readrefPIXIS(exp_time)
	variable exp_time
	imagePIXIS(exp_time)
	duplicate/o root:PIXIS_256E:current:image, root:PIXIS_256E:current:ref_image
	// Automatic creation of reference spectrum
	wave ref_image = root:PIXIS_256E:current:ref_image
	averagepixis(ref_image, dimsize(ref_image,0))
	make/o/n=(dimsize(ref_image,1)) root:PIXIS_256E:current:ref
	wave ref = root:PIXIS_256E:current:ref
	ref[]=ref_image[250][p]
end

function averagePIXIS(image,rows)
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
	wave image = root:PIXIS_256E:current:image
	wave bkgd = root:PIXIS_256E:current:bkgd_image
	wave ref = root:PIXIS_256E:current:ref_image
	duplicate/o image, root:PIXIS_256E:current:image_raw
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

// PANEL //

//Menu

Function imageButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			nvar exp_time = root:PIXIS_256E:current:exp_time
			imagePIXIS(exp_time)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function liveButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			//live code
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function armButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			nvar exp_time = root:PIXIS_256E:current:exp_time
			readyPIXIS(exp_time)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function readButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			readPIXIS()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function getBkgdButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			nvar exp_time = root:PIXIS_256E:current:exp_time
			readbkgdPIXIS(exp_time)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function getRefButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			nvar exp_time = root:PIXIS_256E:current:exp_time
			readrefPIXIS(exp_time)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function clearBkgdButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			killwaves root:PIXIS_256E:current:bkgd_image, root:PIXIS_256E:current:bkgd
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function clearRefButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			killwaves root:PIXIS_256E:current:ref_image, root:PIXIS_256E:current:ref
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Window PIXIS256E() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(436,112,933,456) as "PIXIS 256E"
	ModifyPanel frameStyle=1
	ShowTools/A
	Button image,pos={4,3},size={50,20},proc=imageButton,title="Image",fSize=11
	Button live,pos={55,4},size={50,20},proc=liveButton,title="Live",fSize=11
	SetVariable setexp,pos={106,6},size={134,16},bodyWidth=60,title="Exposure Time"
	SetVariable setexp,fSize=11
	SetVariable setexp,limits={0,1000,1},value= root:PIXIS_256E:current:exp_time
	Button getBkgd,pos={6,25},size={90,20},proc=getBkgdButton,title="Get Background"
	Button getBkgd,fSize=11
	Button getRef,pos={107,26},size={90,20},proc=getRefButton,title="Get Reference"
	Button getRef,fSize=11
	Button clearBkgd,pos={6,45},size={100,20},proc=clearBkgdButton,title="Clear Background"
	Button clearBkgd,fSize=11
	Button clearRef,pos={107,46},size={100,20},proc=clearRefButton,title="Clear Reference"
	Button clearRef,fSize=11
	Button arm,pos={217,47},size={50,20},proc=armButton,title="Arm",fSize=11
	Button read,pos={269,46},size={50,20},proc=readButton,title="Read",fSize=11
	Display/W=(8,70,491,336)/HOST=# 
	AppendImage :PIXIS_256E:current:Image
	ModifyImage Image ctab= {*,*,Geo,0}
	ModifyImage Image ctabAutoscale=1
	ModifyGraph frameStyle=1
	ModifyGraph mirror=2
	Label left "Wavelength (\\U)"
	Label bottom "Time (\\U)"
	RenameWindow #,G0
	SetActiveSubwindow ##
EndMacro
