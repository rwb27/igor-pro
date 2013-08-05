#pragma rtGlobals=1		// Use modern global access method.

#include "data_handling"
#include "fit_functions"

function def_model(i)
	variable i
	string data_folder = data#check_folder(":data_fitting")
	wave w_coef = $(data_folder + ":w_coef")
	if (i < 111)
		def_model_classical()
	elseif (i >= 111 && i < 131)
		//def_model_tunnelling_regime()
	//elseif (i == 131 || (i >= 131 && !waveexists(w_coef)) )
	elseif (i >= 131 && i < 200)
		//def_model_tunnelling_regime()
	elseif (i >= 200 && i < 229)
		def_model_quantum_regime()
	elseif (i >= 229)
		def_model_conductive_regime()
	endif
	// fit boundaries
	variable/g $(data_folder + ":wl_lower_i") = 225, $(data_folder + ":wl_upper_i") = 700
	make/o/n=1 bkgd = {0}
	
	wave m1p = $(data_folder + ":mode_1_p")
	wave m2p = $(data_folder + ":mode_2_p")
	wave m3p = $(data_folder + ":mode_3_p")
	wave m4p = $(data_folder + ":mode_4_p")
	wave m5p = $(data_folder + ":mode_5_p")
	concatenate/o/np {m1p, m2p, m3p, m4p, m5p, bkgd}, $(data_folder + ":w_coef")
	wave m1pl = $(data_folder + ":mode_1_p_lower")
	wave m2pl = $(data_folder + ":mode_2_p_lower")
	wave m3pl = $(data_folder + ":mode_3_p_lower")
	wave m4pl = $(data_folder + ":mode_4_p_lower")
	wave m5pl = $(data_folder + ":mode_5_p_lower")
	wave m1pu = $(data_folder + ":mode_1_p_upper")
	wave m2pu = $(data_folder + ":mode_2_p_upper")
	wave m3pu = $(data_folder + ":mode_3_p_upper")
	wave m4pu = $(data_folder + ":mode_4_p_upper")
	wave m5pu = $(data_folder + ":mode_5_p_upper")
	concatenate/t/o/np {m1pl, m1pu, m2pl, m2pu, m3pl, m3pu, m4pl, m4pu, m5pl, m5pu}, $(data_folder + ":t_constraints")
	
	make/o/t/n=2 $(data_folder + ":t_constraints") = {"K6 < 1.6", "K6 > 1.45"}
end

function def_model_classical()							// i < 111
	string data_folder = data#check_folder(":data_fitting")
	string/g $(data_folder + ":mode_1") = "lorentzian"				// dipolar plasmon
	string/g $(data_folder + ":mode_2") = "lorentzian"				// multipolar plasmon
	string/g $(data_folder + ":mode_3") = "gaussian"
	string/g $(data_folder + ":mode_4") = "gaussian"
	string/g $(data_folder + ":mode_5") = "gaussian"
	// reload strings
	svar mode_1_type = $(data_folder + ":mode_1")
	svar mode_2_type = $(data_folder + ":mode_2")
	svar mode_3_type = $(data_folder + ":mode_3")
	svar mode_4_type = $(data_folder + ":mode_4")
	svar mode_5_type = $(data_folder + ":mode_5")
	// mode 1 initial parameters
	if (stringmatch(mode_1_type, "lorentzian"))
		make/o/n=3 $(data_folder + ":mode_1_p") = {1.98, 0.09, 0.25}
		make/o/t/n=3 $(data_folder + ":mode_1_p_upper") = {"K0 < 2.2","K1 < 100","K2 < 100"}
		make/o/t/n=3 $(data_folder + ":mode_1_p_lower") = {"K0 > 0", "K1 > 0.0", "K2 > 0.0"}
	endif
	if (stringmatch(mode_2_type, "lorentzian"))
		make/o/n=3 $(data_folder + ":mode_2_p") = {2.57, 0.025, 0.25}
		make/o/t/n=3 $(data_folder + ":mode_2_p_upper") = {"K3 < 3","K4 < 100","K5 < 100"}
		make/o/t/n=3 $(data_folder + ":mode_2_p_lower") = {"K3 > 0", "K4 > 0.0", "K5 > 0.0"}
	endif
	if (stringmatch(mode_3_type, "gaussian"))
		make/o/n=3 $(data_folder + ":mode_3_p") = {1.53, 0.008, 0.1}
		make/o/t/n=3 $(data_folder + ":mode_3_p_upper") = {"K6 < 1.6","K7 < 100","K8 < 100"}
		make/o/t/n=3 $(data_folder + ":mode_3_p_lower") = {"K6 > 1.45", "K7 > 0.0", "K8 > 0.0"}
	endif
	if (stringmatch(mode_4_type, "gaussian"))
		make/o/n=3 $(data_folder + ":mode_4_p") = {2.25, 0.02, 0.2}
		make/o/t/n=3 $(data_folder + ":mode_4_p_upper") = {"K9 < 3","K10 < 100","K11 < 100"}
		make/o/t/n=3 $(data_folder + ":mode_4_p_lower") = {"K9 > 0", "K10 > 0.0", "K11 > 0.0"}
	endif
	if (stringmatch(mode_5_type, "gaussian"))
		make/o/n=3 $(data_folder + ":mode_5_p") = {1.75, 0.005, 0.05}
		make/o/t/n=3 $(data_folder + ":mode_5_p_upper") = {"K12 < 3","K13 < 100","K14 < 100"}
		make/o/t/n=3 $(data_folder + ":mode_5_p_lower") = {"K12 > 0", "K13 > 0.0", "K14 > 0.0"}
	endif
	// other variables
	string/g $(data_folder + ":hold_str") = "000" + "000" + "000" + "000" + "000" + "1"
