#pragma ModuleName = data
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

// These are only needed in some cases
#include "tip_alignment"

static strconstant gv_folder = "root:global_variables:data_handling"
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
	data_folder = removeending(data_folder, ":")
	string df_rel = ""
	variable k = 1
	do
		df_rel = removeending(parsefilepath(1, data_folder, ":", 0, k), ":")
		if (stringmatch(df_rel, ""))
			break
		elseif (stringmatch(df_rel,"root"))
			k += 1
			continue
		endif
		if (!datafolderexists(df_rel))
			newdatafolder $df_rel
		endif	
		k += 1
	while (!stringmatch(df_rel, data_folder))
	if (!datafolderexists(data_folder))
		newdatafolder $data_folder
	endif
	return data_folder
end

function/s check_path(path, pathname)
	string path, pathname
	path = removeending(path, ":")
	string path_rel = ""
	variable k = 1
	do
		path_rel = removeending(parsefilepath(1, path, ":", 0, k), ":")
		if (stringmatch(path_rel, ""))
			break
		elseif (stringmatch(path_rel,"root"))
			k += 1
			continue
		endif
		newpath/c/o/q temp, path_rel
		k += 1
	while (!stringmatch(path_rel, path))
	newpath/c/o/q $pathname, path
	return pathname
end

function/s check_gvpath(gv_folder)
	string gv_folder
	check_folder("root:global_variables")
	check_folder(gv_folder)
	return gv_folder
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
	
	print "saving", data_folder
	
	// define string splitting
	string expr = "root:data:(.+)"
	// set current paths/folders
	splitstring/e=(expr) data_folder, data_folder_rel			// get relative folder path
	// check all of relative folder path exists
	string df_rel = ""
	variable k
	do
		df_rel += parsefilepath(0, data_folder_rel, ":", 0, k) + ":"
		if (stringmatch(df_rel, ":"))
			break
		endif
		current_data_path = initial_data_path + df_rel
		newpath/c/o/q current_data, current_data_path	
		k += 1
	while (!stringmatch(df_rel, data_folder_rel+":"))
	
	//current_data_path = initial_data_path + data_folder_rel	// set current data path
	//newpath/c/o current_data, current_data_path				// create and reference local folder
	
	if (waveexists(data_folder_path:parameters))
		killwaves data_folder_path:parameters
	endif
	
	variable i
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
	
	j = i
	// transfer strings in current folder to a text wave
	variable num_strs = countobjectsdfr(data_folder_path, 3)
	if (num_strs != 0)
		if (!waveexists(data_folder_path:parameters))
			make/t/o/n=(0, 2) data_folder_path:parameters
		endif
		wave/t params = data_folder_path:parameters
		string sname
		for(i = 0; i < num_strs; i += 1)
			// save strings to wave
			svar/sdfr=data_folder_path s = $getindexedobjnamedfr(data_folder_path, 3, i)
			sname = getindexedobjname(data_folder, 3, i)
			redimension/n=(dimsize(params, 0)+1, 2) params
			params[i+j][0] = sname
			params[i+j][1] = s
		endfor
	endif
	
	// transfer waves in current folder to current data path
	if (waveexists(data_folder_path:wave_list))
		killwaves data_folder_path:wave_list
	endif
	if (waveexists(data_folder_path:path_list))
		killwaves data_folder_path:path_list
	endif
	variable num_waves = countobjectsdfr(data_folder_path, 1)
	if (num_waves != 0)
		make/t/o/n=0 data_folder_path:wave_list
		wave/t wave_list = data_folder_path:wave_list
		string wname
		for(i = 0; i < num_waves; i += 1)
			// save waves
			wave w = data_folder_path:$getindexedobjnamedfr(data_folder_path, 1, i)
			wname = getindexedobjname(data_folder, 1, i)
			save/p=current_data/c/o w as wname + ".ibw"
			save/t/p=current_data/o w as wname + ".itx"
			// append to wave list
			redimension/n=(dimsize(wave_list, 0)+1) wave_list
			wave_list[i] = wname
		endfor
		save/p=current_data/c/o wave_list as "wave_list.ibw"
		save/t/p=current_data/o wave_list as "wave_list.itx"
	endif
	
	// transfer folders in current folder to current data path
	string new_data_folder, new_data_folder_rel
	variable num_folders = countobjectsdfr(data_folder_path, 4)
	if (num_folders != 0)
		if (!waveexists(data_folder_path:path_list))
			make/t/o/n=0 data_folder_path:path_list
		endif
		wave/t path_list = data_folder_path:path_list
		for(i = 0; i < num_folders; i += 1)
			// create folders
			new_data_folder = data_folder + ":" + getindexedobjnamedfr(data_folder_path, 4, i)
			if (!stringmatch(new_data_folder, "*spectra*"))		
				unpack_experiment(new_data_folder)
			endif
			// append to path list
			redimension/n=(dimsize(path_list, 0)+1) path_list
			splitstring/e=(expr) new_data_folder, new_data_folder_rel
			path_list[i] = new_data_folder_rel
		endfor
		newpath/c/o/q current_data, current_data_path
		save/p=current_data/c/o path_list as "path_list.ibw"
		save/t/p=current_data/o path_list as "path_list.itx"
	endif
