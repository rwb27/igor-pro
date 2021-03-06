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
	string data_folder = "root:global_variables"
	check_folder(data_folder)
	data_folder += ":" + hardware_id
	check_folder(data_folder)
	nvar/z session = $("root:global_variables:" + hardware_id + ":session")
	nvar/z instr = $("root:global_variables:" + hardware_id + ":instr")
	if (!nvar_exists(instr))
		variable/g $("root:global_variables:" + hardware_id + ":instr") = -1
	endif
	if (!nvar_exists(session))
		variable/g $("root:global_variables:" + hardware_id + ":session") = -1
	endif
	nvar session = $("root:global_variables:" + hardware_id + ":session")
	nvar instr = $("root:global_variables:" + hardware_id + ":instr")
	
	if (session != -1 || instr != -1)
		print hardware_id, ": comms already open:", session, instr
	endif
	
	variable status, instr_id = session, session_id = session
	string error_message
	status = viOpenDefaultRM(session_id)
	if (status < 0)
		viStatusDesc(instr_id, status, error_message)
		abort "OpenDefaultRM error: " + error_message
	endif
	status = viOpen(session_id, resourceName, 0, 0, instr_id)
	if (status < 0)
		viStatusDesc(instr_id, status, error_message)
		abort "Open error: " + error_message
	endif
    	session = session_id; instr = instr_id
    
	return status
end

function close_comms(hardware_id)
	string hardware_id
	nvar/z session = $("root:global_variables:" + hardware_id + ":session")
	nvar/z instr = $("root:global_variables:" + hardware_id + ":instr")
	if (!nvar_exists(instr))
		variable/g $("root:global_variables:" + hardware_id + ":instr") = -1
	endif
	if (!nvar_exists(session))
		variable/g $("root:global_variables:" + hardware_id + ":session") = -1
	endif
	
	// check if comms are already closed
	if (session == -1 || instr == -1)
		print hardware_id, ": comms already closed"
		return 0
	endif
	
	variable session_id = session, instr_id = instr, status
	string error_message
	status = viClose(session_id)
	if (status < 0)
		viStatusDesc(instr_id, status, error_message)
		abort "Close error: " + error_message
	endif
	
	session = -1; instr = -1
	return status
end

function cmd(hardware_id, cmd)
	string hardware_id, cmd
	nvar instr = $("root:global_variables:" + hardware_id + ":instr")
	VISAwrite instr, cmd
	return 0
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
	VISAread/t=",\r\n"/n=500 instr, message //  possibly use /t="\n", /n=500 for tek
	return message
end

function/s read_only(hardware_id)
	string hardware_id
	string message
	nvar instr = $("root:global_variables:" + hardware_id + ":instr")
	VISAread/t="\n" instr, message //  possibly use /t="\n"
	return message
end

function write_binary(hardware_id, cmd)
	string hardware_id
	variable cmd
	nvar instr = $("root:global_variables:" + hardware_id + ":instr")
	VISAwritebinary instr, cmd
	return 0
end

function/s read_binary(hardware_id, cmd)
	string hardware_id
	variable cmd
	nvar instr = $("root:global_variables:" + hardware_id + ":instr")
	VISAwritebinary instr, cmd
	string message
	VISAread/t="\n" instr, message //  possibly use /t="\n"
	return message
end