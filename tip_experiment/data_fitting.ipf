#pragma rtGlobals=1		// Use modern global access method.

#include "define_model"

function fit_data()
	saveexperiment
	string data_folder = data#check_folder(":data_fitting")
	
	wave image = spectra2d, energy = energy
	duplicate/o image, spec2d_smth
	smooth 2, spec2d_smth
	wave image = spec2d_smth
	
	dowindow/k data_fits; display/n=data_fits
	make/o/n=(dimsize(image, 1)) spec = image[0][p]
	appendtograph spec vs energy
	setaxis bottom 1.2, 2.7; setaxis/a=2 left
	modifygraph rgb=(0,0,0)
	make/o/n=(numpnts(spec)) spec_fit
	appendtograph spec_fit vs energy
	
	variable i = 200
	textbox/c/n=text0/a=lt "i = " + num2str(i)
	wave w_coef = $(data_folder + ":w_coef")
	wave t_constraints = $(data_folder + ":t_constraints")
	//wave energy = energy
	svar hold_str = $(data_folder + ":hold_str")
	nvar wl_lower_i = $(data_folder + ":wl_lower_i"), wl_upper_i = $(data_folder + ":wl_upper_i")
	do
		def_model(i)
		make/o/n=(dimsize(image, 1)) spec = image[i][p]
		make/o/n=(numpnts(spec)) spec_fit
		variable q = 1
		do
			funcfit/q/x=1/nthr=0/w=2/h=hold_str custom_fit w_coef  spec[wl_lower_i,wl_upper_i] /x=energy /d=spec_fit /c=t_constraints
			//funcfit/q/x=1/nthr=0/w=2/h=hold_str custom_fit w_coef  spec[wl_lower_i,wl_upper_i] /x=energy /d=spec_fit
			textbox/c/n=text0/a=lt "i = " + num2str(i) + ", pass = " + num2str(q)
			q += 1
		while (q <= 2)
		//if (V_chisq > 0.01)
		//	print i
		//endif
		save_fit(i)
		i += 1
	while (i <= 240)//(i < dimsize(image, 0))
end

function save_fit(i)
	variable i
	string data_folder = data#check_folder(":data_fitting")
	wave w_coef = $(data_folder + ":w_coef")
	wave params = $(":params")
	if (!waveexists(params))
		make/o/n=(0,numpnts(w_coef)) params
	endif
	if (i >= dimsize(params, 0))
		redimension/n=(i, numpnts(w_coef)) params
	endif
	params[i][] = w_coef[q]
end