end

function def_model_tunnelling_regime()							// i >= 131
	string data_folder = data#check_folder(":data_fitting")
	string/g $(data_folder + ":mode_1") = "lorentzian"				// dipolar plasmon
	string/g $(data_folder + ":mode_2") = "lorentzian"				// multipolar plasmon
	string/g $(data_folder + ":mode_3") = "gaussian"
	string/g $(data_folder + ":mode_4") = "gaussian"
	string/g $(data_folder + ":mode_5") = "gaussian"
	// reload strings
	svar mode_1_type = $(data_folder + ":mode_1")
	svar mode_2_type = $(data_folder + ":mode_2")
	svar mode_3_type = $(data_folder + ":mode_3")
	svar mode_4_type = $(data_folder + ":mode_4")
	svar mode_5_type = $(data_folder + ":mode_5")
	// mode 1 initial parameters
	if (stringmatch(mode_1_type, "lorentzian"))
		make/o/n=3 $(data_folder + ":mode_1_p") = {1.66, 0.03, 0.2}
		make/o/t/n=3 $(data_folder + ":mode_1_p_upper") = {"K0 < 100","K1 < 100","K2 < 100"}
		make/o/t/n=3 $(data_folder + ":mode_1_p_lower") = {"K0 > 0", "K1 > 0.0", "K2 > 0.0"}
	endif
	if (stringmatch(mode_2_type, "lorentzian"))
		make/o/n=3 $(data_folder + ":mode_2_p") = {1.94, 0.04, 0.2}
		make/o/t/n=3 $(data_folder + ":mode_2_p_upper") = {"K3 < 100","K4 < 100","K5 < 100"}
		make/o/t/n=3 $(data_folder + ":mode_2_p_lower") = {"K3 > 0", "K4 > 0.0", "K5 > 0.0"}
	endif
	if (stringmatch(mode_3_type, "gaussian"))
		make/o/n=3 $(data_folder + ":mode_3_p") = {1.55, 0.012, 0.05}
		make/o/t/n=3 $(data_folder + ":mode_3_p_upper") = {"K6 < 1.6","K7 < 100","K8 < 100"}
		make/o/t/n=3 $(data_folder + ":mode_3_p_lower") = {"K6 > 1.45", "K7 > 0.0", "K8 > 0.0"}
	endif
	if (stringmatch(mode_4_type, "gaussian"))
		make/o/n=3 $(data_folder + ":mode_4_p") = {2.25, 0.08, 0.1}
		make/o/t/n=3 $(data_folder + ":mode_4_p_upper") = {"K9 < 100","K10 < 100","K11 < 100"}
		make/o/t/n=3 $(data_folder + ":mode_4_p_lower") = {"K9 > 0", "K10 > 0.0", "K11 > 0.0"}
	endif
	if (stringmatch(mode_5_type, "gaussian"))
		make/o/n=3 $(data_folder + ":mode_5_p") = {2.6, 0.14, 0.15}
		make/o/t/n=3 $(data_folder + ":mode_5_p_upper") = {"K12 < 100","K13 < 100","K14 < 100"}
		make/o/t/n=3 $(data_folder + ":mode_5_p_lower") = {"K12 > 0", "K13 > 0.0", "K14 > 0.0"}
	endif
	// other variables
	string/g $(data_folder + ":hold_str") = "000" + "000" + "000" + "000" + "000" + "1"
