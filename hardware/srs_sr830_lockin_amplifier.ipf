#pragma rtGlobals=1		// Use modern global access method.
//
// v2, 07/02/13, AS
//

// required functions

function check_folder_lockin(data_folder)
	string data_folder
	if (!datafolderexists(data_folder))
		newdatafolder $data_folder
	endif
end

function open_lockin()
	variable session, instr, status
	string resourceName = "GPIB0::6::INSTR"
	string data_folder = "root:global_variables"
	check_folder_lockin(data_folder)
	data_folder += ":srs_sr830_lockin_amplifier"
	check_folder_lockin(data_folder)
	status = viOpenDefaultRM(session)
	status = viOpen(session, resourceName, 0, 0, instr)
	status = viClear(session)
	variable/g $(data_folder + ":instr") = instr
	variable/g $(data_folder + ":session") = session
	return status
end

function close_lockin()
	nvar session = root:global_variables:srs_sr830_lockin_amplifier:session
	variable status = viClose(session)
	status = viClear(session)
	return status
end

function cmd_lockin()
	string cmd
	nvar instr = root:global_variables:srs_sr830_lockin_amplfiier:instr
	VISAwrite instr, cmd
end

function read_lockin(cmd)
	string cmd
	variable value
	nvar instr = root:global_variables:srs_sr830_lockin_amplifier:instr
	VISAwrite instr, cmd
	VISAread instr, value
	return value
end

function/s read_str_lockin(cmd)
	string cmd
	string message
	nvar instr = root:global_variables:srs_sr830_lockin_amplifier:instr
	VISAwrite instr, cmd
	VISAread instr, message
	return message
end

// measurement functions

function/c measure_xy_lockin()
	variable x, y
	variable/c data
	x = read_lockin("OUTP?1\r")
	y = read_lockin("OUTP?2\r")
	data = cmplx(x, y)
	return data
end

function/c measure_rtheta_lockin()
	variable r, theta
	variable/c data
	r = read_lockin("OUTP?3\r")
	theta = read_lockin("OUTP?4\r")
	data = cmplx(r, theta)
	return data
end

// useful functions

function purge_lockin()
	nvar instr = root:global_variables:srs_sr830_lockin_amplifier:instr
	string buffer
	do
		VISAread instr, buffer
	while (!stringmatch(buffer, ""))
end