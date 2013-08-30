#pragma rtGlobals=3		// Use modern global access method and strict wave access.

static strconstant gv_folder = "root:global_variables:data_handling"
// These folders must exist
strconstant initial_data_path_lab = "C:Users:Hera:Desktop:tip_exp:raw_data"
strconstant initial_data_path_laptop = "C:Users:Alan:Documents:0 - PhD:0 - experiment:raw data"

// This must be run first
function define_paths(pc)
	string pc
	if (stringmatch(pc, "lab"))
		newpath/c/o/q data, initial_data_path_lab
	elseif (stringmatch(pc, "laptop"))
		newpath/c/o/q data, initial_data_path_laptop
	endif
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

function save_data(df)
	dfref df
	pathinfo data
	if (v_flag == 0)
		abort "define paths"
	endif
	string original_path = s_path
	setdatafolder df
	// split root off front and current data folder off back
	string current_df = parsefilepath(1, getdatafolder(1), ":", 1, 0)[5,strlen(getdatafolder(1))]
	check_path(original_path+current_df, "data")
	print "saving to", original_path+current_df
	savedata/d/o /p=data/r/t ":"
	savedata/o /p=data/r/t getdatafolder(0)+".pxp"
	setdatafolder root:
	newpath/c/q/o data, original_path
end