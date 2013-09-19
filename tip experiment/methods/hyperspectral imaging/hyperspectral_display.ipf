#pragma ModuleName = hs_display
#pragma version = 6.32
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "analysis_tools"

static function display_scan(sf, wl)
	dfref sf
	variable wl
	wave/sdfr=sf image = hyperspec_image, wavelength
	variable index = wavelength_to_index(wavelength, wl)
	dowindow/k hyperspec
	display/k=1/n=hyperspec
	appendimage image
	modifyimage ''#0 plane=index
	modifygraph tick=2, mirror=1, fSize=11
	modifygraph width=250
	modifygraph height={aspect,1}
	modifyimage ''#0 ctab= {0,*,ColdWarm,0}, ctabAutoscale=3,lookup= $""
	textbox/c/n=text0/f=0/b=1/g=(65280,65280,65280)/a=rt "\\Z10\\F'Symbol'l\\F'Arial' = "+num2str(wl)+" nm"
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