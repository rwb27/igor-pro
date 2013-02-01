#pragma rtGlobals=1		// Use modern global access method.

function displayspec(i)
	variable i
	nvar upper_i
	wave frequency = root:analysis:frequency
	wave spec = $("root:analysis:spec_fit_params:spec_"+num2str(i))
	wave spec_fit = $("root:analysis:spec_fit_params:spec_fit_"+num2str(i))
	wave mode_1 = $("root:analysis:spec_fit_params:spec_fit_mode1_"+num2str(i))
	wave mode_2 = $("root:analysis:spec_fit_params:spec_fit_mode2_"+num2str(i))
	wave mode_3 = $("root:analysis:spec_fit_params:spec_fit_mode3_"+num2str(i))
	wave mode_4 = $("root:analysis:spec_fit_params:spec_fit_mode4_"+num2str(i))
	wave mode_5 = $("root:analysis:spec_fit_params:spec_fit_mode5_"+num2str(i))
	wave bkgd = $("root:analysis:spec_fit_params:spec_fit_bkgd_"+num2str(i))
	
	dowindow/k spec_info
	display/n=spec_info
	appendtograph spec vs frequency
	setaxis/a=2 left
	setaxis bottom 1.2, 2.7
	modifygraph rgb[0]=(0,0,0)
	appendtograph spec_fit vs frequency
	appendtograph mode_1 vs frequency
	appendtograph mode_2 vs frequency
	appendtograph mode_3 vs frequency
	appendtograph mode_4 vs frequency
	appendtograph mode_5 vs frequency
	appendtograph bkgd vs frequency
	modifygraph rgb[2]=(0,43520,65280), rgb[3]=(0,15872,65280), rgb[4]=(0,0,39168)
	modifygraph rgb[5]=(65280,43520,0)
	modifygraph rgb[6]=(32768,65280,0)
	
	wave spec_params = $("root:analysis:spec_fit_params:spec_params_"+num2str(i))
	make/o/n=(dimsize(spec_params,0)) half_max
	half_max = spec_params[p][1] / 2
	appendtograph half_max vs spec_params[][0]
	modifygraph mode(half_max)=3,marker(half_max)=8, rgb(half_max)=(0,0,0)
	errorbars half_max X,wave=(spec_params[*][2],spec_params[*][2])
	
	label left "Scattering Intensity (a.u.)"
	label bottom "Energy (eV)"
end

function displayfitdata()
	dowindow/k fit_data
	display/n=fit_data
	
	appendtograph spec_fit_params2[][1]
	appendtograph spec_fit_params2[][4]
	appendtograph spec_fit_params2[][7]
	appendtograph spec_fit_params2[][10]
	appendtograph spec_fit_params2[][13]
	modifygraph rgb[0]=(0,43520,65280), rgb[1]=(0,15872,65280), rgb[2]=(0,0,39168)
	modifygraph rgb[3]=(65280,43520,0), rgb[4]=(32768,65280,0)
	setaxis left 1.3, 2.7
	label left "Peak Position (eV)"
	
	appendtograph/l=hwhm spec_fit_params2[][2]
	appendtograph/l=hwhm spec_fit_params2[][5]
	appendtograph/l=hwhm spec_fit_params2[][8]
	appendtograph/l=hwhm spec_fit_params2[][11]
	appendtograph/l=hwhm spec_fit_params2[][14]
	modifygraph rgb[5]=(0,43520,65280), rgb[6]=(0,15872,65280), rgb[7]=(0,0,39168)
	modifygraph rgb[8]=(65280,43520,0)
	modifygraph rgb[9]=(32768,65280,0)
	label hwhm "HWHM (eV)"
	setaxis/a=2 hwhm
	
	appendtograph/l=amp spec_fit_params2[][0]
	appendtograph/l=amp spec_fit_params2[][3]
	appendtograph/l=amp spec_fit_params2[][6]
	appendtograph/l=amp spec_fit_params2[][9]
	appendtograph/l=amp spec_fit_params2[][12]
	modifygraph rgb[10]=(0,43520,65280), rgb[11]=(0,15872,65280), rgb[12]=(0,0,39168)
	modifygraph rgb[13]=(65280,43520,0)
	modifygraph rgb[14]=(32768,65280,0)
	label amp "Amplitude"
	setaxis/a=2 amp
	
	appendtograph/l=cond tipConductance
	modifygraph log(cond)=1, rgb(tipConductance)=(0,0,0)
	label cond "Conductance (G\B0\M)"
	setaxis/a=2 cond
	
	Legend/C/N=text0/J/A=RB "\\Z10\\s(spec_fit_params2) Mode A\r\\s(spec_fit_params2#1) Mode B\r\\s(spec_fit_params2#2) Mode C"
	AppendText "\\s(spec_fit_params2#3) Bkgd Mode\r\\s(spec_fit_params2#4) Mode D"
	
	modifygraph mode = 4, marker = 8, msize = 1.2
	modifygraph axisEnab(left)={0.77,1}, axisEnab(hwhm)={0.27,0.48}, axisEnab(amp)={0.52,0.73}, axisEnab(cond)={0,0.23}
	modifygraph freePos=0, lblPosMode=1
	label bottom "Step"
	setaxis bottom 214,240
