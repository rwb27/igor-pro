#pragma IndependentModule = visa
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

function check_folder(data_folder)
	string data_folder
	if (!datafolderexists(data_folder))
		newdatafolder $data_folder
	endif
end

function open_comms(hardware_id, resourceName)
	string hardware_id, resourceName
	variable session, instr, status
	string data_folder = "root:global_variables"
	check_folder(data_folder)
	data_folder += ":" + hardware_id
	check_folder(data_folder)
	
	string error_message
	status = viOpenDefaultRM(session)
	if (status < 0)
		viStatusDesc(instr, status, error_message)
		abort "OpenDefaultRM error: " + error_message
	endif
	status = viOpen(session, resourceName, 0, 0, instr)
	if (status < 0)
		viStatusDesc(instr, status, error_message)
		abort "Open error: " + error_message
	endif
	//status = viClear(session)
	//if (status < 0)
	//	viStatusDesc(instr, status, error_message)
	//	abort "Clear error: " + error_message
	//endif
    
	variable/g $(data_folder + ":instr") = instr
	variable/g $(data_folder + ":session") = session
	return status
end

function close_comms(hardware_id)
	string hardware_id
	nvar session = $("root:global_variables:" + hardware_id + ":session")
	nvar instr = $("root:global_variables:" + hardware_id + ":instr")
	variable status
	string error_message
	//status = viClear(session)
	//if (status < 0)
	//    viStatusDesc(instr, status, error_message)
	//    abort "Clear error: " + error_message
	//endif
	status = viClose(session)
	if (status < 0)
		viStatusDesc(instr, status, error_message)
		abort "Close error: " + error_message
	endif
	return status
end

function cmd(hardware_id, cmd)
	string hardware_id, cmd
	nvar instr = $("root:global_variables:" + hardware_id + ":instr")
	VISAwrite instr, cmd
end

function read(hardware_id, cmd)
	string hardware_id, cmd
	variable value
	nvar instr = $("root:global_variables:" + hardware_id + ":instr")
	VISAwrite instr, cmd
	VISAread instr, value
	return value
end

function/s read_str(hardware_id, cmd)
	string hardware_id, cmd
	string message
	nvar instr = $("root:global_variables:" + hardware_id + ":instr")
	VISAwrite instr, cmd
	VISAread/t="\n" instr, message //  possibly use /t="\n"
	return message
end