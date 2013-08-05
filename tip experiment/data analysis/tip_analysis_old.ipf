#pragma rtGlobals=1		// Use modern global access method.

function fitdata2()
	wave image = root:analysis:spectra2d
	duplicate/o image, image_smth
	smooth 5, image_smth
	wave image = root:analysis:image_smth
	wave wavelength = root:analysis:wavelength
	wave frequency = root:analysis:frequency
	setscale d 0, 0, "eV", frequency
	
	wave wavelengthImageAxis
	wave frequencyImageAxis
	setscale d 0, 0, "eV", frequencyImageAxis
	
	dowindow/k tipexp
	display/n=tipexp
	
	//appendimage/w=tipexp image vs {*,wavelengthImageAxis}
	//setaxis left 5e-7, 9e-7
	//label left "Wavelength (\\U)"; label bottom "Step"
	
	appendimage/w=tipexp image vs {*,frequencyImageAxis}
	setaxis left 1.2, 2.7
	label left "Energy (\\U)"; label bottom "Step"
	
	modifyimage image_smth ctab = {*,*,Geo,0}, ctabAutoscale = 1
	
	//make/o/n=(0,dimsize(image, 1)) image_fit
	make/o/n=(dimsize(image, 1)) image_y
	make/o/n=(0,0) image_stat
	
	dowindow/k spectra_fit
	display/n=spectra_fit image_y vs frequency
	modifygraph rgb=(0,0,0)
	setaxis/a=2 left
	setaxis bottom 1.2, 2.7
	//make/D/N=13/O W_coef
	//W_coef = {0,1.95,2e-3,8e-3,2.25,4e-3,2e-2,2.6,3e-2,6e-2,1.6,2e-2,6e-2}
	make/d/n=16/O W_coef
	W_coef[0] = {0.02,2.05,2e-3,8e-3}
	W_coef[4] = {2.25,4e-3,2e-2}
	W_coef[7] = {2.6,3e-2,6e-2}
	W_coef[10] = {1.55,5e-4,5e-3}
	W_coef[13] = {1.65,5e-4,5e-3}
	//Make/O/T/N=10 constraints
	//constraints[0] = {"K2>=0", "K3>=0", "K5>=0", "K6>=0", "K8>=0", "K9>=0", "K11>=0", "K12>=0", "K14>=0", "K15>=0"}
	make/D/N=4/O mode_1 = {0,1.95,2e-3,8e-3}
	make/D/N=4/O mode_2 = {0,2.25,4e-3,2e-2}
	make/D/N=4/O mode_3 = {0,2.6,3e-2,6e-2}
	make/D/N=4/O mode_4 = {0,1.6,2e-2,6e-2}
	make/D/N=4/O mode_5 = {0,1.6,2e-2,6e-2}
	
	make/free/n=(dimsize(image, 1)) spec_rem
	duplicate/o image, image_fit
	duplicate/o image, image_fit1
	duplicate/o image, image_fit2
	duplicate/o image, image_fit3
	duplicate/o image, image_fit4
	duplicate/o image, image_fit5
	make/free/n=(dimsize(image, 1)) fit
	make/free/n=(dimsize(image, 1)) fit1
	make/free/n=(dimsize(image, 1)) fit2
	make/free/n=(dimsize(image, 1)) fit3
	make/free/n=(dimsize(image, 1)) fit4
	make/free/n=(dimsize(image, 1)) fit5
	
	variable i = 111, ptA = 220, ptB = 700, j = 0
	do
		image_y = image[i][p]
		funcfit/H="1"/Q/X/NTHR=0 lor5a W_coef image_y[ptA,ptB] /X=frequency/D//C=constraints 
		//funcfit/Q/X/NTHR=0 {{lor, mode_1, hold="1"},{lor, mode_2, hold="1"},{lor, mode_3, hold="1"},{lor, mode_4, hold="1"},{lor, mode_5, hold="1"}} image_y[ptA,ptB] /X=frequency/D
		wave fit_image_y
		//redimension/n=(i+1, dimsize(image, 1)) image_fit
		//image_fit[i][] = fit_image_y[q]
		redimension/n=(i+1, numpnts(W_coef)) image_stat
		image_stat[i][] = W_coef[q]
		
		//spec_rem = W_coef[0] + (W_coef[8] / (( frequency -W_coef[7])^2 + W_coef[9]))
		//image[i][] -= spec_rem[q]
		
		wave w = W_coef
		wave x = frequency
		fit1 =(w[2] / ((x-w[1])^2 + w[3]))
		fit2 = (w[5] / ((x-w[4])^2 + w[6]))
		fit3 = (w[8] / ((x-w[7])^2 + w[9]))
		fit4 = (w[11] / ((x-w[10])^2 + w[12]))
		fit5 = (w[14] / ((x-w[13])^2 + w[15]))
		fit = fit1 + fit2 + fit3 + fit4+ fit5
		image_fit1[i][] = fit1[q]
		image_fit2[i][] = fit2[q]
		image_fit3[i][] = fit3[q]
		image_fit4[i][] = fit4[q]
		image_fit5[i][] = fit5[q]
		image_fit[i][] = fit[q]
		//image_fit[i][] -= spec_rem[q]
		
		i += 1
	while (i < dimsize(image, 0))
	
	dowindow imagefits
	display/n=imagefits; appendimage/w=imagefits image_fit vs {*,frequencyImageAxis}
	setaxis/w=imagefits left 1.2, 2.7
	label/w=imagefits left "Energy (\\U)"; label/w=imagefits bottom "Step"
	modifyimage/w=imagefits image_fit ctab = {0.004,0.53,Geo,0}, ctabAutoscale = 1
	appendtograph/w=imagefits root:analysis:image_stat[][1]
	appendtograph/w=imagefits root:analysis:image_stat[][4]
	appendtograph/w=imagefits root:analysis:image_stat[][7]
	appendtograph/w=imagefits root:analysis:image_stat[][10]
	modifygraph/w=imagefits lstyle(image_stat)=2,lsize(image_stat)=1.1,rgb(image_stat)=(0,0,0)
	modifygraph/w=imagefits lstyle(image_stat#1)=2,lsize(image_stat#1)=1.1,rgb(image_stat#1)=(0,0,0)
	modifygraph/w=imagefits lstyle(image_stat#2)=2,lsize(image_stat#2)=1.1,rgb(image_stat#2)=(0,0,0)
	modifygraph/w=imagefits lstyle(image_stat#3)=2,lsize(image_stat#3)=1.1,rgb(image_stat#3)=(0,0,0)
	errorbars/w=imagefits/l=0/t=1/y=1 image_stat y,wave=(image_stat[*][3],image_stat[*][3])
	errorbars/w=imagefits/l=0/t=1/y=1 image_stat#1 y,wave=(image_stat[*][6],image_stat[*][6])
	errorbars/w=imagefits/l=0/t=1/y=1 image_stat#2 y,wave=(image_stat[*][9],image_stat[*][9])
	errorbars/w=imagefits/l=0/t=1/y=1 image_stat#3 y,wave=(image_stat[*][12],image_stat[*][12])
	killwindow spectra_fit
	
	if (waveexists(root:analysis:image_stat))
		//image_stat[][1] = 3e8 / (image_stat[p][1] * 1.6e-19 / 6.626068e-34)
		//image_stat[][4] = 3e8 / (image_stat[p][4] * 1.6e-19 / 6.626068e-34)
		//image_stat[][7] = 3e8 / (image_stat[p][7] * 1.6e-19 / 6.626068e-34)
		//image_stat[][10] = 3e8 / (image_stat[p][10] * 1.6e-19 / 6.626068e-34)
		
		image_stat[][3] = sqrt(image_stat[p][3]) //2
		image_stat[][6] = sqrt(image_stat[p][6]) //2
		image_stat[][9] = sqrt(image_stat[p][9]) //2
		image_stat[][12] = sqrt(image_stat[p][12]) //2
		
		//image_stat[][3] = 3e8 * (image_stat[p][3] * 1.6e-19 / 6.626068e-34) / (image_stat[p][1] * 1.6e-19 / 6.626068e-34)^2
		//image_stat[][6] = 3e8 * (image_stat[p][6] * 1.6e-19 / 6.626068e-34) / (image_stat[p][1] * 1.6e-19 / 6.626068e-34)^2
		//image_stat[][9] = 3e8 * (image_stat[p][9] * 1.6e-19 / 6.626068e-34) / (image_stat[p][1] * 1.6e-19 / 6.626068e-34)^2
		//image_stat[][12] = 3e8 * (image_stat[p][12] * 1.6e-19 / 6.626068e-34) / (image_stat[p][1] * 1.6e-19 / 6.626068e-34)^2
		
		appendtograph/w=tipexp root:analysis:image_stat[][1]
		appendtograph/w=tipexp root:analysis:image_stat[][4]
		appendtograph/w=tipexp root:analysis:image_stat[][7]
		appendtograph/w=tipexp root:analysis:image_stat[][10]
		errorbars/w=tipexp/l=0/t=1/y=1 image_stat y,wave=(image_stat[*][3],image_stat[*][3])
		errorbars/w=tipexp/l=0/t=1/y=1 image_stat#1 y,wave=(image_stat[*][6],image_stat[*][6])
		errorbars/w=tipexp/l=0/t=1/y=1 image_stat#2 y,wave=(image_stat[*][9],image_stat[*][9])
		errorbars/w=tipexp/l=0/t=1/y=1 image_stat#3 y,wave=(image_stat[*][12],image_stat[*][12])
		modifygraph/w=tipexp lstyle(image_stat)=2,lsize(image_stat)=1.1,rgb(image_stat)=(0,0,0)
		modifygraph/w=tipexp lstyle(image_stat#1)=2,lsize(image_stat#1)=1.1,rgb(image_stat#1)=(0,0,0)
		modifygraph/w=tipexp lstyle(image_stat#2)=2,lsize(image_stat#2)=1.1,rgb(image_stat#2)=(0,0,0)
		modifygraph/w=tipexp lstyle(image_stat#3)=2,lsize(image_stat#3)=1.1,rgb(image_stat#3)=(0,0,0)
	endif
	
	appendtograph/w=tipexp/l=l2 tipconductance
	label/w=tipexp l2 "Conductance (G\\B0\\M)"
	modifygraph/w=tipexp axisEnab(left)={0.25,1}
	modifygraph/w=tipexp log(l2)=1, freePos(l2)=0, axisEnab(l2)={0,0.2}, lblPosMode(l2)=1
	modifygraph/w=tipexp rgb(tipconductance)=(0,0,0)
	ModifyGraph/w=tipexp mirror(bottom)=1,nticks=10,fSize=10,btLen=4,stLen=2
	
	//killwaves image_y, fit_image_y
end