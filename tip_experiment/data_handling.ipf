#pragma ModuleName = data
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

// These folders must exist
strconstant initial_data_path_lab = "C:Users:Hera:Desktop:tip_exp:raw_data"
strconstant initial_data_path_laptop = "C:Users:Alan:Documents:0 - experiment:data:raw data"

// This must be run first
function define_paths(pc)
	string pc
	if (stringmatch(pc, "lab"))
		newpath/c/o/q data, initial_data_path_lab
	elseif (stringmatch(pc, "laptop"))
		newpath/c/o/q data, initial_data_path_laptop
	endif
end

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
	newdatafolder $data_folder
	return data_folder
end

function/s data_path(fname)
	string fname
	string day, month, year
	string expr = "([[:digit:]]+) ([[:alpha:]]+) ([[:digit:]]+)"
	splitstring/e=(expr) date(), day, month, year
	pathinfo data
	if (v_flag == 0)
		abort "define paths"
	endif
	string initial_data_path = s_path
	newpath/c/o/q data, initial_data_path
	string data_path = initial_data_path + ":" + month + "_" + year
	newpath/c/o/q data, data_path
	data_path += ":day_" + day
	newpath/c/o/q data, data_path
	data_path += ":" + fname
	newpath/c/o/q data, data_path
	return data_path
end

function save_data(w, wname, data_path)
	wave w
	string wname, data_path
	pathinfo data
	if (v_flag == 0)
		abort "define paths"
	endif
	string initial_data_path = s_path
	data_path = initial_data_path + ":" + data_path
	wname += ".ibw"
	newpath/o/c data data_path
	save/p=data/c/o w as wname
end

function unpack_experiment(data_folder)
	// give data folder
	string data_folder
	string data_folder2
	string data_path
	string data_path2
	string expr = "root:data:(.+)"
	variable i
	
	// create folder if not currently existing
	pathinfo data
	if (v_flag == 0)
		abort "define paths"
	endif
	string initial_data_path = s_path
	data_path = initial_data_path
	newpath/c/o/q data, data_path
	splitstring/e=(expr) data_folder, data_path2
	data_path = initial_data_path + ":" + data_path2
	newpath/c/o data, data_path
	
	// create waves
	variable num_waves = countobjects(data_folder, 1)
	string wname
	for(i = 0; i < num_waves; i += 1)
		if (num_waves == 0)
			break
		endif
		// save waves
		wave w = $(data_folder + ":" + getindexedobjname(data_folder, 1, i))
		wname = getindexedobjname(data_folder, 1, i) + ".ibw"
		save/p=data/c/o w as wname
	endfor
	
	variable num_folders = countobjects(data_folder, 4)
	for(i = 0; i < num_folders; i += 1)
		if (num_folders == 0)
			break
		endif
		// create folders
		data_folder2 = data_folder + ":" + getindexedobjname(data_folder, 4, i)
		splitstring/e=(expr) data_folder2, data_path2
		data_path = initial_data_path + ":" + data_path2
		newpath/c/o/q data, data_path
		
		unpack_experiment(data_folder2)
	endfor
	
	// create experiment folder on hd
	//string day, month, year, experiment
	//string expr = "root:data:([[:alpha:]]+)_([[:digit:]]+):day_([[:digit:]]+):(.+)"
	//splitstring/e=(expr) data_folder, month, year, day, experiment
	//newpath/c/o/q data, initial_data_path
	//string data_path = initial_data_path + ":" + month + "_" + year
	//newpath/c/o/q data, data_path
	//data_path += ":day_" + day
	//newpath/c/o/q data, data_path
	//data_path += ":" + experiment
	//newpath/c/o/q data, data_path
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
	pathinfo data
	if (v_flag == 0)
		abort "define paths"
	endif
	string initial_data_path = s_path
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