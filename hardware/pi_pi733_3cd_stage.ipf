#pragma rtGlobals=1		// Use modern global access method.
//
// v3, 03/02/13, AS
//

// required functions

function check_folder_pi(data_folder)
	string data_folder
	if (!datafolderexists(data_folder))
		newdatafolder $data_folder
	endif
end

function open_pi()
	variable session, instr, status
	string error
	string resourceName = "ASRL2::INSTR"
	string data_folder = "root:global_variables"
	check_folder_pi(data_folder)
	data_folder += ":pi_pi733_3cd_stage"
	check_folder_pi(data_folder)
	status = viOpenDefaultRM(session)
	if (status < 0)																//Error handling
		viStatusDesc(instr, status, error)
  		print error
  		abort "no comms1"
	endif
	status = viOpen(session, resourceName, 0, 0, instr)
	if (status < 0)																//Error handling
		viStatusDesc(instr, status, error)
  		print error
  		abort "no comms2"
	endif
	status = viClear(session)
	variable/g $(data_folder + ":instr") = instr
	variable/g $(data_folder + ":session") = session
	return status
end

function close_pi()
	nvar session = root:global_variables:pi_pi733_3cd_stage:session
	variable status = viClose(session)
	status = viClear(session)
	return status
end

function cmd_pi(cmd)
	string cmd
	nvar instr = root:global_variables:pi_pi733_3cd_stage:instr
	VISAwrite instr, cmd
	variable status
	string error
	if (status < 0)
		viStatusDesc(instr, status, error)
  		print error
  		abort "no comms3"
	endif
end

function read_pi(cmd)
	string cmd
	variable value
	nvar instr = root:global_variables:pi_pi733_3cd_stage:instr
	VISAwrite instr, cmd
	VISAread instr, value
	return value
end

function/s read_str_pi(cmd)
	string cmd
	string message
	nvar instr = root:global_variables:pi_pi733_3cd_stage:instr
	VISAwrite instr, cmd
	VISAread/t="\n" instr, message
	return message
end

// setup functions

function start_up_pi()
	cmd_pi("onl 1")
	sleep/s 0.5
	close_loop_pi()
	sleep/s 0.5
	zero_stage_pos_pi()
end

// set pi stage to 'closed-loop' operation (required for 'move_pi' command to work)
function close_loop_pi()
	cmd_pi("svo a1")
	cmd_pi("svo b1")
	cmd_pi("svo c1")
end

// set pi stage to 'open-loop' operation
// (always run before turning the controller to 'offline mode' and then powering down)
function open_loop_pi()
	cmd_pi("svo a0")
	cmd_pi("svo b0")
	cmd_pi("svo c0")
end

function get_pos_pi()
	string param_dir = "root:global_variables:pi_pi733_3cd_stage"
	check_folder_pi(param_dir)
	variable/g $(param_dir + ":pos_a") = read_pi("pos? a")
	variable/g $(param_dir + ":pos_b") = read_pi("pos? b")
	variable/g $(param_dir + ":pos_c") = read_pi("pos? c")
end

// movement functions

function move_pi(ch, pos)
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
	cmd_pi("mov " + ch + num2str(pos))
	variable/g $("pos_" + ch) = read_pi("pos? " + ch)
end

function move_rel_pi(ch, rpos)
	string ch
	variable rpos
	cmd_pi("mvr " + ch + num2str(rpos))
end

function zero_stage_pos_pi()
	cmd_pi("mov a0")
	cmd_pi("mov b0")
	cmd_pi("mov c0")
end

function shutdown_pi()
	zero_stage_pos_pi()
	sleep/s 20.0
	open_loop_pi()
	sleep/s 0.5
	cmd_pi("onl 0")
end

function stop_pi()
	cmd_pi("stp a")
end

// set functions

function set_step_pi(step)
	variable step
	variable/g step_a
	variable/g step_b
	variable/g step_c
end

function set_velocity_pi(v)
	variable v
	string v_s = num2str(v)
	cmd_pi("vco a1")
	cmd_pi("vco b1")
	cmd_pi("vco c1")
	cmd_pi("vel a" + v_s)
	cmd_pi("vel b" + v_s)
	cmd_pi("vel c" + v_s)
end