end

function def_model_quantum_regime()							// i >= 131
	string data_folder = data#check_folder(":data_fitting")
	string/g $(data_folder + ":mode_1") = "lorentzian"				// dipolar plasmon
	string/g $(data_folder + ":mode_2") = "lorentzian"				// multipolar plasmon
	string/g $(data_folder + ":mode_3") = "gaussian"
	string/g $(data_folder + ":mode_4") = "gaussian"
	string/g $(data_folder + ":mode_5") = "gaussian"
	// reload strings
	svar mode_1_type = $(data_folder + ":mode_1")
	svar mode_2_type = $(data_folder + ":mode_2")
	svar mode_3_type = $(data_folder + ":mode_3")
	svar mode_4_type = $(data_folder + ":mode_4")
	svar mode_5_type = $(data_folder + ":mode_5")
	// mode 1 initial parameters
	if (stringmatch(mode_1_type, "lorentzian"))
		make/o/n=3 $(data_folder + ":mode_1_p") = {1.66, 0.01, 0.2}
		make/o/t/n=3 $(data_folder + ":mode_1_p_upper") = {"K0 < 100","K1 < 100","K2 < 100"}
		make/o/t/n=3 $(data_folder + ":mode_1_p_lower") = {"K0 > 0", "K1 > 0.0", "K2 > 0.0"}
	endif
	if (stringmatch(mode_2_type, "lorentzian"))
		make/o/n=3 $(data_folder + ":mode_2_p") = {1.97, 0.06, 0.15}
		make/o/t/n=3 $(data_folder + ":mode_2_p_upper") = {"K3 < 100","K4 < 100","K5 < 100"}
		make/o/t/n=3 $(data_folder + ":mode_2_p_lower") = {"K3 > 0", "K4 > 0.0", "K5 > 0.0"}
	endif
	if (stringmatch(mode_3_type, "gaussian"))
		make/o/n=3 $(data_folder + ":mode_3_p") = {1.55, 0.02, 0.07}
		make/o/t/n=3 $(data_folder + ":mode_3_p_upper") = {"K6 < 1.6","K7 < 100","K8 < 100"}
		make/o/t/n=3 $(data_folder + ":mode_3_p_lower") = {"K6 > 1.45", "K7 > 0.0", "K8 > 0.0"}
	endif
	if (stringmatch(mode_4_type, "gaussian"))
		make/o/n=3 $(data_folder + ":mode_4_p") = {2.29, 0.12, 0.15}
		make/o/t/n=3 $(data_folder + ":mode_4_p_upper") = {"K9 < 100","K10 < 100","K11 < 100"}
		make/o/t/n=3 $(data_folder + ":mode_4_p_lower") = {"K9 > 0", "K10 > 0.0", "K11 > 0.0"}
	endif
	if (stringmatch(mode_5_type, "gaussian"))
		make/o/n=3 $(data_folder + ":mode_5_p") = {2.6, 0.09, 0.11}
		make/o/t/n=3 $(data_folder + ":mode_5_p_upper") = {"K12 < 100","K13 < 100","K14 < 100"}
		make/o/t/n=3 $(data_folder + ":mode_5_p_lower") = {"K12 > 0", "K13 > 0.0", "K14 > 0.0"}
	endif
	// other variables
	string/g $(data_folder + ":hold_str") = "000" + "000" + "000" + "000" + "000" + "1"
end

