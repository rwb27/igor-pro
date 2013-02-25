#pragma ModuleName = data
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

//strconstant initial_data_path = "c:users:hera:desktop:tip_exp:data"
strconstant initial_data_path = "c:users:alan:documents:0 - experiment:data"

function/s check_folder(data_folder)
	string data_folder
	if (!datafolderexists(data_folder))
		newdatafolder $data_folder
	endif
	return data_folder
end

function check_gvpath(gv_folder)
	string gv_folder
	check_folder("root:global_variables")
	check_folder(gv_folder)
end

function/s check_data_folder()
	string day, month, year
	string expr = "([[:digit:]]+) ([[:alpha:]]+) ([[:digit:]]+)"
	splitstring/e=(expr) date(), day, month, year
	string data_folder = "root:data"
	check_folder(data_folder)
	data_folder += ":" + month + "_" + year
	check_folder(data_folder)
	data_folder += ":day_" + day
	check_folder(data_folder)
	return data_folder
end

function/s new_data_folder(name)
	string name
	string data_folder
	variable i = 0
	do
		i += 1
		data_folder = name + num2str(i)
	while (datafolderexists(data_folder))
	newdatafolder data_folder
	return data_folder
end

function/s data_path(fname)
	string fname
	string day, month, year
	string expr = "([[:digit:]]+) ([[:alpha:]]+) ([[:digit:]]+)"
	splitstring/e=(expr) date(), day, month, year
	string data_path = initial_data_path + ":" + month + "_" + year
	data_path += ":day_" + day
	newpath/c data, data_path
	data_path += ":" + fname
	newpath/c data, data_path
	return data_path
end

function save_data(w)
	wave w
	save w
end

function load_tip_experiment(tip_exp)
	string tip_exp							// location of tip experiment data structure
	// parse string into components to reconstruct in the Igor data browser
	// example: ":raw data:Dec 2012:day 21:tip experiment"
	string expr = ":raw data:([[:alpha:]]+) ([[:digit:]]+):day ([[:digit:]]+):([[:alpha:]]+)"
	string month, year, day, experiment
	splitstring/e=(expr) tip_exp, month, year, day, experiment
	string data_folder = "root:data"
	check_folder(data_folder)
	data_folder += ":" + month + "_" + year
	check_folder(data_folder)
	data_folder += ":day_" + day
	check_folder(data_folder)
	data_folder += ":tip_experiment_"
	// increment at some point
	data_folder += "0"
	check_folder(data_folder)
	newpath/o/q data, initial_data_path
	loadwave/t/o/q/p=data tip_exp + ":spectra2D.txt"
	loadwave/t/o/q/p=data tip_exp + ":tipConductance.txt"
	loadwave/t/o/q/p=data tip_exp + ":PZdisplacement.txt"
	loadwave/t/o/q/p=data tip_exp + ":wavelengthImageAxis.txt"
	movewave :spectra2D, $(data_folder +":")
	movewave :tipConductance, $(data_folder +":")
	movewave :PZdisplacement, $(data_folder +":")
	movewave :wavelengthImageAxis, $(data_folder +":")
end