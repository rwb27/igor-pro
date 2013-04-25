#pragma ModuleName = pi_stage
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "visa_comms"
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
	set_dco(1)
	get_dco()
end

static function/s gv_path()
	return gv_folder
end

static function startup()
	visa#cmd(hardware_id, "onl 1\n")
	sleep/s 0.5
	close_loop()
	sleep/s 0.5
	zero_stage_pos()
	get_pos()
	get_velocity()
end

static function shutdown()
	zero_stage_pos()
	sleep/s 20.0
	open_loop()
	sleep/s 0.5
	visa#cmd(hardware_id, "onl 0\n")
end

// set pi stage to 'closed-loop' operation (required for 'move_pi' command to work)
static function close_loop()
	visa#cmd(hardware_id, "svo a1\n")
	visa#cmd(hardware_id, "svo b1\n")
	visa#cmd(hardware_id, "svo c1\n")
end

// set pi stage to 'open-loop' operation
// (always run before turning the controller to 'offline mode' and then powering down)
static function open_loop()
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
	nvar/sdfr=$gv_folder vel = $("vel_" + ch), pos0 = $("pos_" + ch)
	visa#cmd(hardware_id, "mov " + ch + num2str(pos) + "\n")
	variable translation_time = abs((pos - pos0) / vel)
	variable delay = 0.25 + translation_time							// add 0.25 to translation time
	sleep/s delay
	variable/g $(gv_folder + ":pos_" + ch) = visa#read(hardware_id, "pos? " + ch + "\n")
end

static function move_rel(ch, rpos)
	string ch
	variable rpos
	visa#cmd(hardware_id, "mvr " + ch + num2str(rpos) + "\n")
	nvar/sdfr=$gv_folder pos = $("pos_" + ch), vel = $("vel_" + ch)
	sleep/s 0.25 + abs(rpos / vel)
	pos = visa#read(hardware_id, "pos? " + ch + "\n")
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

static function set_step(step)
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

static function set_dco_a(dco)
	variable dco
	visa#cmd(hardware_id, "dco a" + num2str(dco) + "\n")
	variable/g $(gv_folder + ":dco_a") = visa#read(hardware_id, "dco? a\n")
end

static function set_dco_b(dco)
	variable dco
	visa#cmd(hardware_id, "dco b" + num2str(dco) + "\n")
	variable/g $(gv_folder + ":dco_b") = visa#read(hardware_id, "dco? b\n")
end

static function set_dco_c(dco)
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

static function zero_stage_pos()
	visa#cmd(hardware_id, "mov a0\n")
	visa#cmd(hardware_id, "mov b0\n")
	visa#cmd(hardware_id, "mov c0\n")
end

static function stop()
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