function def_model_conductive_regime()							// i >= 229
	string data_folder = data#check_folder(":data_fitting")
	string/g $(data_folder + ":mode_1") = "lorentzian"				// dipolar plasmon
	string/g $(data_folder + ":mode_2") = "lorentzian"				// multipolar plasmon
	string/g $(data_folder + ":mode_3") = "gaussian"
	string/g $(data_folder + ":mode_4") = "gaussian"
	string/g $(data_folder + ":mode_5") = "gaussian"
	// reload strings
	svar mode_1_type = $(data_folder + ":mode_1")
	svar mode_2_type = $(data_folder + ":mode_2")
	svar mode_3_type = $(data_folder + ":mode_3")
	svar mode_4_type = $(data_folder + ":mode_4")
	svar mode_5_type = $(data_folder + ":mode_5")
	// mode 1 initial parameters
	if (stringmatch(mode_1_type, "lorentzian"))
		make/o/n=3 $(data_folder + ":mode_1_p") = {1.68, 0.03, 0.15}
		make/o/t/n=3 $(data_folder + ":mode_1_p_upper") = {"K0 < 100","K1 < 100","K2 < 100"}
		make/o/t/n=3 $(data_folder + ":mode_1_p_lower") = {"K0 > 0", "K1 > 0.0", "K2 > 0.0"}
	endif
	if (stringmatch(mode_2_type, "lorentzian"))
		make/o/n=3 $(data_folder + ":mode_2_p") = {2.04, 0.11, 0.17}
		make/o/t/n=3 $(data_folder + ":mode_2_p_upper") = {"K3 < 100","K4 < 100","K5 < 100"}
		make/o/t/n=3 $(data_folder + ":mode_2_p_lower") = {"K3 > 0", "K4 > 0.0", "K5 > 0.0"}
	endif
	if (stringmatch(mode_3_type, "gaussian"))
		make/o/n=3 $(data_folder + ":mode_3_p") = {1.55, 0.02, 0.07}
		make/o/t/n=3 $(data_folder + ":mode_3_p_upper") = {"K6 < 1.6","K7 < 100","K8 < 100"}
		make/o/t/n=3 $(data_folder + ":mode_3_p_lower") = {"K6 > 1.45", "K7 > 0.0", "K8 > 0.0"}
	endif
	if (stringmatch(mode_4_type, "gaussian"))
		make/o/n=3 $(data_folder + ":mode_4_p") = {2.29, 0.11, 0.15}
		make/o/t/n=3 $(data_folder + ":mode_4_p_upper") = {"K9 < 100","K10 < 100","K11 < 100"}
		make/o/t/n=3 $(data_folder + ":mode_4_p_lower") = {"K9 > 0", "K10 > 0.0", "K11 > 0.0"}
	endif
	if (stringmatch(mode_5_type, "gaussian"))
		make/o/n=3 $(data_folder + ":mode_5_p") = {2.6, 0.09, 0.11}
		make/o/t/n=3 $(data_folder + ":mode_5_p_upper") = {"K12 < 100","K13 < 100","K14 < 100"}
		make/o/t/n=3 $(data_folder + ":mode_5_p_lower") = {"K12 > 0", "K13 > 0.0", "K14 > 0.0"}
	endif
	// other variables
	string/g $(data_folder + ":hold_str") = "000" + "000" + "000" + "000" + "000" + "1"
end

function custom_fit(w, x) : fitfunc
	wave w
	variable x
	variable A, sigma, x0, G
	make/free/n=3 p0
	variable bkgd = w[numpnts(w)-1]
	variable f = 0
	// mode 1: dipolar plasmon
	x0 = w[0]; A = w[1]; G = w[2]
	p0 = {x0, A, G}
	f += lorentzian(p0, x)
	// mode 2: multipolar plasmon
	x0 = w[3]; A = w[4]; G = w[5]
	p0 = {x0, A, G}
	f += lorentzian(p0, x)
	// mode 3
	x0 = w[6]; A = w[7]; sigma = w[8]
	p0 = {x0, A, sigma}
	f += gaussian(p0, x)
	// mode 4
	x0 = w[9]; A = w[10]; sigma = w[11]
	p0 = {x0, A, sigma}
	f += gaussian(p0, x)
	// mode 5
	x0 = w[12]; A = w[13]; sigma = w[14]
	p0 = {x0, A, sigma}
	f += gaussian(p0, x)
	f += bkgd
	return f
end