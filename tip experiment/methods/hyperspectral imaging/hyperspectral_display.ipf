#pragma ModuleName = hs_display
#pragma version = 6.32
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "analysis_tools"

static function display_scan(sf, wl)
	dfref sf
	variable wl
	variable dual_pol = 0
	wave/sdfr=sf image = hyperspec_image, wavelength
	// check if wave exists
	wave/sdfr=sf image_t = hyperspec_image_t
	if (waveexists(image_t))
		dual_pol = 1
	endif
	variable index = wavelength_to_index(wavelength, wl)
	dowindow/k hyperspec
	display/k=1/n=hyperspec
	appendimage image
	modifyimage ''#0 plane=index
	modifygraph width=250
	modifygraph height={aspect,1}
	modifyimage ''#0 ctab= {0,*,ColdWarm,0}, ctabAutoscale=3,lookup= $""
	if (dual_pol)
		appendimage/b=b1 image_t
		modifygraph axisenab(bottom) = {0, 0.49}, axisenab(b1) = {0.51, 1.0}
		modifygraph width=500
		modifygraph height={aspect,0.5}
		modifyimage ''#1 plane=index
		modifyimage ''#1 ctab= {0,*,ColdWarm,0}, ctabAutoscale=3,lookup= $""
	endif
	modifygraph tick=2, mirror=1, fSize=11
	modifygraph freepos=0
	textbox/c/n=text0/f=0/b=1/g=(65280,65280,65280)/a=rt "\\Z10\\F'Symbol'l\\F'Arial' = "+num2str(wl)+" nm"
end

static function display_image(image, wavelength, wl)
	wave image, wavelength
	variable wl
	// check if wave exists
	variable index = wavelength_to_index(wavelength, wl)
	dowindow/k hyperspec
	display/k=1/n=hyperspec
	appendimage image
	modifyimage ''#0 plane=index
	modifygraph width=250
	modifygraph height={aspect,1}
	modifyimage ''#0 ctab= {0,*,ColdWarm,0}, ctabAutoscale=3,lookup= $""
	modifygraph tick=2, mirror=1, fSize=11
	modifygraph freepos=0
	textbox/c/n=text0/f=0/b=1/g=(65280,65280,65280)/a=rt "\\Z10\\F'Symbol'l\\F'Arial' = "+num2str(wl)+" nm"
end

static function display_range(image, wavelength)
	wave image, wavelength
	dowindow/k hyperspec
	display/k=1/n=hyperspec
	appendimage/l/b image; modifyimage ''#0 plane=wavelength_to_index(wavelength, 450)
	appendimage/l/b=b1 image; modifyimage ''#1 plane=wavelength_to_index(wavelength, 500)
	appendimage/l/b=b2 image; modifyimage ''#2 plane=wavelength_to_index(wavelength, 550)
	appendimage/l/b=b3 image; modifyimage ''#3 plane=wavelength_to_index(wavelength, 600)
	appendimage/l=l1/b image; modifyimage ''#4 plane=wavelength_to_index(wavelength, 650)
	appendimage/l=l1/b=b1 image; modifyimage ''#5 plane=wavelength_to_index(wavelength, 700)
	appendimage/l=l1/b=b2 image; modifyimage ''#6 plane=wavelength_to_index(wavelength, 750)
	appendimage/l=l1/b=b3 image; modifyimage ''#7 plane=wavelength_to_index(wavelength, 800)
	
	modifygraph axisenab(left)={0.505,1}, axisenab(l1)={0,0.495}
	modifygraph axisenab(bottom)={0,0.245}, axisenab(b1)={0.255,0.495}, axisenab(b2)={0.505,0.745}, axisenab(b3)={0.755,1}
	
	textbox/c/n=text0/f=0/b=1/g=(65280,65280,65280)/a=lt/x=1/y=1 "\\Z10\\F'Symbol'l\\F'SansSerif' = 450 nm"
	textbox/c/n=text1/f=0/b=1/g=(65280,65280,65280)/a=lt/x=26/y=1 "\\Z10\\F'Symbol'l\\F'SansSerif' = 500 nm"
	textbox/c/n=text2/f=0/b=1/g=(65280,65280,65280)/a=lt/x=51/y=1 "\\Z10\\F'Symbol'l\\F'SansSerif' = 550 nm"
	textbox/c/n=text3/f=0/b=1/g=(65280,65280,65280)/a=lt/x=76/y=1 "\\Z10\\F'Symbol'l\\F'SansSerif' = 600 nm"
	textbox/c/n=text4/f=0/b=1/g=(65280,65280,65280)/a=lt/x=1/y=51 "\\Z10\\F'Symbol'l\\F'SansSerif' = 650 nm"
	textbox/c/n=text5/f=0/b=1/g=(65280,65280,65280)/a=lt/x=26/y=51 "\\Z10\\F'Symbol'l\\F'SansSerif' = 700 nm"
	textbox/c/n=text6/f=0/b=1/g=(65280,65280,65280)/a=lt/x=51/y=51 "\\Z10\\F'Symbol'l\\F'SansSerif' = 750 nm"
	textbox/c/n=text7/f=0/b=1/g=(65280,65280,65280)/a=lt/x=76/y=51 "\\Z10\\F'Symbol'l\\F'SansSerif' = 800 nm"
	
	modifygraph width=72*(17.0/2.54)
	modifygraph height={aspect,0.5}
	modifyimage ''#0 ctab= {*,*,ColdWarm,0}, ctabAutoscale=3,lookup= $""
	modifyimage ''#1 ctab= {*,*,ColdWarm,0}, ctabAutoscale=3,lookup= $""
	modifyimage ''#2 ctab= {*,*,ColdWarm,0}, ctabAutoscale=3,lookup= $""
	modifyimage ''#3 ctab= {*,*,ColdWarm,0}, ctabAutoscale=3,lookup= $""
	modifyimage ''#4 ctab= {*,*,ColdWarm,0}, ctabAutoscale=3,lookup= $""
	modifyimage ''#5 ctab= {*,*,ColdWarm,0}, ctabAutoscale=3,lookup= $""
	modifyimage ''#6 ctab= {*,*,ColdWarm,0}, ctabAutoscale=3,lookup= $""
	modifyimage ''#7 ctab= {*,*,ColdWarm,0}, ctabAutoscale=3,lookup= $""
	modifygraph tick=0,minor=1,fSize=10,btLen=4,stLen=2,font="SansSerif"
	modifygraph mirror=1, freepos=0
	ModifyGraph lblLatPos(left)=60,lblLatPos(bottom)=185
	Label left "y position";	Label bottom "x position"
	//SavePICT/EF=1/P=home/E=-8 as "hyperspec_t.pdf"
end

static function display_sum(sf)
	dfref sf
	wave/sdfr=sf image = hyperspec_image, wavelength
	make/o/n=(dimsize(image, 0), dimsize(image, 1)) sum_image = 0
	variable i
	make/free/n=(dimsize(image, 0), dimsize(image, 1)) temp_image = 0
	//for(i = 0; i < dimsize(image, 2); i += 1)
	for(i = 0; i < dimsize(image, 2)-5; i += 1)
		temp_image[][] = image[p][q][i] // dimsize(image, 2)
		sum_image[][] += temp_image
	endfor
	dowindow/k hyperspec
	display/k=1/n=hyperspec
	appendimage sum_image
	modifygraph tick=2, mirror=1, fSize=11
	modifygraph width=250
	modifygraph height={aspect,1}
	modifyimage '' ctab= {0,*,ColdWarm,0}, ctabAutoscale=3,lookup= $""
end