#pragma rtGlobals=1		// Use modern global access method.
//
// v2, 12/02/13, AS
//

// required functions

function check_folder_siggen(data_folder)
	string data_folder
	if (!datafolderexists(data_folder))
		newdatafolder $data_folder
	endif
end

function open_siggen()
	variable session, instr, status
	string resourceName = "GPIB0::3::INSTR"
	string data_folder = "root:global_variables"
	check_folder_siggen(data_folder)
	data_folder += ":hp33120a_signal_generator"
	check_folder_siggen(data_folder)
	
	status = viOpenDefaultRM(session)
	if (status < 0)
		string error_message
		viStatusDesc(instr, status, error_message)
		abort error_message
	endif
	status = viOpen(session, resourceName, 0, 0, instr)
	if (status < 0)
		string error_message
		viStatusDesc(instr, status, error_message)
		abort error_message
	endif
	status = viClear(session)
	if (status < 0)
		string error_message
		viStatusDesc(instr, status, error_message)
		abort error_message
	endif
	variable/g $(data_folder + ":instr") = instr
	variable/g $(data_folder + ":session") = session
	return status
end

function close_siggen()
	nvar session = root:global_variables:hp33120a_signal_generator:session
	variable status
	status = viClear(session)
	if (status < 0)
		string error_message
		viStatusDesc(instr, status, error_message)
		abort error_message
	endif
	status = viClose(session)
	if (status < 0)
		string error_message
		viStatusDesc(instr, status, error_message)
		abort error_message
	endif
	return status
end

function cmd_siggen(cmd)
	string cmd
	nvar instr = root:global_variables:hp33120a_signal_generator:instr
	VISAwrite instr, cmd
end

function read_siggen(cmd)
	string cmd
	variable value
	nvar instr = root:global_variables:hp33120a_signal_generator:instr
	VISAwrite instr, cmd
	VISAread instr, value
	return value
end

function/s read_str_siggen(cmd)
	string cmd
	string message
	nvar instr = root:global_variables:hp33120a_signal_generator:instr
	VISAwrite instr, cmd
	VISAread/t="\n" instr, message
	return message
end

// setup functions

function set_frequency_siggen(freq)
	variable freq
	cmd_siggen("FREQ " + num2str(freq) + "\n")
end

function set_amplitude_siggen(volt)
	variable volt
	cmd_siggen("output:load inf")
	cmd_siggen("voltage " + num2str(volt) + "\n")
end

function set_offset_siggen(offset)
	variable offset
	cmd_siggen("voltage:offset " + num2str(offset) + "\n")
end