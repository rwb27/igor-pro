#pragma ModuleName = actuators
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "visa_comms"
static strconstant hardware_id_x = "newport_actuators_x"
static strconstant hardware_id_y = "newport_actuators_y"
static strconstant hardware_id_z = "newport_actuators_z"
static strconstant resourceName_x = "ASRL10"
static strconstant resourceName_y = "ASRL8"
static strconstant resourceName_z = "ASRL9"
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

static function/s gv_path(ch)
	string ch
	if (stringmatch(ch, "x"))
		return gv_folder_x
	elseif (stringmatch(ch, "y"))
		return gv_folder_y
	elseif (stringmatch(ch, "z"))
		return gv_folder_z
	endif
end

static function initialise()
	variable/g $(gv_folder_x + ":pos_x"), $(gv_folder_y + ":pos_y"), $(gv_folder_z + ":pos_z")
	variable/g $(gv_folder_x + ":step_x") = 500.0, $(gv_folder_y + ":step_y") = 500.0, $(gv_folder_z + ":step_z") = 500.0
	motors_on()
	setup("x"); setup("y"); setup("z")
	get_pos("x"); get_pos("y"); get_pos("z")
end

static function setup(ch)
	string ch
	string status
	if (stringmatch(ch, "x"))
		do
			status = ready_status("x")
		while (!stringmatch(status, "32") && !stringmatch(status, "33") && !stringmatch(status, "34") && !stringmatch(status, "35"))
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
	string pos_str
	variable pos
	if (stringmatch(ch, "x"))
		// hlx pos x
		pos_str = visa#read_str(hardware_id_x, actuator_id_x + "tp?\r\n")
		pos = str2num(pos_str[5, (strlen(pos_str) - 1)])
		pos *= 1000
		variable/g $(gv_folder_x + ":pos_x") = pos
	elseif (stringmatch(ch, "y"))
		// nanopz pos y
		pos_str = visa#read_str(hardware_id_y, actuator_id_y + "tp?\r\n")
		pos = str2num(pos_str[5, (strlen(pos_str) - 1)])
		pos /= 100
		variable/g $(gv_folder_y + ":pos_y") = pos
	elseif (stringmatch(ch, "z"))
		// nanopz pos z
		pos_str = visa#read_str(hardware_id_z, actuator_id_z + "tp?\r\n")
		pos = str2num(pos_str[5, (strlen(pos_str) - 1)])
		pos /= 100
		variable/g $(gv_folder_z + ":pos_z") = pos
	endif
	return pos
end
	
static function move(ch, pos)
	string ch
	variable pos
	variable init_pos, new_pos
	string pos_str
	if (stringmatch(ch, "x"))
		//init_pos = get_pos("x")
		pos /= 1000
		visa#cmd(hardware_id_x, actuator_id_x + "pr" + num2str(pos) + "\r\n")
		sleep/s abs(pos)/1000*1000
		new_pos = get_pos("x")
	elseif (stringmatch(ch, "y"))
		//init_pos = get_pos("y")
		pos *= 100
		pos = round(pos)
		sprintf pos_str, "%8d\r", pos
		visa#cmd(hardware_id_y, actuator_id_y + "pr" + pos_str + "\r\n")
		sleep/s abs(pos)/1000/100
		new_pos = get_pos("y")
	elseif (stringmatch(ch, "z"))
		//init_pos = get_pos("z")
		pos *= 100
		pos = round(pos)
		sprintf pos_str, "%8d\r", pos
		visa#cmd(hardware_id_z, actuator_id_z + "pr" + pos_str + "\r\n")
		sleep/s abs(pos)/1000/100
		new_pos = get_pos("z")
	endif
	//print "moved ", (new_pos - init_pos), ", slept ", abs(pos)/1000
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
end

static function motors_off()
	visa#cmd(hardware_id_x, actuator_id_x + "mm0\r\n")
	visa#cmd(hardware_id_y, actuator_id_y + "mf\r\n")
	visa#cmd(hardware_id_z, actuator_id_z + "mf\r\n")
	sleep/s 1
end

static function stop()
	visa#cmd(hardware_id_x, actuator_id_x + "st\r\n")
	visa#cmd(hardware_id_y, actuator_id_y + "st\r\n")
	visa#cmd(hardware_id_z, actuator_id_z + "st\r\n")
end

// Panel Controls

static function startup_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			open_comms()
			motors_on()
			close_comms()
			break
		case -1:
			break
	endswitch
	return 0
end

static function shutdown_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			open_comms()
			motors_off()
			close_comms()
			break
		case -1:
			break
	endswitch
	return 0
end

static function move_up_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			nvar step = $(gv_folder_x + ":step_x")
			open_comms()
			move("x", step)
			close_comms()
			break
		case -1:
			break
	endswitch
	return 0
end

static function move_down_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			nvar step = $(gv_folder_x + ":step_x")
			open_comms()
			move("x", -step)
			close_comms()
			break
		case -1:
			break
	endswitch
	return 0
end

static function move_left_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			nvar step = $(gv_folder_z + ":step_z")
			open_comms()
			move("z", step)
			close_comms()
			break
		case -1:
			break
	endswitch
	return 0