end

function load_experiment(data_path_rel)
	// folders refer to Igor while paths refer to local folders
	string data_path_rel				// relative path to the folder from which data will be loaded
	//dfref current_folder
	
	// check that local data path is defined
	pathinfo data
	if (v_flag == 0)			// abort if data path does not exist
		abort "define paths"
	endif
	
	print "loading", data_path_rel
	
	check_folder("root:data")		// check that the initial data storage folder exists
	dfref initial_data_folder = root:data	// initial igor folder for data storage
	string initial_data_folder_str = "root:data"	// initial igor folder for data storage
	string initial_data_path = s_path	// top local folder for data storage	
	// set full paths
	string full_data_path = initial_data_path + data_path_rel	// ful folder path on hd
	newpath/o/q current_data, full_data_path
	
	// copy folder structure up to the current folder into igor
	string full_data_folder_str = initial_data_folder_str + ":" + data_path_rel	// full folder path in igor
	string df_rel = "", df_full
	variable k = 0
	do
		df_rel += parsefilepath(0, data_path_rel, ":", 0, k) + ":"
		if (stringmatch(df_rel, ":"))
			break
		endif
		df_full = initial_data_folder_str + ":" + df_rel
		check_folder(df_full)
		dfref current_folder = $df_full
		k += 1
	while (!stringmatch(df_rel, data_path_rel + ":"))
	dfref full_data_folder = $full_data_folder_str	// full folder path in igor
	
	// load files into folder structure
	variable i
	
	// load waves if waves_list exists
	loadwave/w/a/h/o/q/p=current_data "wave_list.ibw"			// load wave_list
	if (waveexists(wave_list))
		duplicate/o wave_list, full_data_folder:wave_list
		killwaves wave_list
	endif
	if (waveexists(full_data_folder:wave_list))
		// parse wave_list
		wave/t/sdfr=full_data_folder wave_list
		variable num_waves = numpnts(wave_list)
		string wname
		for(i = 0; i < num_waves; i += 1)
			wname = wave_list[i]
			loadwave/w/a/h/o/q/p=current_data wname+".ibw"
			duplicate/o $wname, full_data_folder:$wname
			killwaves $wname
		endfor
		killwaves full_data_folder:wave_list
	endif
	
	// convert parameters wave into global variables
	if (waveexists(full_data_folder:parameters))
		wave/t/sdfr=full_data_folder parameters
	endif
	
	// load folders in current path to current folder
	loadwave/h/o/q/p=current_data "path_list.ibw"			// load path_list
	if (waveexists(path_list))
		duplicate/o path_list, full_data_folder:path_list
		killwaves path_list
	endif
	if (waveexists(full_data_folder:path_list))
		// parse path_list
		wave/t/sdfr=full_data_folder path_list
		variable num_paths = numpnts(path_list)
		string new_data_path
		for(i = 0; i < num_paths; i += 1)
			// load paths
			new_data_path = path_list[i]	
			load_experiment(new_data_path)
		endfor
		killwaves full_data_folder:path_list
	endif
end

