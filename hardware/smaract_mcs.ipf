#pragma moduleName = mcs
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// notes regarding channels
// ch0, x (bottom), +ive right
// ch1, z (middle), +ive forward
// ch2, y (top), +ive down	-	focus, down is towards objective
// ch3, x (bottom), +ive right
// ch4, z (middle), +ive forward
// ch5, y (top), +ive down	-	focus, down is towards objective

static strconstant gv_folder = "root:global_variables:smaract_mcs"

// functions

static function initialise()
	newdatafolder/o root:global_variables
	newdatafolder/o $gv_folder
	get_positions()
	get_speeds()
	get_accelerations()
end

static function get_positions()
	variable mcsHandle = openMCS()
	variable num_ch = getNumChannelsMCS(mcsHandle)
	variable i
	for(i=0;i<num_ch;i+=1)
		variable/g $(gv_folder+":pos_"+num2str(i)) = getPositionMCS(mcsHandle, i)
	endfor
 	closeMCS(mcsHandle)
end

static function get_speeds()
	variable mcsHandle = openMCS()
	variable num_ch = getNumChannelsMCS(mcsHandle)
	variable i
	for(i=0;i<num_ch;i+=1)
		variable/g $(gv_folder+":speed_"+num2str(i)) = getSpeedMCS(mcsHandle, i)
	endfor
 	closeMCS(mcsHandle)
end

static function get_accelerations()
	variable mcsHandle = openMCS()
	variable num_ch = getNumChannelsMCS(mcsHandle)
	variable i
	for(i=0;i<num_ch;i+=1)
		variable/g $(gv_folder+":acc_"+num2str(i)) = getAccelerationMCS(mcsHandle, i)
	endfor
 	closeMCS(mcsHandle)
end

static function set_pos(ch, pos)
	variable ch, pos
	variable/g $(gv_folder+":set_pos_"+num2str(ch)) = pos
end

// grid scanning functions

function default_func(i,j)
	variable i,j
	print "valid function not given"
	return -1
end

function test_func(i,j)
	variable i, j
	nvar/sdfr=$gv_folder pos_0, pos_1, pos_2, pos_3, pos_4, pos_5
	print i, j, pos_0, pos_1, pos_2, pos_3, pos_4, pos_5
end

static function scan_grid(axis1, axis2, scan_size, scan_step, scan_function)
	variable axis1, axis2, scan_size, scan_step
	funcref default_func scan_function
	
	mcs#initialise()
	variable mcsHandle = openMCS()
	
	// initialise piezo positions
	//nvar/sdfr=$pi_path pos_a0 = pos_a, pos_b0 = pos_b, pos_c0 = pos_c // load read piezo positions
	nvar/sdfr=$gv_folder set_point_i = $("set_pos_"+num2str(axis1)), set_point_j = $("set_pos_"+num2str(axis2))
	variable init_i = set_point_i, init_j = set_point_j
	variable pos_i = init_i, pos_j = init_j
	
	// get starting positions
	pos_i = init_i - scan_size/2
	pos_j = init_j - scan_size/2
	//grid scan
	moveMCS(mcsHandle, axis1, pos_i); moveMCS(mcsHandle, axis2, pos_j)
	
	variable nmax = scan_size/scan_step, i = 0, j = 0
	do
		moveMCS(mcsHandle, axis2, pos_j)
		do
			moveMCS(mcsHandle, axis1, pos_i)
			scan_function(i,j)
			doupdate
			// increment B position //
			pos_i += scan_step
			i += 1
		while (i < nmax)
		// move back to initial B position //
		pos_i = init_i - scan_size/2
		i = 0
		// increment C position //
		pos_j += scan_step
		j += 1
	while (j < nmax)

	moveMCS(mcsHandle, axis1, init_i); moveMCS(mcsHandle, axis2, init_j)
	closeMCS(mcsHandle)
end

// panel controls

static function moveTo_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:			
			string ch = getUserData("", ba.ctrlName, "ch")
			nvar pos = $(gv_folder + ":moveTo_"+ch)
			variable mcsHandle = openMCS()
			moveMCS(mcsHandle, str2num(ch), pos)
			closeMCS(mcsHandle)
			break
		case -1:
			break
	endswitch
	return 0
end

static function moveRel_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:			
			string direction = getUserData("", ba.ctrlName, "direction")
			string ch = getUserData("", ba.ctrlName, "ch")
			nvar step = $(gv_folder + ":step_"+ch)
			variable rel_pos = str2num(direction)*step
			variable mcsHandle = openMCS()
			moveRelMCS(mcsHandle, str2num(ch), rel_pos)
			closeMCS(mcsHandle)
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
			mcs#get_positions()
			mcs#get_speeds()
			mcs#get_accelerations()
			break
		case -1:
			break
	endswitch
	return 0
end

static function set_position_panel(sva) : setvariablecontrol
	struct wmsetvariableaction &sva
	switch( sva.eventcode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
			
			variable ch
			strswitch (sva.ctrlName)
				case "stage1_x":
					ch=0
				case "stage1_y":
					ch=0
				case "stage1_z":
					ch=0
				case "stage2_x":
					ch=0
				case "stage2_y":
					ch=0
				case "stage2_z":
					ch=0
			endswitch
			
			variable mcsHandle = openMCS()
			moveMCS(mcsHandle, ch, dval)
			closeMCS(mcsHandle)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

static function set_speed_panel(sva) : setvariablecontrol
	struct wmsetvariableaction &sva

	switch( sva.eventcode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
			
			variable ch
			strswitch (sva.ctrlName)
				case "stage1_x":
					ch=0
				case "stage1_y":
					ch=0
				case "stage1_z":
					ch=0
				case "stage2_x":
					ch=0
				case "stage2_y":
					ch=0
				case "stage2_z":
					ch=0
			endswitch
			
			variable mcsHandle = openMCS()
			setSpeedMCS(mcsHandle, ch, dval)
			closeMCS(mcsHandle)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

static function set_acceleration_panel(sva) : setvariablecontrol
	struct wmsetvariableaction &sva

	switch( sva.eventcode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			variable dval = sva.dval
			string sval = sva.sval
			
			variable ch
			strswitch (sva.ctrlName)
				case "stage1_x":
					ch=0
				case "stage1_y":
					ch=0
				case "stage1_z":
					ch=0
				case "stage2_x":
					ch=0
				case "stage2_y":
					ch=0
				case "stage2_z":
					ch=0
			endswitch
			
			variable mcsHandle = openMCS()
			setAccelerationMCS(mcsHandle, ch, dval)
			closeMCS(mcsHandle)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

// Panel //

static function starting_pos()
	variable mcsHandle = openMCS()
	moveMCS(mcsHandle, 0, 0)
	moveMCS(mcsHandle, 1, 0)
	moveMCS(mcsHandle, 2, 0)
	moveMCS(mcsHandle, 3, 0)
	moveMCS(mcsHandle, 4, 0)
	moveMCS(mcsHandle, 5, 0)
	closeMCS(mcsHandle)
end

function starting_pos_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			mcs#starting_pos()
			break
		case -1:
			break
	endswitch
	return 0
end

static function/c insert_mcs_panel(left, top) : panel
	variable left, top
	
	dfref gv_path = $gv_folder
	
	mcs#initialise()
	
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