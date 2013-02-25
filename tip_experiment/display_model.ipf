#pragma rtGlobals=1		// Use modern global access method.
#include "data_handling"
#include "define_model"
#include "fit_functions"

function display_init_fit(data_path, i)
	string data_path
	variable i
	string data_folder = data#check_folder(":data_fitting")
	dowindow/k init_fit
	display/n=init_fit
	// display spectra
	wave spec2d = spectra2d, energy = energy
	deletepoints 1044, 1, energy
	make/o/n=(dimsize(spec2d, 1)) spec = spec2d[i][p]
	appendtograph spec vs energy
	setaxis bottom 1.2, 2.7; setaxis/a=2 left
	modifygraph rgb=(0,0,0)
	// display fit
	def_model(i)
	wave w_coef = $(data_folder + ":w_coef")
	make/o/n=(numpnts(energy)) spec_fit
	wave spec_fit
	spec_fit = custom_fit(w_coef, energy)
	appendtograph spec_fit vs energy
	// load individual modes
	wave m1p = $(data_folder + ":mode_1_p")
	wave m2p = $(data_folder + ":mode_2_p")
	wave m3p = $(data_folder + ":mode_3_p")
	wave m4p = $(data_folder + ":mode_4_p")
	wave m5p = $(data_folder + ":mode_5_p")
	make/o/n=(numpnts(energy)) mode_1, mode_2, mode_3, mode_4, mode_5
	svar mode_1_type = $(data_folder + ":mode_1")
	svar mode_2_type = $(data_folder + ":mode_2")
	svar mode_3_type = $(data_folder + ":mode_3")
	svar mode_4_type = $(data_folder + ":mode_4")
	svar mode_5_type = $(data_folder + ":mode_5")
	if (stringmatch(mode_1_type, "lorentzian"))
		mode_1 = lorentzian(m1p, energy)
		appendtograph mode_1 vs energy
		modifygraph rgb(''#2)=(0,65280,0), lstyle(''#2)=2
	endif
	if (stringmatch(mode_2_type, "lorentzian"))
		mode_2 = lorentzian(m2p, energy)
		appendtograph mode_2 vs energy
		modifygraph rgb(''#3)=(0,65280,0), lstyle(''#3)=2
	endif
	if (stringmatch(mode_3_type, "gaussian"))
		mode_3 = gaussian(m3p, energy)
		appendtograph mode_3 vs energy
		modifygraph rgb(''#4)=(0,0,65280), lstyle(''#4)=2
	endif
	if (stringmatch(mode_4_type, "gaussian"))
		mode_4 = gaussian(m4p, energy)
		appendtograph mode_4 vs energy
		modifygraph rgb(''#5)=(0,0,65280), lstyle(''#5)=2
	endif
	if (stringmatch(mode_5_type, "gaussian"))
		mode_5 = gaussian(m5p, energy)
		appendtograph mode_5 vs energy
		modifygraph rgb(''#6)=(0,0,65280), lstyle(''#6)=2
	endif
end

function update_graph()
	string data_folder = data#check_folder(":data_fitting")
	dowindow init_fit
	wave w_coef = $(data_folder + ":w_coef"), energy = energy
	make/o/n=(numpnts(energy)) spec_fit; wave spec_fit
	spec_fit = custom_fit(w_coef, energy)
	// load individual modes
	wave m1p = $(data_folder + ":mode_1_p")
	wave m2p = $(data_folder + ":mode_2_p")
	wave m3p = $(data_folder + ":mode_3_p")
	wave m4p = $(data_folder + ":mode_4_p")
	wave m5p = $(data_folder + ":mode_5_p")
	m1p = w_coef[p]
	m2p = w_coef[p+3]
	m3p = w_coef[p+6]
	m4p = w_coef[p+9]
	m5p = w_coef[p+12]
	wave mode_1, mode_2, mode_3, mode_4, mode_5
	svar mode_1_type = $(data_folder + ":mode_1")
	svar mode_2_type = $(data_folder + ":mode_2")
	svar mode_3_type = $(data_folder + ":mode_3")
	svar mode_4_type = $(data_folder + ":mode_4")
	svar mode_5_type = $(data_folder + ":mode_5")
	if (stringmatch(mode_1_type, "lorentzian"))
		mode_1 = lorentzian(m1p, energy)
	endif
	if (stringmatch(mode_2_type, "lorentzian"))
		mode_2 = lorentzian(m2p, energy)
	endif
	if (stringmatch(mode_3_type, "gaussian"))
		mode_3 = gaussian(m3p, energy)
	endif
	if (stringmatch(mode_4_type, "gaussian"))
		mode_4 = gaussian(m4p, energy)
	endif
	if (stringmatch(mode_5_type, "gaussian"))
		mode_5 = gaussian(m5p, energy)
	endif
end