static function set_position_a_panel(sva) : setvariablecontrol
	struct wmsetvariableaction &sva
	switch( sva.eventcode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
			open_comms()
			move("A", dval)
			close_comms()
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

static function set_position_b_panel(sva) : setvariablecontrol
	struct wmsetvariableaction &sva
	switch( sva.eventcode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
			open_comms()
			move("B", dval)
			close_comms()
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

static function set_position_c_panel(sva) : setvariablecontrol
	struct wmsetvariableaction &sva
	switch( sva.eventcode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
			open_comms()
			move("C", dval)
			close_comms()
			break
		case -1: // control being killed
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

static function set_dco_a_panel(sva) : setvariablecontrol
	struct wmsetvariableaction &sva

	switch( sva.eventcode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
			open_comms()
			set_dco_a(dval)
			close_comms()
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

static function set_dco_b_panel(sva) : setvariablecontrol
	struct wmsetvariableaction &sva

	switch( sva.eventcode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
			open_comms()
			set_dco_b(dval)
			close_comms()
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

static function set_dco_c_panel(sva) : setvariablecontrol
	struct wmsetvariableaction &sva

	switch( sva.eventcode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
			open_comms()
			set_dco_c(dval)
			close_comms()
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

// Panel //

function starting_pos()
	pi_stage#open_comms()
	pi_stage#move("a", 50)
	pi_stage#move("b", 50)
	pi_stage#move("c", 5)
	pi_stage#close_comms()
end

function starting_pos_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			starting_pos()
			break
		case -1:
			break
	endswitch
	return 0
end

static function/c insert_pi_stage_panel(left, top) : panel
	variable left, top
	
	dfref gv_path = $gv_folder
	
	pi_stage#open_comms()
	pi_stage#initialise()
	pi_stage#close_comms()
	
	variable l_size = 340, t_size = 205
	groupbox pi_group,pos={left, top},size={l_size, t_size},title="PI PI733.3CD Stage"
	groupbox pi_group, labelBack=(56576,56576,56576), fStyle=1
		// main buttons
	left += 5; top += 20
	button startup_stage ,pos={left, top}, size={60,20}, proc=pi_stage#startup_button, title="Startup"
	button startup_stage, fColor=(32768,65280,0)
	top += 20
	button shutdown_stage, pos={left, top}, size={60,20}, proc=pi_stage#shutdown_button, title="Shutdown"
	button shutdown_stage, fColor=(65280,0,0)
	top += 20
	button stage_update, pos={left, top}, size={60,20}, proc=pi_stage#update_button, title="Update"
	top += 20
	button stage_starting_pos, pos={left, top}, size={60,30}, proc=starting_pos_button, title="Starting\rPositions"
	
		// position display
	top += 40
	setvariable stage_pos_a, pos={left, top}, size={70,15}, bodyWidth=55, proc=pi_stage#set_position_a_panel, title="A"
	setvariable stage_pos_a, value= _NUM:20//root:global_variables:pi_pi733_3cd_stage:pos_a
	top += 20
	setvariable stage_pos_b, pos={left, top}, size={70,15}, bodyWidth=55, proc=pi_stage#set_position_b_panel, title="B"
	setvariable stage_pos_b, value= _NUM:20//root:global_variables:pi_pi733_3cd_stage:pos_b
	top += 20
	setvariable stage_pos_c, pos={left, top}, size={70,15}, bodyWidth=55, proc=pi_stage#set_position_c_panel, title="C"
	setvariable stage_pos_c, value= _NUM:5//root:global_variables:pi_pi733_3cd_stage:pos_c
	
		// position display
	left += 65; top -= 60 + 80
	valdisplay stage_a, pos={left, top}, size={110,15}, bodyWidth=60, title="lateral (a)"
	valdisplay stage_a, limits={0,0,0}, barmisc={0,1000}
	valdisplay stage_a, value= #"root:global_variables:pi_pi733_3cd_stage:pos_a"
	top += 20
	valdisplay stage_b, pos={left, top}, size={110,15}, bodyWidth=60, title="height (b)"
	valdisplay stage_b, limits={0,0,0}, barmisc={0,1000}
	valdisplay stage_b, value= #"root:global_variables:pi_pi733_3cd_stage:pos_b"
	top += 20
	valdisplay stage_c,pos={left, top},size={110,15},bodyWidth=60,title="focus (c)"
	valdisplay stage_c,limits={0,0,0},barmisc={0,1000}
	valdisplay stage_c,value= #"root:global_variables:pi_pi733_3cd_stage:pos_c"
		// velocity display
	top += 20
	setvariable stage_vel_a, pos={left, top}, size={109,16}, bodyWidth=60, proc=pi_stage#set_velocity_a_panel,title="a-velocity"
	setvariable stage_vel_a, value= root:global_variables:pi_pi733_3cd_stage:vel_a
	top += 20
	setvariable stage_vel_b, pos={left, top}, size={109,16}, bodyWidth=60, proc=pi_stage#set_velocity_b_panel,title="b-velocity"
	setvariable stage_vel_b, value= root:global_variables:pi_pi733_3cd_stage:vel_b
	top += 20
	setvariable stage_vel_c, pos={left, top}, size={109,16}, bodyWidth=60, proc=pi_stage#set_velocity_c_panel,title="c-velocity"
	setvariable stage_vel_c, value= root:global_variables:pi_pi733_3cd_stage:vel_c
		// dco display
	top += 20
	setvariable stage_dco_a, pos={left, top}, size={109,16}, bodyWidth=60, proc=pi_stage#set_dco_a_panel, title="a-dco"
	setvariable stage_dco_a, value= root:global_variables:pi_pi733_3cd_stage:dco_a
	top += 20
	setvariable stage_dco_b, pos={left, top}, size={109,16}, bodyWidth=60, proc=pi_stage#set_dco_b_panel, title="b-dco"
	setvariable stage_dco_b, value= root:global_variables:pi_pi733_3cd_stage:dco_b
	top += 20
	setvariable stage_dco_c, pos={left, top}, size={109,16}, bodyWidth=60, proc=pi_stage#set_dco_c_panel, title="c-dco"
	setvariable stage_dco_c, value= root:global_variables:pi_pi733_3cd_stage:dco_c
		// step display
	left += 115; top -= 160
	setvariable stage_step_a, pos={left, top}, size={93,16}, bodyWidth=60, title="a-step"
	setvariable stage_step_a, value= root:global_variables:pi_pi733_3cd_stage:step_a
	top += 20
	setvariable stage_step_b, pos={left, top}, size={93,16}, bodyWidth=60, title="b-step"
	setvariable stage_step_b, value= root:global_variables:pi_pi733_3cd_stage:step_b
	top += 20
	setvariable stage_step_c, pos={left, top}, size={93,16}, bodyWidth=60, title="c-step"
	setvariable stage_step_c, value= root:global_variables:pi_pi733_3cd_stage:step_c
		// movement control
	left = 190; top += 20
	variable t_spacer = 25, l_spacer = 50, t_spacer2 = t_spacer + 5
	variable up_l = left + l_spacer, up_t = top, in_l = left + 2*l_spacer, in_t = top	// top row
	variable left_l = left, left_t = top + t_spacer2, right_l = left + 2*l_spacer, right_t = top + t_spacer2	// middle row
	variable out_l = left, out_t = top + 2*t_spacer, down_l = left + l_spacer, down_t = top + 2*t_spacer	// bottom row
	button stage_left, pos={left_l, left_t}, size={50,20}, proc=pi_stage#move_left_button, title="Left"
	button stage_down, pos={down_l, down_t}, size={50,20}, proc=pi_stage#move_down_button, title="Down"
	button stage_up, pos={up_l, up_t}, size={50,20}, proc=pi_stage#move_up_button, title="Up"
	button stage_right, pos={right_l, right_t}, size={50,20}, proc=pi_stage#move_right_button, title="Right"
	button stage_focusin, pos={in_l, in_t}, size={50,30}, proc=pi_stage#move_focusup_button, title="Focus\rIn"
	button stage_focusout, pos={out_l, out_t}, size={50,30}, proc=pi_stage#move_focusdown_button, title="Focus\rOut"

	return cmplx(l_size, t_size)
end