function update_experiment(data_folder)
	// folders refer to Igor while paths refer to local folders
	string data_folder				// everything in this folder will be copied to the hard drive
	dfref data_folder_path = $data_folder		// full path to current folder
	
	variable i
	
	// update wave analysis
	variable num_waves = countobjectsdfr(data_folder_path, 1)
	if (num_waves != 0)
		string wname
		for(i = 0; i < num_waves; i += 1)
			// load wave
			wave w = data_folder_path:$getindexedobjnamedfr(data_folder_path, 1, i)
			wname = getindexedobjnamedfr(data_folder_path, 1, i)
			
			// update wave analysis
			// resonance scans
			if (stringmatch(wname, "*resonance_scan*"))
				nvar/z/sdfr=data_folder_path alignment_set
				if (!nvar_exists(alignment_set))
					variable/g data_folder_path:alignment_set = 0
				endif
			endif
			if (stringmatch(wname, "*resonance_scan_r"))
				nvar/z/sdfr=data_folder_path electronic_alignment
				if (!nvar_exists(electronic_alignment))
					variable/g data_folder_path:electronic_alignment = 1
				endif
			endif
			if (stringmatch(wname, "*resonance_scan_fr"))
				nvar/z/sdfr=data_folder_path force_alignment
				if (!nvar_exists(force_alignment))
					variable/g data_folder_path:force_alignment = 1
				endif
			endif
			// alignment scans
			if (stringmatch(wname, "*alignment_scan*"))
				string df = getdatafolder(1, data_folder_path)
				alignment#fit_alignment_data(data_folder_path, w)
				nvar/z/sdfr=data_folder_path alignment_set
				if (!nvar_exists(alignment_set))
					variable/g data_folder_path:alignment_set = 0
				endif
			endif
			if (stringmatch(wname, "*alignment_scan_r"))
				nvar/z/sdfr=data_folder_path electronic_alignment
				if (!nvar_exists(electronic_alignment))
					variable/g data_folder_path:electronic_alignment = 1
				endif
			endif
			if (stringmatch(wname, "*alignment_scan_fr"))
				nvar/z/sdfr=data_folder_path force_alignment
				if (!nvar_exists(force_alignment))
					variable/g data_folder_path:force_alignment = 1
				endif
			endif
		endfor
	endif
	
	// update sub-folders
	string new_data_folder
	variable num_folders = countobjectsdfr(data_folder_path, 4)
	if (num_folders != 0)
		for(i = 0; i < num_folders; i += 1)
			// create folders
			new_data_folder = data_folder + ":" + getindexedobjnamedfr(data_folder_path, 4, i)		
			update_experiment(new_data_folder)
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

// Panel //

static function check_data_folder_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch(ba.eventcode)
		case 2:
			data#check_data_folder()
			break
	endswitch
	return 0
end

static function unpack_experiment_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch(ba.eventcode)
		case 2:
			svar/sdfr=$gv_folder data_folder
			data#unpack_experiment(data_folder)
			break
	endswitch
	return 0
end

function data_handling_panel() : panel

	check_folder("root:global_variables")
	check_folder(gv_folder)
	string/g scan_folder = "root:"
	
	variable left, right, top, bottom
	dowindow/k data_panel
	newpanel/w=(100,50,400,160)/n=data_panel as "Data Handling"
	modifypanel cbRGB=(60928,60928,60928), framestyle=1
	setdrawlayer UserBack
	showtools/a
	// title
	left = 5; top = 5
	titlebox title, pos={left, top}, size={60,25}, title="Data Handling", fsize=14, fstyle=1, frame=0
	top += 25
	// variables
	popupmenu set_path_definition, pos={left, top}, size={95,15}, bodywidth=70, title="Path",value="lab;laptop"
	popupmenu set_path_definition fSize=11, proc=define_path
	top += 25
	setvariable set_datafolder, pos={left, top}, size={290,20}, title="Data Folder"
	setvariable set_datafolder, fSize=11
	setvariable set_datafolder, value= scan_folder
	// buttons
	top += 20
	button unpack_exp, pos={left, top}, size={50,30}, proc=data#unpack_experiment_button, title="Unpack\rFolder"
	button unpack_exp, fColor=(32768,65280,0)
	//top += 40
	left += 50
	button check_df, pos={left, top}, size={60,30}, proc=data#check_data_folder_button, title="Check\rDataFolder"
	top += 40
end