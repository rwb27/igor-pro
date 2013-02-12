#pragma IndependentModule = smu
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "visa_basic" as visa
strconstant hardware_id = "pi_pi733_3cd_stage"
strconstant resourceName = "ASRL2::INSTR"
strconstant gv_folder = "root:global_variables:" + hardware_id

function open()
	variable status
	status = visa#open(hardware_id, resourceName)
	return status
end

function close()
	variable status
	status = visa#close(hardware_id)
	return status
end

function initialise()
end

function start_up()
	visa#cmd(hardware_id, "onl 1")
	sleep/s 0.5
	close_loop()
	sleep/s 0.5
	zero_stage_pos()
end

// set pi stage to 'closed-loop' operation (required for 'move_pi' command to work)
function close_loop()
	visa#cmd(hardware_id, "svo a1")
	visa#cmd(hardware_id, "svo b1")
	visa#cmd(hardware_id, "svo c1")
end

// set pi stage to 'open-loop' operation
// (always run before turning the controller to 'offline mode' and then powering down)
function open_loop()
	visa#cmd(hardware_id, "svo a0")
	visa#cmd(hardware_id, "svo b0")
	visa#cmd(hardware_id, "svo c0")
end

function get_pos()
	variable/g $(gv_folder + ":pos_a") = visa#read(hardware_id, "pos? a")
	variable/g $(gv_folder + ":pos_b") = visa#read(hardware_id, "pos? b")
	variable/g $(gv_folder + ":pos_c") = visa#read(hardware_id, "pos? c")
end

function move(ch, pos)
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
	visa#cmd(hardware_id, "mov " + ch + num2str(pos))
	variable/g $(gv_folder + ":pos_" + ch) = visa#read(hardware_id, "pos? " + ch)
end

function move_rel(ch, rpos)
	string ch
	variable rpos
	visa#cmd(hardware_id, "mvr " + ch + num2str(rpos))
	variable/g $(gv_folder + ":pos_" + ch) = visa#read(hardware_id, "pos? " + ch)
end

function zero_stage_pos()
	visa#cmd(hardware_id, "mov a0")
	visa#cmd(hardware_id, "mov b0")
	visa#cmd(hardware_id, "mov c0")
end

function shutdown()
	zero_stage_pos()
	sleep/s 20.0
	open_loop()
	sleep/s 0.5
	visa#cmd(hardware_id, "onl 0")
end

function stop()
	visa#cmd(hardware_id, "stp a")
end

function set_step_pi(step)
	variable step
	variable/g step_a
	variable/g step_b
	variable/g step_c
end

function set_velocity_pi(v)
	variable v
	string v_s = num2str(v)
	visa#cmd(hardware_id, "vco a1")
	visa#cmd(hardware_id, "vco b1")
	visa#cmd(hardware_id, "vco c1")
	visa#cmd(hardware_id, "vel a" + v_s)
	visa#cmd(hardware_id, "vel b" + v_s)
	visa#cmd(hardware_id, "vel c" + v_s)
end