end

function fit_to_image()
	wave image = root:analysis:image_src
	wave frequency = root:analysis:frequency, wavelength = root:analysis:wavelength
	wave frequencyImageAxis, wavelengthImageAxis
	dowindow/k tipexp
	display/n=tipexp
	appendimage/w=tipexp image vs {*,frequencyImageAxis}
	setaxis left 1.2, 2.7
	label left "Energy (\\U)"; label bottom "Step"
	modifyimage image_smth ctab = {*,*,Geo,0}, ctabAutoscale = 1
	
	wave s = spec_fit_params2
	appendtograph/w=tipexp s[][0]
	appendtograph/w=tipexp s[][3]
	appendtograph/w=tipexp s[][6]
	appendtograph/w=tipexp s[][9]
	appendtograph/w=tipexp s[][12]
	modifygraph/w=tipexp lstyle=2, lsize=1.1, rgb=(0,0,0)
	
	wave s = spec_fit_params
	duplicate/o image, image_fit
	variable i = 0
	svar fit
	make/free/n=(numpnts(frequency)) spec_fit
	make/free/n=(16) w
	do
		w = s[i][p]
		spec_fit = mode_fit(w, frequency)
		image_fit[i][] = spec_fit[q]
		i += 1
	while (i < dimsize(image,0))
	dowindow/k tipexp_fit
	display/n=tipexp_fit
	appendimage/w=tipexp_fit image_fit vs {*,frequencyImageAxis}
	setaxis left 1.2, 2.7
	label left "Energy (\\U)"; label bottom "Step"
	modifyimage image_fit ctab = {0.006,0.5,Geo,0}, ctabAutoscale = 1
	
	wave s = spec_fit_params2
	appendtograph/w=tipexp_fit s[][0]
	appendtograph/w=tipexp_fit s[][3]
	appendtograph/w=tipexp_fit s[][6]
	appendtograph/w=tipexp_fit s[][9]
	appendtograph/w=tipexp_fit s[][12]
	//errorbars/w=tipexp_fit/l=0/t=1/y=1 spec_fit_params2 y,wave=(s[*][2],s[*][2])
	//errorbars/w=tipexp_fit/l=0/t=1/y=1 spec_fit_params2#1 y,wave=(s[*][5],s[*][5])
	//errorbars/w=tipexp_fit/l=0/t=1/y=1 spec_fit_params2#2 y,wave=(s[*][8],s[*][8])
	//errorbars/w=tipexp_fit/l=0/t=1/y=1 spec_fit_params2#3 y,wave=(s[*][11],s[*][11])
	//errorbars/w=tipexp_fit/l=0/t=1/y=1 spec_fit_params2#4 y,wave=(s[*][14],s[*][14])
	modifygraph/w=tipexp_fit lstyle=2, lsize=1.1, rgb=(0,0,0)
end

