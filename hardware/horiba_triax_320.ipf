#pragma ModuleName = triax
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "visa"
static strconstant hardware_id = "horiba_triax_320"
static strconstant resourceName = ""
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
		if (stringmatch(buffer, "*"))						// first time power-up or reboot
			buffer = visa#read_binary(hardware_id, 247)
			sleep/s 0.5
			print buffer								// should be "=" if in intelligent comms mode
		elseif (stringmatch(buffer, "B"))					// talking to boot program
			nvar instr = $(gv_folder + ":instr")
			make/free/n=6 cmd_wave
			cmd_wave = {char2num("O"), char2num("2"), char2num("0"), char2num("0"), char2num("0"), 0}
			visawritebinarywave instr, cmd_wave		// transfer to main program
			sleep/s 0.5
		elseif (stringmatch(buffer, "F"))					// talking to main program
			break									// break once in the main program
		elseif (stringmatch(buffer, num2char(27)))		// escape char: comms previously established in hand-held terminal mode
			buffer = visa#write_binary(hardware_id, 248)	// sets to intelligent comms mode
			sleep/s 0.5
		else
			buffer = visa#write_binary(hardware_id, 248)	// sets to intelligent comms mode
			sleep/s 0.5
			buffer = visa#write_binary(hardware_id, 222)	// reboots if hung
			sleep/s 0.5
		endif
	while (1)
end

static function reset()
	initialise()
	if (stringmatch(visa#read_str(hardware_id, "A"), "o"))
		print "motors initialised"
	else
		print "error: motor initialisation failed"
	endif
end

static function move(wavelength)
	variable wavelength
	return wavelength
end

static function set_slit_size(size)
	variable size
	return size
end