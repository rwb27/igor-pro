#pragma ModuleName = triax
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "visa_comms"
static strconstant hardware_id = "horiba_triax_320"
static strconstant resourceName = "GPIB0::1::INSTR"
static strconstant gv_folder = "root:global_variables:horiba_triax_320"

static function open_comms()
	variable status
	status = visa#open_comms(hardware_id, resourceName)
	return status
end

static function close_comms()
	variable status
	status = visa#close_comms(hardware_id)
	return status
end

static function/s gv_path()
	return gv_folder
end

static function initialise()
	string buffer
	do
		buffer = visa#read_str(hardware_id, " ")			// send autobaud character "<space>" for status
		print buffer
		if (char2num(buffer) == 42)						// * char: first time power-up or reboot
			buffer = visa#read_binary(hardware_id, 247)
			sleep/s 0.5
			print buffer								// should be "=" if in intelligent comms mode
		elseif (stringmatch(buffer, "B"))					// talking to boot program
			nvar instr = $(gv_folder + ":instr")
			make/free/n=6 cmd_wave= {char2num("O"), char2num("2"), char2num("0"), char2num("0"), char2num("0"), 0}
			visawritebinarywave instr, cmd_wave		// transfer to main program
			sleep/s 0.5
		elseif (stringmatch(buffer, "F"))					// talking to main program
			break									// break once in the main program
		elseif (char2num(buffer) == 27)		// escape char: comms previously established in hand-held terminal mode
			visa#write_binary(hardware_id, 248)	// sets to intelligent comms mode
			sleep/s 0.5
		else
			visa#write_binary(hardware_id, 248)	// sets to intelligent comms mode
			sleep/s 0.5
			visa#write_binary(hardware_id, 222)	// reboots if hung
			sleep/s 0.5
		endif
	while (1)
end

static function reset()
	initialise()
	string buffer = visa#read_str(hardware_id, "A\r")
	do
		sleep/s 1
		buffer = visa#read_only(hardware_id)
	while (stringmatch(buffer, ""))
	if (stringmatch(buffer, "o"))
		print "motors initialised"
	else
		print "error: motor initialisation failed"
	endif
end

static function set_entrance(port)
	variable port
	string buffer
	if (port == 0)
		buffer = visa#read_str(hardware_id, "d0\r")
		sleep/s 4
	elseif (port == 1)
		buffer = visa#read_str(hardware_id, "c0\r")
		sleep/s 4
	endif
	if (stringmatch(buffer, "o"))
		return 0
	else
		return -1
	endif
end

static function set_slit_size(size)
	variable size
	return size
end

static function set_grating(grating)
	variable grating
	if (grating == 0)
		visa#cmd(hardware_id, "Z451,0,0,0,0\r")
	elseif (grating == 1)
		visa#cmd(hardware_id, "Z451,0,0,0,1\r")
	elseif (grating == 2)
		visa#cmd(hardware_id, "Z451,0,0,0,2\r")
	endif
	return 0
end

static function move(wavelength)
	variable wavelength
	return wavelength
end