function fit_to_image_G()
	wave image = root:analysis:image_smth
	wave wavelength = root:analysis:wavelength
	wave frequency = root:analysis:frequency
	wave wavelengthImageAxis
	wave frequencyImageAxis
	wave tipConductance
	dowindow/k tipexp
	display/n=tipexp
	appendimage/w=tipexp image vs {tipConductance2,frequencyImageAxis}
	modifyimage image_smth ctab = {*,*,Geo,0}, ctabAutoscale = 1
	
	wave s = spec_fit_params2
	appendtograph/w=tipexp s[][1] vs tipConductance
	appendtograph/w=tipexp s[][4] vs tipConductance
	appendtograph/w=tipexp s[][7] vs tipConductance
	appendtograph/w=tipexp s[][10] vs tipConductance
	appendtograph/w=tipexp s[][13] vs tipConductance
	modifygraph/w=tipexp lstyle=2, lsize=1.1, rgb=(0,0,0)
	
	setaxis left 1.2, 2.7
	modifygraph log(bottom)=1
	modifygraph swapxy=1
	label left "Energy (\\U)"; label bottom "Conductance (\\U)"
	
	wave s = spec_fit_params
	duplicate/o image, image_fit
	variable i = 0
	svar fit
	make/free/n=(numpnts(frequency)) spec_fit
	make/free/n=(16) w
	do
		w = s[i][p]
		spec_fit = mode_fit(w, frequency)
		image_fit[i][] = spec_fit[q]
		i += 1
	while (i < dimsize(image,0))
	dowindow/k tipexp_fit
	display/n=tipexp_fit
	appendimage/w=tipexp_fit image_fit vs {tipConductance2,frequencyImageAxis}
	modifyimage image_fit ctab = {0.006,0.5,Geo,0}, ctabAutoscale = 1
	
	wave s = spec_fit_params2
	appendtograph/w=tipexp_fit s[][1] vs tipConductance
	appendtograph/w=tipexp_fit s[][4] vs tipConductance
	appendtograph/w=tipexp_fit s[][7] vs tipConductance
	appendtograph/w=tipexp_fit s[][10] vs tipConductance
	appendtograph/w=tipexp_fit s[][13] vs tipConductance
	//errorbars/w=tipexp_fit/l=0/t=1/y=1 spec_fit_params2 y,wave=(s[*][2],s[*][2])
	//errorbars/w=tipexp_fit/l=0/t=1/y=1 spec_fit_params2#1 y,wave=(s[*][5],s[*][5])
	//errorbars/w=tipexp_fit/l=0/t=1/y=1 spec_fit_params2#2 y,wave=(s[*][8],s[*][8])
	//errorbars/w=tipexp_fit/l=0/t=1/y=1 spec_fit_params2#3 y,wave=(s[*][11],s[*][11])
	//errorbars/w=tipexp_fit/l=0/t=1/y=1 spec_fit_params2#4 y,wave=(s[*][14],s[*][14])
	
	modifygraph/w=tipexp_fit lstyle=2, lsize=1.1, rgb=(0,0,0)
	setaxis left 1.2, 2.7
	modifygraph log(bottom)=1
	label left "Energy (\\U)"; label bottom "Conductance (\\U)"
end

function display_image(image_str, axis_str)
	string image_str, axis_str
	wave image = $image_str
	wave frequencyImageAxis
	dowindow/k tipexp
	display/n=tipexp
	//display
	appendimage image vs {*,frequencyImageAxis}
	setaxis left 1.2, 2.7
	setaxis left 1.3, 2.2
	setaxis/a=2/r bottom
	setaxis bottom 150, 112
	label left "\\Z11Energy (\\U)"; label bottom "\\Z11Step"
	modifyimage $image_str ctab = {*,*,Geo,0}, ctabAutoscale = 1
	
	wave tipG = $axis_str
	appendtograph/l=l2 tipG
	modifygraph log(l2)=1
	setaxis/a/r l2
	label l2 "\\Z11Conductance (G\\B0\\M)"
	modifygraph mode=4,marker=8,msize=1.2,rgb=(0,0,0)
	
	modifygraph axisEnab(left) = {0,0.74}, axisEnab(l2) = {0.76,1}, freePos = 0, lblPosMode = 1
	modifygraph mirror(bottom) = 3,minor = 1,fSize = 11,btLen = 4, stLen = 2
	modifygraph swapxy = 1
end