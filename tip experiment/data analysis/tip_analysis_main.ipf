#pragma rtGlobals=1		// Use modern global access method.
#include <Multi-peak fitting 2.0>

#include "tip_analysis_fit_funcs"
#include "tip_analysis_display"

function define_model()
	// Mode profiles
	string/g mode_1 = "gauss"
	string/g mode_2 = "lor"
	string/g mode_3 = "gauss"
	string/g mode_4 = "gauss"
	string/g mode_5 = "gauss"
	// Mode regimes
	variable/g lower_i = 111, upper_i = 131
	// Fit limits
	variable/g ptA = 225, ptB = 700
end

function make_fit_waves(i)
	variable i
	svar mode_1, mode_2, mode_3, mode_4, mode_5
	nvar lower_i, upper_i
	make/o/n=16 w_coef
	w_coef[0] = 0
	if (i == 0)
		w_coef[1] = {0.034933, 1.5181, 0.057218}
		w_coef[4] = {0.14, 2.04, 0.27}
		w_coef[7] = {0.06, 2.27, 0.08}
		w_coef[10] = {0.2,2.6,0.1}
		w_coef[13] = {0.1,1.68,0.1}
	elseif (i == lower_i)
		// Mode 1
		if (stringmatch(mode_1, "gauss"))
			w_coef[1] = {0.08, 1.99, 0.3}
		elseif (stringmatch(mode_1, "lor"))
			w_coef[1] = {0,0,0}
		endif
		// Mode 2
		if (stringmatch(mode_2, "gauss"))
			w_coef[4] = {0,0,0}
		elseif (stringmatch(mode_2, "lor"))
			w_coef[4] = {0.2, 2.27, 0.1}
		endif
		// Mode 3
		if (stringmatch(mode_3, "gauss"))
			w_coef[7] = {0.35,2.6,0.2}
		elseif (stringmatch(mode_3, "lor"))
			w_coef[7] = {0,0,0}
		endif
		// Mode 4
		if (stringmatch(mode_4, "gauss"))
			w_coef[10] = {0.1,1.64,0.1}
		elseif (stringmatch(mode_4, "lor"))
			w_coef[10] = {0,0,0}
		endif
		// Mode 5
		if (stringmatch(mode_5, "gauss"))
			w_coef[13] = {0,0,0}
		elseif (stringmatch(mode_5, "lor"))
			w_coef[13] = {0,0,0}
		endif
	elseif (i == upper_i)
		// Mode 1
		if (stringmatch(mode_1, "gauss"))
			w_coef[1] = {0, 0.034933, 1.5181, 0.057218}
		elseif (stringmatch(mode_1, "lor"))
			w_coef[1] = {0,0,0}
		endif
		// Mode 2
		if (stringmatch(mode_2, "gauss"))
			w_coef[4] = {0,0,0}
		elseif (stringmatch(mode_2, "lor"))
			w_coef[4] = {0.7, 2.03, 0.2}
		endif
		// Mode 3
		if (stringmatch(mode_3, "gauss"))
			w_coef[7] = {0.3, 2.25, 0.1}
		elseif (stringmatch(mode_3, "lor"))
			w_coef[7] = {0,0,0}
		endif
		// Mode 4
		if (stringmatch(mode_4, "gauss"))
			w_coef[10] = {0.4,2.6,0.15}
		elseif (stringmatch(mode_4, "lor"))
			w_coef[10] = {0,0,0}
		endif
		// Mode 5
		if (stringmatch(mode_5, "gauss"))
			w_coef[13] = {0.15,1.67,0.05}
		elseif (stringmatch(mode_5, "lor"))
			w_coef[13] = {0,0,0}
		endif
	endif
	
	make/o/t/n=9 T_Constraints
	T_Constraints[0] = {"K2 > 1.5", "K2 < 1.6", "K3 > 0.05", "K3 < 0.07"}
	T_Constraints[4] = {"K5 > 1.8","K5 < 2.1"}
	T_Constraints[6] = {"K8 > 2.1", "K8 < 2.5"}
	T_Constraints[8] = {"K11 > 2.5"}
	if (i <= 130 || i >= upper_i)
		redimension/n=11 T_Constraints
		T_Constraints[9] = {"K14 > 1.5", "K14 < 1.8"}
	endif
end

function data_store()
	if (!waveexists(spec_fit_params))
		make/o/n=(0,0) spec_fit_params
		make/o/n=(0,0) spec_fit_errors
		make/o/n=(0,0) spec_fit_params2
		make/t/o/n=(1,16) spec_fit_params_key
		make/t/o/n=(1,15) spec_fit_params2_key
	endif
