#pragma ModuleName = data
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

strconstant initial_data_path = "c:users:hera:desktop:tip_exp:data"

function/s check_folder(data_folder)
	string data_folder
	if (!datafolderexists(data_folder))
		newdatafolder $data_folder
	endif
	return data_folder
end

function/s check_data_folder()
	string day, month, year
	day=date()[0,1], month=date()[3,5], year=date()[7,10]
	string data_folder = "root:data"
	check_folder(data_folder)
	data_folder += ":" + month + "_" + year
	check_folder(data_folder)
	data_folder += ":day_" + day
	check_folder(data_folder)
	return data_folder
end

function/s data_path(fname)
	string fname
	string day, month, year
	day=date()[0,1], month=date()[3,5], year=date()[7,10]
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