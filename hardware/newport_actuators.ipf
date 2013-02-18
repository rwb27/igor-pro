#pragma ModuleName = actuators
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "visa"
static strconstant hardware_id_x = "newport_actuators_x"
static strconstant hardware_id_y = "newport_actuators_y"
static strconstant hardware_id_z = "newport_actuators_z"
static strconstant resourceName_x = "ASRL9"
static strconstant resourceName_y = "ASRL8"
static strconstant resourceName_z = "ASRL10"
static strconstant gv_folder_x = "root:global_variables:newport_actuators_x"
static strconstant gv_folder_y = "root:global_variables:newport_actuators_y"
static strconstant gv_folder_z = "root:global_variables:newport_actuators_z"
static strconstant actuator_id_x = "1"
static strconstant actuator_id_y = "1"
static strconstant actuator_id_z = "1"

static function open_comms()
	variable status
	status = visa#open_comms(hardware_id_x, resourceName_x)
	status = visa#open_comms(hardware_id_y, resourceName_y)
	status = visa#open_comms(hardware_id_z, resourceName_z)
	return status
end

static function close_comms()
	variable status
	status = visa#close_comms(hardware_id_x)
	status = visa#close_comms(hardware_id_y)
	status = visa#close_comms(hardware_id_z)
	return status
end

static function initialise()
	variable/g $(gv_folder_x + ":pos_x"), $(gv_folder_y + ":pos_y"), $(gv_folder_z + ":pos_z")
	get_pos("x"); get_pos("y"); get_pos("z")
	variable/g $(gv_folder_x + ":step_x") = 500.0, $(gv_folder_y + ":step_y") = 500.0, $(gv_folder_z + ":step_z") = 500.0
end

static function setup(ch)
	string ch
	string status
	if (stringmatch(ch, "x"))
		do
			status = ready_status("x")
		while (!stringmatch(status, "33"))
		get_pos("x")
	elseif (stringmatch(ch, "y"))
		do
			status = ready_status("y")
		while (!stringmatch(status, "q"))
		get_pos("y")
	elseif (stringmatch(ch, "z"))
		do
			status = ready_status("z")
		while (!stringmatch(status, "q"))
		get_pos("z")
	endif
end

static function get_pos(ch)
	string ch
	if (stringmatch(ch, "x"))
		// hlx pos x
		string pos_x_str = visa#read_str(hardware_id_x, actuator_id_x + "tp?\r\n")
		variable pos_x = str2num(pos_x_str[3, (strlen(pos_x_str) - 1)])
		variable/g $(gv_folder_x + ":pos_x") = 1000 * pos_x
	elseif (stringmatch(ch, "x"))
		// nanopz pos y
		string pos_y_str = visa#read_str(hardware_id_y, actuator_id_y + "tp?\r\n")
		variable pos_y = str2num(pos_y_str[5, (strlen(pos_y_str) - 1)])
		variable/g $(gv_folder_y + ":pos_y") = pos_y / 80
	elseif (stringmatch(ch, "x"))
		// nanopz pos z
		string pos_z_str = visa#read_str(hardware_id_z, actuator_id_z + "tp?\r\n")
		variable pos_z = str2num(pos_z_str[5, (strlen(pos_z_str) - 1)])
		variable/g $(gv_folder_z + ":pos_z") = pos_z / 60
	endif
end
	
static function move(ch, pos)
	string ch
	variable pos
	string pos_str
	if (stringmatch(ch, "x"))
		pos /= 1000
		visa#cmd(hardware_id_x, actuator_id_x + "pr" + num2str(pos) + "\r\n")
		variable/g $(gv_folder_x + ":pos_x") = get_pos("x")
	elseif (stringmatch(ch, "y"))
		pos *= 80
		pos = round(pos)
		sprintf pos_str, "%8d\r", pos
		visa#cmd(hardware_id_y, actuator_id_y + "pr" + pos_str + "\r\n")
		variable/g $(gv_folder_y + ":pos_y") = get_pos("y")
	elseif (stringmatch(ch, "z"))
		pos *= 60
		pos = round(pos)
		sprintf pos_str, "%8d\r", pos
		visa#cmd(hardware_id_z, actuator_id_z + "pr" + pos_str + "\r\n")
		variable/g $(gv_folder_z + ":pos_z") = get_pos("z")
	endif
end

function/s ready_status(ch)
	string ch
	string ready_info, ready_state
	if (stringmatch(ch, "x"))
		ready_info = visa#read_str(hardware_id_x, actuator_id_x + "ts?\r\n")
		ready_state = ready_info[7,8]
	elseif (stringmatch(ch, "y"))
		ready_info = visa#read_str(hardware_id_y, actuator_id_y + "ts?\r\n")
		ready_state = ready_info[5]
	elseif (stringmatch(ch, "z"))
		ready_info = visa#read_str(hardware_id_z, actuator_id_z + "ts?\r\n")
		ready_state = ready_info[5]
	endif
	return ready_state
end

function home_search(ch)
	string ch
	if (stringmatch(ch, "x"))
		visa#cmd(hardware_id_x, actuator_id_x + "or\r\n")
	endif
end

static function set_velocity(ch)
	string ch
	variable velocity
	if (stringmatch(ch, "x"))
		velocity = 0.1
		visa#cmd(hardware_id_x, actuator_id_x + "va" + num2str(velocity) + "\r\n")
	endif
end

static function motors_on()
	visa#cmd(hardware_id_x, actuator_id_x + "mm1\r\n")
	visa#cmd(hardware_id_y, actuator_id_y + "mo\r\n")
	visa#cmd(hardware_id_z, actuator_id_z + "mo\r\n")
	sleep/s 1
	initialise()
end

static function motors_off()
	visa#cmd(hardware_id_x, actuator_id_x + "mm0\r\n")
	visa#cmd(hardware_id_y, actuator_id_y + "mf\r\n")
	visa#cmd(hardware_id_z, actuator_id_z + "mf\r\n")
	sleep/s 1
	initialise()
end

static function stop()
	visa#cmd(hardware_id_x, actuator_id_x + "st\r\n")
	visa#cmd(hardware_id_y, actuator_id_y + "st\r\n")
	visa#cmd(hardware_id_z, actuator_id_z + "st\r\n")
end

// Panel //