end

function fit_data()
	saveexperiment
	wave image = root:analysis:spectra2d
	define_model()
	variable i = 0
	nvar ptA, ptB
	wave w_coef
	do
		prep_image(i)
		make_fit_waves(i)
		FuncFit/Q/X=1/NTHR=0/W=2/H="1000" mode_fit w_coef  image_spec[ptA,ptB] /X=frequency /D /C=T_Constraints
		FuncFit/Q/X=1/NTHR=0/W=2/H="1000" mode_fit w_coef  image_spec[ptA,ptB] /X=frequency /D /C=T_Constraints
		save_fit(i)
		i += 1
	while (i < dimsize(image, 0))
end

function prep_image(i)
	variable i
	wave image = root:analysis:spectra2d
	duplicate/o image, image_src
	wave image = root:analysis:image_src
	make/o/n=(dimsize(image, 1)) image_spec
	image_spec = image[i][p]
	
	// Display spectra to view fit
	dowindow/k spectra_fit
	display/n=spectra_fit image_spec vs frequency
	modifygraph rgb=(0,0,0)
	setaxis/a=2 left
	setaxis bottom 1.2, 2.7
	textbox/c/n=text0/a=lt num2str(i)
end

function save_fit_key()
	wave/t k1 = spec_fit_params_key, spec_fit_params2_key
	// Spec fit raw parameters
	k1[0][0] = "Bkgd"
	// Mode 1
	k1[0][1] = "Mode A A"; k1[0][2] = "Mode A x0"; k1[0][3] = "Mode A sigma"
	// Mode 2
	k1[0][4] = "Mode B A"; k1[0][5] = "Mode B x0"; k1[0][6] = "Mode B G"
	// Mode 3
	k1[0][7] = "Mode C A"; k1[0][8] = "Mode C x0"; k1[0][9] = "Mode C sigma"
	// Mode 4
	k1[0][10] = "Bkgd Mode A"; k1[0][11] = "Bkgd Mode x0"; k1[0][12] = "Bkgd Mode sigma"
	// Mode 5
	k1[0][13] = "Mode D A"; k1[0][14] = "Mode D x0"; k1[0][15] = "Mode D sigma"
	
	// Spec fit useful parameters
	make/t/free/n=(numpnts(w_coef)-1) w_params_key
	
	// Mode position
	w_params_key[0] = "Mode A Energy"
	w_params_key[3] = "Mode B Energy"
	w_params_key[6] = "Mode C Energy"
	w_params_key[9] = "Bkgd Mode Energy"
	w_params_key[12] = "Mode D Energy"
	
	// Mode amplitude
	w_params_key[1] = "Mode A Amplitude"
	w_params_key[4] = "Mode B Amplitude"
	w_params_key[7] = "Mode C Amplitude"
	w_params_key[10] = "Bkgd Mode Amplitude"
	w_params_key[13] = "Mode D Amplitude"
	
	// Mode width
	w_params_key[2] = "Mode A FWHM"
	w_params_key[5] = "Mode B FWHM"
	w_params_key[8] = "Mode C FWHM"
	w_params_key[11] = "Bkgd Mode FWHM"
	w_params_key[14] = "Mode D FWHM"
	
	spec_fit_params2_key[0][] = w_params_key[q]
end

function save_fit(i)
	variable i
	svar mode_1, mode_2, mode_3, mode_4, mode_5
	wave spec_fit_params, spec_fit_errors, spec_fit_params2

	// Save fit (i) parameters to row (i)
	wave w_coef, w_sigma
	variable size = 16
	redimension/n=(i+1, size) spec_fit_params
	redimension/n=(i+1, size) spec_fit_errors
	redimension/n=(i+1, size-1) spec_fit_params2
	spec_fit_params[i][] = w_coef[q]
	spec_fit_errors[i][] = w_sigma[q]
	
	make/free/n=(numpnts(w_coef)) w_params = w_coef
	deletepoints 0, 1, w_params
	
	// Mode 1
	w_params[1] = abs(w_params[1])	// amplitude
	w_params[2] = 2 * sqrt(2 * ln(2)) * abs(w_params[2])	// fwhm
	
	// Mode 2
	// amplitude
	if (stringmatch(mode_2, "lor"))
		w_params[3] = abs(w_params[3]) / (pi * w_params[5])
	elseif (stringmatch(mode_2, "gauss"))
		w_params[3] = abs(w_params[3])
	endif
	// fwhm
	if (stringmatch(mode_2, "lor"))
		w_params[5] = 2 * abs(w_params[5])
	elseif (stringmatch(mode_2, "gauss"))
		w_params[5] = 2 * sqrt(2 * ln(2)) * abs(w_params[5])
	endif
	
	// Mode 3
	w_params[7] = abs(w_params[7])
	w_params[8] = 2 *sqrt(2 * ln(2)) * abs(w_params[8])
	// Mode 4
	w_params[10] = abs(w_params[10])
	w_params[11] = 2 *sqrt(2 * ln(2)) * abs(w_params[11])
	// Mode 5
	w_params[13] = abs(w_params[13])
	w_params[14] = 2 *sqrt(2 * ln(2)) * abs(w_params[14])
	
	spec_fit_params2[i][] = w_params[q]
