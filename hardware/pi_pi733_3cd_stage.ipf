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
	get_dco()
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
	get_pos()
	get_velocity()
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
	variable pos0 = visa#read(hardware_id, "pos? " + ch + "\n")
	visa#cmd(hardware_id, "mov " + ch + num2str(pos) + "\n")
	nvar vel = $(gv_folder + ":vel_" + ch)
	sleep/s 0.1 + abs((pos - pos0) / vel)
	variable/g $(gv_folder + ":pos_" + ch) = visa#read(hardware_id, "pos? " + ch + "\n")
end

function move_rel(ch, rpos)
	string ch
	variable rpos
	visa#cmd(hardware_id, "mvr " + ch + num2str(rpos) + "\n")
	nvar vel = $(gv_folder + ":vel_" + ch)
	sleep/s 0.1 + abs(rpos / vel)
	variable/g $(gv_folder + ":pos_" + ch) = visa#read(hardware_id, "pos? " + ch + "\n")
end

static function get_pos_ch(ch)
	string ch
	variable pos
	if (stringmatch(ch, "a") || stringmatch(ch, "b") || stringmatch(ch, "c"))
		pos =  visa#read(hardware_id, "pos? " + ch + "\n")
		variable/g $(gv_folder + ":pos_" + ch) = pos
	else
		print "error: '", ch, "' not a valid channel."
		pos = -1
	endif
	return pos
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

static function set_velocity_a(v)
	variable v
	visa#cmd(hardware_id, "vco a1\n")
	visa#cmd(hardware_id, "vel a" + num2str(v) + "\n")
	variable/g $(gv_folder + ":vel_a") = visa#read(hardware_id, "vel? a\n")
end

static function set_velocity_b(v)
	variable v
	visa#cmd(hardware_id, "vco b1\n")
	visa#cmd(hardware_id, "vel b" + num2str(v) + "\n")
	variable/g $(gv_folder + ":vel_b") = visa#read(hardware_id, "vel? b\n")
end

static function set_velocity_c(v)
	variable v
	visa#cmd(hardware_id, "vco c1\n")
	visa#cmd(hardware_id, "vel c" + num2str(v) + "\n")
	variable/g $(gv_folder + ":vel_c") = visa#read(hardware_id, "vel? c\n")
end

static function set_velocity(v)
	variable v
	set_velocity_a(v)
	set_velocity_b(v)
	set_velocity_c(v)
	get_velocity()
end

function set_dco_a(dco)
	variable dco
	visa#cmd(hardware_id, "dco a" + num2str(dco) + "\n")
	variable/g $(gv_folder + ":dco_a") = visa#read(hardware_id, "dco? a\n")
end

function set_dco_b(dco)
	variable dco
	visa#cmd(hardware_id, "dco b" + num2str(dco) + "\n")
	variable/g $(gv_folder + ":dco_b") = visa#read(hardware_id, "dco? b\n")
end

function set_dco_c(dco)
	variable dco
	visa#cmd(hardware_id, "dco c" + num2str(dco) + "\n")
	variable/g $(gv_folder + ":dco_c") = visa#read(hardware_id, "dco? c\n")
end

static function set_dco(dco)
	variable dco
	set_dco_a(dco)
	set_dco_b(dco)
	set_dco_c(dco)
	get_dco()
end

function zero_stage_pos()
	visa#cmd(hardware_id, "mov a0\n")
	visa#cmd(hardware_id, "mov b0\n")
	visa#cmd(hardware_id, "mov c0\n")
end

function stop()
	visa#cmd(hardware_id, "stp a\n")
end

// Panel Controls

static function startup_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			open_comms()
			startup()
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
			shutdown()
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
			nvar rpos = $(gv_folder + ":step_a")
			open_comms()
			move_rel("A", rpos)
			//get_pos()
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
			nvar rpos = $(gv_folder + ":step_a")
			open_comms()
			move_rel("A", -rpos)
			//get_pos()
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
			nvar rpos = $(gv_folder + ":step_b")
			open_comms()
			move_rel("B", -rpos)
			//get_pos()
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
			nvar rpos = $(gv_folder + ":step_b")
			open_comms()
			move_rel("B", rpos)
			//get_pos
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
			nvar rpos = $(gv_folder + ":step_c")
			open_comms()
			move_rel("C", rpos)
			//get_pos()
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
			nvar rpos = $(gv_folder + ":step_c")
			open_comms()
			move_rel("C", -rpos)
			//get_pos()
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
			get_pos()
			get_velocity()
			get_dco()
			close_comms()
			break
		case -1:
			break
	endswitch
	return 0
end

static function get_pos_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			open_comms()
			get_pos()
			close_comms()
			break
		case -1:
			break
	endswitch
	return 0
end

static function get_velocity_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			open_comms()
			get_velocity()
			close_comms()
			break
		case -1:
			break
	endswitch
	return 0
end


static function set_velocity_a_panel(sva) : setvariablecontrol
	struct wmsetvariableaction &sva

	switch( sva.eventcode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
			open_comms()
			set_velocity_a(dval)
			close_comms()
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

static function set_velocity_b_panel(sva) : setvariablecontrol
	struct wmsetvariableaction &sva

	switch( sva.eventcode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
			open_comms()
			set_velocity_b(dval)
			close_comms()
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

static function set_velocity_c_panel(sva) : setvariablecontrol
	struct wmsetvariableaction &sva

	switch( sva.eventcode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
			open_comms()
			set_velocity_c(dval)
			close_comms()
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

static function set_dco_panel(sva) : setvariablecontrol
	struct wmsetvariableaction &sva

	switch( sva.eventcode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
			open_comms()
			set_dco(dval)
			close_comms()
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end