#pragma ModuleName = pi_stage
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "visa"
static strconstant hardware_id = "pi_pi733_3cd_stage"
static strconstant resourceName = "ASRL2::INSTR"
static strconstant gv_folder = "root:global_variables:pi_pi733_3cd_stage"

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

static function initialise()
	variable/g $(gv_folder + ":pos_a"), $(gv_folder + ":pos_b"), $(gv_folder + ":pos_c")
	variable/g $(gv_folder + ":step_a"), $(gv_folder + ":step_b"), $(gv_folder + ":step_c")
	get_pos()
	get_velocity()
end

static function/s gv_path()
	return gv_folder
end

function startup()
	visa#cmd(hardware_id, "onl 1\n")
	sleep/s 0.5
	close_loop()
	sleep/s 0.5
	zero_stage_pos()
end

function shutdown()
	zero_stage_pos()
	sleep/s 20.0
	open_loop()
	sleep/s 0.5
	visa#cmd(hardware_id, "onl 0\n")
end

// set pi stage to 'closed-loop' operation (required for 'move_pi' command to work)
function close_loop()
	visa#cmd(hardware_id, "svo a1\n")
	visa#cmd(hardware_id, "svo b1\n")
	visa#cmd(hardware_id, "svo c1\n")
end

// set pi stage to 'open-loop' operation
// (always run before turning the controller to 'offline mode' and then powering down)
function open_loop()
	visa#cmd(hardware_id, "svo a0\n")
	visa#cmd(hardware_id, "svo b0\n")
	visa#cmd(hardware_id, "svo c0\n")
end

static function move(ch, pos)
	string ch
	variable pos
	if  ((stringmatch(ch, "A") == 1) || (stringmatch(ch, "B") == 1))		//Stops the stage being commanded to move beyond its limits of movement	
		if ((pos < 0) || (pos >= 100))
	    		abort "out of range (x, y)"
		endif
	else
		if ((pos < 0) || (pos >= 10))
	    		abort "out of range (z)"
		endif
	endif
	visa#cmd(hardware_id, "mov " + ch + num2str(pos) + "\n")
	variable/g $(gv_folder + ":pos_" + ch) = visa#read(hardware_id, "pos? " + ch + "\n")
end

function move_rel(ch, rpos)
	string ch
	variable rpos
	visa#cmd(hardware_id, "mvr " + ch + num2str(rpos) + "\n")
	variable/g $(gv_folder + ":pos_" + ch) = visa#read(hardware_id, "pos? " + ch + "\n")
end

static function get_pos()
	variable/g $(gv_folder + ":pos_a") = visa#read(hardware_id, "pos? a\n")
	variable/g $(gv_folder + ":pos_b") = visa#read(hardware_id, "pos? b\n")
	variable/g $(gv_folder + ":pos_c") = visa#read(hardware_id, "pos? c\n")
end

static function get_velocity()
	variable/g $(gv_folder + ":vel_a") = visa#read(hardware_id, "vel? a\n")
	variable/g $(gv_folder + ":vel_b") = visa#read(hardware_id, "vel? b\n")
	variable/g $(gv_folder + ":vel_c") = visa#read(hardware_id, "vel? c\n")
end

static function get_dco()
	variable/g $(gv_folder + ":dco_a") = visa#read(hardware_id, "dco? a\n")
	variable/g $(gv_folder + ":dco_b") = visa#read(hardware_id, "dco? b\n")
	variable/g $(gv_folder + ":dco_c") = visa#read(hardware_id, "dco? c\n")
end

function set_step(step)
	variable step
	variable/g $(gv_folder + ":step_a") = step
	variable/g $(gv_folder + ":step_b") = step
	variable/g $(gv_folder + ":step_c") = step
end

function set_velocity(v)
	variable v
	visa#cmd(hardware_id, "vco a1\n")
	visa#cmd(hardware_id, "vco b1\n")
	visa#cmd(hardware_id, "vco c1\n")
	visa#cmd(hardware_id, "vel a" + num2str(v) + "\n")
	visa#cmd(hardware_id, "vel b" + num2str(v) + "\n")
	visa#cmd(hardware_id, "vel c" + num2str(v) + "\n")
end

function set_dco(dco)
	variable dco
	visa#cmd(hardware_id, "dco a" + num2str(dco) + "\n")
	visa#cmd(hardware_id, "dco b" + num2str(dco) + "\n")
	visa#cmd(hardware_id, "dco c" + num2str(dco) + "\n")
end

function zero_stage_pos()
	visa#cmd(hardware_id, "mov a0\n")
	visa#cmd(hardware_id, "mov b0\n")
	visa#cmd(hardware_id, "mov c0\n")
end

function stop()
	visa#cmd(hardware_id, "stp a\n")
end

// Panel //