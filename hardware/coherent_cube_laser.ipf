#pragma rtGlobals=1		// Use modern global access method.
//
// v2, 07/02/13, AS
//

// required functions

menu "Coherent Cube"
	"initialise cube", /Q, init_cube()
end

function check_folder_cube(data_folder)
	string data_folder
	if (!datafolderexists(data_folder))
		newdatafolder $data_folder
	endif
end

function open_cube()
	VDT2/P=COM1 baud=19200, stopbits=1, databits=8, parity=0, terminalEOL=0
	VDTOperationsPort2 COM1
	VDTOpenPort2 COM1
	string data_folder = "root:global_variables"
	check_folder_cube(data_folder)
	data_folder += ":coherent_cube"
	check_folder_cube(data_folder)
	return 0
end

function close_cube()
	VDTOperationsPort2 None
	VDTClosePort2 COM1
	return 0
end

function cmd_cube(cmd)
	string cmd
	//status = opencommsShtr(hShtr)
	VDTWrite2/o=3 cmd + "\r"
	sleep/q/t 10
	//status = closecommsShtr(hShtr)
end

function read_cube(cmd)
	string cmd
end

function/s read_str_cube(cmd)
	string cmd
	string message
  	VDTread2/t="\r"/o=3 message
	return message
end

// control functions

function/s status_cube()
	string status = read_str_cube("?STA")
	return status
end

function read_nom_power_cube()
	string power_str = read_str_cube("?NOMP")
	variable power
	sscanf power_str, "NOMP=%f", power
	return power
end

function read_power_cube()
	string power_str = read_str_cube("?P")
	variable power
	sscanf power_str, "P=%f", power
	return power
end

function set_power_cube(power)
	variable power
	if (power >= 25)
		abort "red cube: max power = 25 mW"
	endif
	cmd_cube("P=" + num2str(power))
	sleep/t 30
	variable/g root:global_variables:coherent_cube:power = power
end

// other functions

function pending_read_cube()
	VDTgetstatus2 0, 0, 0
	return V_VDT
end

function purge_cube()
	VDTgetstatus2 0, 1, 1
	if ((V_VDT %& 1) != 0)
		abort "serial port overrun error occurred"
	elseif (V_VDT != 0)
		print "serial error code: %0X\r", V_VDT
		abort "serial port error"
	endif
end

function init_cube()
	open_cube()
	cmd_cube("EXT=0")
	set_power_cube(0)
end