end

static function move_right_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			nvar step = $(gv_folder_z + ":step_z")
			open_comms()
			move("z", -step)
			close_comms()
			break
		case -1:
			break
	endswitch
	return 0
end

static function move_focusdown_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			nvar step = $(gv_folder_y + ":step_y")
			open_comms()
			move("y", step)
			close_comms()
			break
		case -1:
			break
	endswitch
	return 0
end

static function move_focusup_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			nvar step = $(gv_folder_y + ":step_y")
			open_comms()
			move("y", -step)
			close_comms()
			break
		case -1:
			break
	endswitch
	return 0
end

static function update_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			open_comms()
			get_pos("x"); get_pos("y"); get_pos("z")
			close_comms()
			break
		case -1:
			break
	endswitch
	return 0
end

static function init_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			open_comms()
			initialise()
			close_comms()
			break
		case -1:
			break
	endswitch
	return 0
end

// Panel //

static function/c insert_actuators_panel(left, top) : panel
	variable left, top
	
	dfref gv_path_x = $gv_folder_x
	dfref gv_path_y = $gv_folder_y
	dfref gv_path_z = $gv_folder_z
	
	actuators#open_comms()
	actuators#initialise()
	actuators#close_comms()
	
	variable l_size = 340, t_size = 165
	groupbox newport_group, pos={left, top}, size={l_size, t_size}, title="Newport NanoPZ/HLX Actuators"
	groupbox newport_group, labelBack=(56576,56576,56576), fStyle=1
		// buttons
	left = 10; top += 20
	button startup_actuators, pos={left, top}, size={60,20}, proc=actuators#startup_button, title="Startup"
	button startup_actuators, fColor=(32768,65280,0)
	top += 20
	button shutdown_actuators, pos={left, top}, size={60,20}, proc=actuators#shutdown_button, title="Shutdown"
	button shutdown_actuators, fColor=(65280,0,0)
	top += 20
	button actuators_update, pos={left,top}, size={60,20}, proc=actuators#update_button, title="Update"
	top += 20
	button init_actuators, pos={left,top}, size={60,20}, proc=actuators#init_button, title="Initialise"
		// position display
	left += 65; top -= 60
	valdisplay actuator_x, pos={left, top}, size={110,15}, bodyWidth=60, title="height (x)"
	valdisplay actuator_x, limits={0,0,0}, barmisc={0,1000}
	valdisplay actuator_x, value= #"root:global_variables:newport_actuators_x:pos_x"
	top += 20
	valdisplay actuator_y, pos={left, top}, size={110,15}, bodyWidth=60, title="focus (y)"
	valdisplay actuator_y, limits={0,0,0}, barmisc={0,1000}
	valdisplay actuator_y, value= #"root:global_variables:newport_actuators_y:pos_y"
	top += 20
	valdisplay actuator_z, pos={left, top}, size={110,15}, bodyWidth=60, title="lateral (z)"
	valdisplay actuator_z, limits={0,0,0}, barmisc={0,1000}
	valdisplay actuator_z, value= #"root:global_variables:newport_actuators_z:pos_z"
		// step display
	left += 115; top -= 40
	setvariable actuators_step_x, pos={left, top}, size={92,15}, bodyWidth=60, title="ht step"
	setvariable actuators_step_x, value= root:global_variables:newport_actuators_x:step_x
	top += 20
	setvariable actuators_step_y, pos={left, top},size={92,15},bodyWidth=60,title="f step"
	setvariable actuators_step_y, value= root:global_variables:newport_actuators_y:step_y
	top += 20
	setvariable actuators_step_z, pos={left, top},size={92,15},bodyWidth=60,title="lat step"
	setvariable actuators_step_z, value= root:global_variables:newport_actuators_z:step_z
		// movement controls
	left = 190; top += 20
	variable t_spacer = 25, l_spacer = 50, t_spacer2 = t_spacer + 5
	variable up_l = left + l_spacer, up_t = top, in_l = left + 2*l_spacer, in_t = top	// top row
	variable left_l = left, left_t = top + t_spacer2, right_l = left + 2*l_spacer, right_t = top + t_spacer2	// middle row
	variable out_l = left, out_t = top + 2*t_spacer, down_l = left + l_spacer, down_t = top + 2*t_spacer	// bottom row
	button actuators_left, pos={left_l, left_t}, size={50,20}, proc=actuators#move_left_button, title="Left"
	button actuators_focusout, pos={out_l, out_t}, size={50,30}, proc=actuators#move_focusdown_button, title="Focus\rOut"
	button actuators_down, pos={down_l, down_t}, size={50,20}, proc=actuators#move_down_button, title="Down"
	button actuators_up, pos={up_l, up_t}, size={50,20}, proc=actuators#move_up_button, title="Up"
	button actuators_right, pos={right_l, right_t}, size={50,20}, proc=actuators#move_right_button, title="Right"
	button actuators_focusin, pos={in_l, in_t}, size={50,30}, proc=actuators#move_focusup_button, title="Focus\rIn"
	
	return cmplx(l_size, t_size)
end