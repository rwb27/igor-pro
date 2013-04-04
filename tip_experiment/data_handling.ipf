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
	// folders refer to Igor while paths refer to local folders
	string data_folder				// everything in this folder will be copied to the hard drive
	string data_folder_rel			// current igor folder being unpacked relative to the data folder
	dfref data_folder_path = $data_folder		// full path to current folder
	string current_data_path		// current local folder where data is being deposited
	
	// check that local data path is defined
	pathinfo data
	if (v_flag == 0)			// abort if data path does not exist
		abort "define paths"
	endif
	string initial_data_path = s_path	// top local folder for data storage
	
	// define string splitting
	string expr = "root:data:(.+)"
	variable i
	
	// set current paths/folders
	splitstring/e=(expr) data_folder, data_folder_rel			// get relative folder path
	current_data_path = initial_data_path + data_folder_rel	// set current data path
	newpath/c/o current_data, current_data_path				// create and reference local folder
	
	if (waveexists(data_folder_path:parameters))
		killwaves data_folder_path:parameters
	endif
	
	variable j = 0
	// transfer variables in current folder to a text wave
	variable num_vars = countobjectsdfr(data_folder_path, 2)
	if (num_vars != 0)
		if (!waveexists(data_folder_path:parameters))
			make/t/o/n=(0, 2) data_folder_path:parameters
		endif
		wave/t params = data_folder_path:parameters
		string vname
		for(i = j; i < j + num_vars; i += 1)
			// save variables to wave
			nvar/sdfr=data_folder_path v = $getindexedobjnamedfr(data_folder_path, 2, i)
			vname = getindexedobjname(data_folder, 2, i)
			redimension/n=(dimsize(params, 0)+1, 2) params
			params[i][0] = vname
			params[i][1] = num2str(v)
		endfor
	endif
	
	// transfer strings in current folder to a text wave
	variable num_strs = countobjectsdfr(data_folder_path, 3)
	if (num_strs != 0)
		if (!waveexists(data_folder_path:parameters))
			make/t/o/n=(0, 2) data_folder_path:parameters
		endif
		wave/t params = data_folder_path:parameters
		string sname
		for(i = j; i < j + num_strs; i += 1)
			// save strings to wave
			svar/sdfr=data_folder_path s = $getindexedobjnamedfr(data_folder_path, 3, i)
			sname = getindexedobjname(data_folder, 3, i)
			redimension/n=(dimsize(params, 0)+1, 2) params
			params[i][0] = sname
			params[i][1] = s
		endfor
	endif
	
	// transfer waves in current folder to current data path
	variable num_waves = countobjectsdfr(data_folder_path, 1)
	if (num_waves != 0)
		string wname
		for(i = 0; i < num_waves; i += 1)
			// save waves
			wave w = data_folder_path:$getindexedobjnamedfr(data_folder_path, 1, i)
			wname = getindexedobjname(data_folder, 1, i)
			save/p=current_data/c/o w as wname + ".ibw"
			save/t/p=current_data/o w as wname + ".itx"
		endfor
	endif
	
	// transfer folders in current folder to current data path
	string new_data_folder
	variable num_folders = countobjectsdfr(data_folder_path, 4)
	if (num_folders != 0)
		for(i = 0; i < num_folders; i += 1)
			// create folders
			new_data_folder = data_folder + ":" + getindexedobjnamedfr(data_folder_path, 4, i)		
			unpack_experiment(new_data_folder)
		endfor
	endif
end

function load_tip_experiment(tip_exp)
	string tip_exp							// location of tip experiment data structure
	
	// parse string into components to reconstruct in the Igor data browser
	// example: ":raw data:Nov 2012:day 21:tip experiment"
	string expr = ":([[:alpha:]]+)_([[:digit:]]+):day_([[:digit:]]+):(.+)"
	string month, year, day, experiment
	splitstring/e=(expr) tip_exp, month, year, day, experiment
	string data_folder = "root:data"; check_folder(data_folder)
	data_folder += ":" + month + "_" + year; check_folder(data_folder)
	data_folder += ":day_" + day; check_folder(data_folder)
	data_folder += ":" + experiment; killdatafolder data_folder; check_folder(data_folder)
	
	pathinfo data
	if (v_flag == 0)
		abort "define paths"
	endif
	
	string initial_data_path = s_path
	newpath/o/q data, initial_data_path
	loadwave/h/o/q/p=data tip_exp + ":spectra2D.ibw"
	loadwave/h/o/q/p=data tip_exp + ":tipConductance.ibw"
	loadwave/h/o/q/p=data tip_exp + ":tipVoltage.ibw"
	loadwave/h/o/q/p=data tip_exp + ":tipCurrent.ibw"
	loadwave/h/o/q/p=data tip_exp + ":PZdisplacement.ibw"
	loadwave/h/o/q/p=data tip_exp + ":wavelengthImageAxis.ibw"
	loadwave/h/o/q/p=data tip_exp + ":xPSD.ibw"
	loadwave/h/o/q/p=data tip_exp + ":yPSD.ibw"
	movewave :spectra2D, $(data_folder +":")
	movewave :tipConductance, $(data_folder +":")
	movewave :tipVoltage, $(data_folder +":")
	movewave :tipCurrent, $(data_folder +":")
	movewave :PZdisplacement, $(data_folder +":")
	movewave :wavelengthImageAxis, $(data_folder +":")
	movewave :xPSD, $(data_folder +":")
	movewave :yPSD, $(data_folder +":")
end