end

function save_modes(i)
	variable i
	svar mode_1, mode_2, mode_3, mode_4, mode_5
	if (!datafolderexists("root:analysis:spec_fit_params"))
		newdatafolder root:analysis:spec_fit_params
	endif
	
	duplicate/o image_spec, $("root:analysis:spec_fit_params:spec_"+num2str(i))
	duplicate/o w_coef, $("root:analysis:spec_fit_params:w_coef_"+num2str(i))
	duplicate/o w_sigma, $("root:analysis:spec_fit_params:w_sigma_"+num2str(i))
	
	wave w = w_coef, frequency
	
	// Mode 1
	make/o/n=(numpnts(frequency)) $("root:analysis:spec_fit_params:spec_fit_mode1_"+num2str(i))
	wave mode1 = $("root:analysis:spec_fit_params:spec_fit_mode1_"+num2str(i))
	if (stringmatch(mode_1, "gauss"))
		mode1 = gauss1(w[2], w[1], w[3], frequency)
	elseif (stringmatch(mode_1, "lor"))
		mode1 = lor1(w[2], w[1], w[3], frequency)
	endif
	make/o/n=3 $("root:analysis:spec_fit_params:spec_fit_params_mode1_"+num2str(i))
	// Mode 2
	make/o/n=(numpnts(frequency)) $("root:analysis:spec_fit_params:spec_fit_mode2_"+num2str(i))
	wave mode2 = $("root:analysis:spec_fit_params:spec_fit_mode2_"+num2str(i))
	if (stringmatch(mode_2, "gauss"))
		mode2 = gauss1(w[5], w[4], w[6], frequency)
	elseif (stringmatch(mode_2, "lor"))
		mode2 = lor1(w[5], w[4], w[6], frequency)
	endif
	make/o/n=3 $("root:analysis:spec_fit_params:spec_fit_params_mode2_"+num2str(i))
	// Mode 3
	make/o/n=(numpnts(frequency)) $("root:analysis:spec_fit_params:spec_fit_mode3_"+num2str(i))
	wave mode3 = $("root:analysis:spec_fit_params:spec_fit_mode3_"+num2str(i))
	if (stringmatch(mode_3, "gauss"))
		mode3 = gauss1(w[8], w[7], w[9], frequency)
	elseif (stringmatch(mode_3, "lor"))
		mode3 = lor1(w[8], w[7], w[9], frequency)
	endif
	make/o/n=3 $("root:analysis:spec_fit_params:spec_fit_params_mode3_"+num2str(i))
	// Mode 4
	make/o/n=(numpnts(frequency)) $("root:analysis:spec_fit_params:spec_fit_mode4_"+num2str(i))
	wave mode4 = $("root:analysis:spec_fit_params:spec_fit_mode4_"+num2str(i))
	if (stringmatch(mode_4, "gauss"))
		mode4 = gauss1(w[11], w[10], w[12], frequency)
	elseif (stringmatch(mode_4, "lor"))
		mode4 = lor1(w[11], w[10], w[12], frequency)
	endif
	make/o/n=3 $("root:analysis:spec_fit_params:spec_fit_params_mode4_"+num2str(i))
	// Mode 5
	make/o/n=(numpnts(frequency)) $("root:analysis:spec_fit_params:spec_fit_mode5_"+num2str(i))
	wave mode5 = $("root:analysis:spec_fit_params:spec_fit_mode5_"+num2str(i))
	if (stringmatch(mode_5, "gauss"))
		mode5 = gauss1(w[14], w[13], w[15], frequency)
	elseif (stringmatch(mode_5, "lor"))
		mode5 = lor1(w[14], w[13], w[15], frequency)
	endif
	make/o/n=3 $("root:analysis:spec_fit_params:spec_fit_params_mode5_"+num2str(i))
end