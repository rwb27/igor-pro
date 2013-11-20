#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "arrowPictures"

function tip_control_and_alignment() : panel
	variable left, right, top, bottom
	dowindow/k tip_control
	
	// MAIN PANEL //
	// panel layout
	newpanel/w=(50,20,450,600)/n=tip_control as "Tip Control and Alignment"
	modifypanel cbRGB=(60928,60928,60928), framestyle=1
	setdrawlayer UserBack
	showtools/a
	
	// title
	left = 5; top = 5
	titlebox title, pos={left,top}, size={130,25}, title="Tip Control and Alignment"
	top += 25
	variable/c size
	
	// newport actuators
	size = insert_mcs_panel(left, top)
	top += imag(size) + 5
	
	//movewindow/w=tip_control 50, 20, left-30, top-130
end

Function updateStageStep(action) : PopupMenuControl //change the distance moved by the relative move controls
	Struct wmPopupAction &action
	String ctrlName = action.ctrlName
	String windowName = action.win
	String valueStr = action.popStr
	
	//if we select "other", show the setVariable control directly.  Otherwise, update the hidden control
	variable distance
	strswitch (ctrlName)
		case "stageStep0Popup":
		if (stringmatch(valueStr, "*other*"))
			setVariable stageStep0, disable=0
		else
			distance = str2num(valueStr)
			variable/g root:global_variables:smaract_mcs:step_0 = distance
			setVariable stageStep0, disable=1, value=root:global_variables:smaract_mcs:step_0
		endif
		break
		
		case "stageStep1Popup":
		if (stringmatch(valueStr, "*other*"))
			setVariable stageStep1, disable=0
		else
			distance = str2num(valueStr)
			variable/g root:global_variables:smaract_mcs:step_1 = distance
			setVariable stageStep1, disable=1, value=root:global_variables:smaract_mcs:step_1
		endif
		break
		
		case "stageStep2Popup":
		if (stringmatch(valueStr, "*other*"))
			setVariable stageStep2, disable=0
		else
			distance = str2num(valueStr)
			variable/g root:global_variables:smaract_mcs:step_2 = distance
			setVariable stageStep2, disable=1, value=root:global_variables:smaract_mcs:step_2
		endif
		break
		
	endswitch
End

function/c insert_mcs_panel(left, top) : panel
	variable left, top
	
	//dfref gv_path = $gv_folder
	
	//mcs#initialise()
	
	// title
	variable l_size = 5+170+5+170+5
	variable t_size = 450
	groupbox mcs_group,pos={left, top},size={l_size, t_size},title="SmarAct MCS Controller"
	groupbox mcs_group, labelBack=(60928,60928,60928), fStyle=1
	
	button stage_update, pos={left+290, top+15}, size={60,20}, proc=update_button, title="Update"
	
	variable groupBoxWidth = 170, groupBoxHeight = 400
	
	// stage 1 - groupbox containing each stage movements
	left += 5; top += 25
	groupbox stage1_group,pos={left, top},size={groupBoxWidth, groupBoxHeight},title="Stage 1"
	groupbox stage1_group, labelBack=(60928,60928,60928), fStyle=1
	
	// stage 1, row 1 - movement controls
	top += 20
	Button stage1MoveLeft, picture=arrowPics#leftArrow, pos={left+5,top+45}, title="", help={"Click this button to move one step"}, proc=moveRel_button, userData(direction)="1", userData(ch)="0"
	Button stage1MoveRight, picture=arrowPics#rightArrow, pos={left+80,top+45}, title="", help={"Click this button to move one step"}, proc=moveRel_button, userData(direction)="1", userData(ch)="0"
	Button stage1MoveDown, picture=arrowPics#downArrow, pos={left+50,top+80}, title="", help={"Click this button to move one step"}, proc=moveRel_button, userData(direction)="1", userData(ch)="0"
	Button stage1MoveUp, picture=arrowPics#upArrow, pos={left+50,top}, title="", help={"Click this button to move one step"}, proc=moveRel_button, userData(direction)="1", userData(ch)="0"
	Button stage1MoveOut, picture=arrowPics#upArrow, pos={left+130,top}, title="", help={"Click this button to move one step"}, proc=moveRel_button, userData(direction)="1", userData(ch)="0"
	Button stage1MoveIn, picture=arrowPics#downArrow, pos={left+130, top+80}, title="", help={"Click this button to move one step"}, proc=moveRel_button, userData(direction)="1", userData(ch)="0"
	
	// stage 1, row 2, column 1
	top += 120
	DrawText left+5, top, "Step"
	PopupMenu stageStep0Popup, mode=5, pos = {left+5,top+5}, size={80,10}, proc=updateStageStep, title="X"
	PopupMenu stageStep0Popup, value="5000 um;1000 um;500 um;200 um;100 um;50 um;20 um;10 um;5um;2um;1 um;0.5 um;0.2 um;0.1 um;other..."
	PopupMenu stageStep0Popup, help={"The distance moved when you click the relative move buttons"}, userData(ch)="0"
	SetVariable stageStep0, title="", format="%.2f nm", pos={left+2,top-100}, size={50, 20}, noproc, disable=1
	SetVariable stageStep0, limits={-inf,inf,0}, value=root:global_variables:smaract_mcs:step_0
	
	PopupMenu stageStep1Popup, mode=5, pos = {left+5,top+25}, size={80,10}, proc=updateStageStep, title="Y"
	PopupMenu stageStep1Popup, value="5000 um;1000 um;500 um;200 um;100 um;50 um;20 um;10 um;5um;2um;1 um;0.5 um;0.2 um;0.1 um;other..."
	PopupMenu stageStep1Popup, help={"The distance moved when you click the relative move buttons"}, userData(ch)="0"
	SetVariable stageStep1, title="", format="%.2f nm", pos={left+75,top+-118}, size={50, 20}, noproc, disable=1
	SetVariable stageStep1, limits={-inf,inf,0}, value=root:global_variables:smaract_mcs:step_1
	
	PopupMenu stageStep2Popup, mode=5, pos = {left+5,top+45}, size={80,10}, proc=updateStageStep, title="Z"
	PopupMenu stageStep2Popup, value="5000 um;1000 um;500 um;200 um;100 um;50 um;20 um;10 um;5um;2um;1 um;0.5 um;0.2 um;0.1 um;other..."
	PopupMenu stageStep2Popup, help={"The distance moved when you click the relative move buttons"}, userData(ch)="0"
	SetVariable stageStep2, title="", format="%.2f nm", pos={left+120,top-70}, size={50, 20}, noproc, disable=1
	SetVariable stageStep2, limits={-inf,inf,0}, value=root:global_variables:smaract_mcs:step_2	
	
	// stage 1, row 2, column 2
	valdisplay stagePos0, pos={left+80, top+5}, size={60,20}, bodyWidth=60, title=""
	valdisplay stagePos0, limits={0,0,0}, barmisc={0,1000}
	valdisplay stagePos0, value= #"root:global_variables:smaract_mcs:pos_0"
	
	valdisplay stagePos1, pos={left+80, top+25}, size={60,20}, bodyWidth=60, title=""
	valdisplay stagePos1, limits={0,0,0}, barmisc={0,1000}
	valdisplay stagePos1, value= #"root:global_variables:smaract_mcs:pos_1"
	
	valdisplay stagePos2, pos={left+80, top+45}, size={60,20}, bodyWidth=60, title=""
	valdisplay stagePos2, limits={0,0,0}, barmisc={0,1000}
	valdisplay stagePos2, value= #"root:global_variables:smaract_mcs:pos_2"
	
	// stage1, row 3, column 1
	top += 85
	DrawText left+5, top, "Speed"
	PopupMenu stageSpeed0Popup, mode=5, pos = {left+5,top+5}, size={80,10}, proc=updateStageStep, title="X"
	PopupMenu stageSpeed0Popup, value="5000 um;1000 um;500 um;200 um;100 um;50 um;20 um;10 um;5um;2um;1 um;0.5 um;0.2 um;0.1 um;other..."
	PopupMenu stageSpeed0Popup, help={"The distance moved when you click the relative move buttons"}, userData(ch)="0"
	SetVariable stageSpeed0, title="", format="%.2f nm", pos={left+2,top-105}, size={50, 20}, noproc, disable=1
	SetVariable stageSpeed0, limits={-inf,inf,0}, value=root:global_variables:smaract_mcs:speed_0
	
	PopupMenu stageSpeed1Popup, mode=5, pos = {left+5,top+25}, size={80,10}, proc=updateStageStep, title="Y"
	PopupMenu stageSpeed1Popup, value="5000 um;1000 um;500 um;200 um;100 um;50 um;20 um;10 um;5um;2um;1 um;0.5 um;0.2 um;0.1 um;other..."
	PopupMenu stageSpeed1Popup, help={"The distance moved when you click the relative move buttons"}, userData(ch)="0"
	SetVariable stageSpeed1, title="", format="%.2f nm", pos={left+75,top+-123}, size={50, 20}, noproc, disable=1
	SetVariable stageSpeed1, limits={-inf,inf,0}, value=root:global_variables:smaract_mcs:speed_1
	
	PopupMenu stageSpeed2Popup, mode=5, pos = {left+5,top+45}, size={80,10}, proc=updateStageStep, title="Z"
	PopupMenu stageSpeed2Popup, value="5000 um;1000 um;500 um;200 um;100 um;50 um;20 um;10 um;5um;2um;1 um;0.5 um;0.2 um;0.1 um;other..."
	PopupMenu stageSpeed2Popup, help={"The distance moved when you click the relative move buttons"}, userData(ch)="0"
	SetVariable stageSpeed2, title="", format="%.2f nm", pos={left+120,top-75}, size={50, 20}, noproc, disable=1
	SetVariable stageSpeed2, limits={-inf,inf,0}, value=root:global_variables:smaract_mcs:speed_2	
	
	// stage 1, row 3, column 2
	valdisplay stageSpeedVal0, pos={left+80, top+5}, size={60,20}, bodyWidth=60, title=""
	valdisplay stageSpeedVal0, limits={0,0,0}, barmisc={0,1000}
	valdisplay stageSpeedVal0, value= #"root:global_variables:smaract_mcs:speed_0"
	
	valdisplay stageSpeedVal1, pos={left+80, top+25}, size={60,20}, bodyWidth=60, title=""
	valdisplay stageSpeedVal1, limits={0,0,0}, barmisc={0,1000}
	valdisplay stageSpeedVal1, value= #"root:global_variables:smaract_mcs:speed_1"
	
	valdisplay stageSpeedVal2, pos={left+80, top+45}, size={60,20}, bodyWidth=60, title=""
	valdisplay stageSpeedVal2, limits={0,0,0}, barmisc={0,1000}
	valdisplay stageSpeedVal2, value= #"root:global_variables:smaract_mcs:speed_2"
	
	// stage1, row 4, column 1
	top += 85
	DrawText left+5, top, "Acceleration"
	PopupMenu stageAcc0Popup, mode=5, pos = {left+5,top+5}, size={80,10}, proc=updateStageStep, title="X"
	PopupMenu stageAcc0Popup, value="5000 um;1000 um;500 um;200 um;100 um;50 um;20 um;10 um;5um;2um;1 um;0.5 um;0.2 um;0.1 um;other..."
	PopupMenu stageAcc0Popup, help={"The distance moved when you click the relative move buttons"}, userData(ch)="0"
	SetVariable stageAcc0, title="", format="%.2f nm", pos={left+2,top-105}, size={50, 20}, noproc, disable=1
	SetVariable stageAcc0, limits={-inf,inf,0}, value=root:global_variables:smaract_mcs:acc_0
	
	PopupMenu stageAcc1Popup, mode=5, pos = {left+5,top+25}, size={80,10}, proc=updateStageStep, title="Y"
	PopupMenu stageAcc1Popup, value="5000 um;1000 um;500 um;200 um;100 um;50 um;20 um;10 um;5um;2um;1 um;0.5 um;0.2 um;0.1 um;other..."
	PopupMenu stageAcc1Popup, help={"The distance moved when you click the relative move buttons"}, userData(ch)="0"
	SetVariable stageAcc1, title="", format="%.2f nm", pos={left+75,top+-123}, size={50, 20}, noproc, disable=1
	SetVariable stageAcc1, limits={-inf,inf,0}, value=root:global_variables:smaract_mcs:acc_1
	
	PopupMenu stageAcc2Popup, mode=5, pos = {left+5,top+45}, size={80,10}, proc=updateStageStep, title="Z"
	PopupMenu stageAcc2Popup, value="5000 um;1000 um;500 um;200 um;100 um;50 um;20 um;10 um;5um;2um;1 um;0.5 um;0.2 um;0.1 um;other..."
	PopupMenu stageAcc2Popup, help={"The distance moved when you click the relative move buttons"}, userData(ch)="0"
	SetVariable stageAcc2, title="", format="%.2f nm", pos={left+120,top-75}, size={50, 20}, noproc, disable=1
	SetVariable stageAcc2, limits={-inf,inf,0}, value=root:global_variables:smaract_mcs:acc_2	
	
	// stage 1, row 4, column 2
	valdisplay stageAccVal0, pos={left+80, top+5}, size={60,20}, bodyWidth=60, title=""
	valdisplay stageAccVal0, limits={0,0,0}, barmisc={0,1000}
	valdisplay stageAccVal0, value= #"root:global_variables:smaract_mcs:acc_0"
	
	valdisplay stageAccVal1, pos={left+80, top+25}, size={60,20}, bodyWidth=60, title=""
	valdisplay stageAccVal1, limits={0,0,0}, barmisc={0,1000}
	valdisplay stageAccVal1, value= #"root:global_variables:smaract_mcs:acc_1"
	
	valdisplay stageAccVal2, pos={left+80, top+45}, size={60,20}, bodyWidth=60, title=""
	valdisplay stageAccVal2, limits={0,0,0}, barmisc={0,1000}
	valdisplay stageAccVal2, value= #"root:global_variables:smaract_mcs:acc_2"
	
	// stage 2, row 1
	top -= 20+120+85+85
	left += groupBoxWidth+5
	groupbox stage2_group,pos={left, top},size={groupBoxWidth, groupBoxHeight},title="Stage 2"
	groupbox stage2_group, labelBack=(60928,60928,60928), fStyle=1
	
	top += 20
	Button stage2MoveLeft, picture=arrowPics#leftArrow, pos={left+5,top+45}, title="", help={"Click this button to move one step"}, proc=moveRel_button, userData(direction)="1", userData(ch)="0"
	Button stage2MoveRight, picture=arrowPics#rightArrow, pos={left+80,top+45}, title="", help={"Click this button to move one step"}, proc=moveRel_button, userData(direction)="1", userData(ch)="0"
	Button stage2MoveDown, picture=arrowPics#downArrow, pos={left+50,top+80}, title="", help={"Click this button to move one step"}, proc=moveRel_button, userData(direction)="1", userData(ch)="0"
	Button stage2MoveUp, picture=arrowPics#upArrow, pos={left+50,top}, title="", help={"Click this button to move one step"}, proc=moveRel_button, userData(direction)="1", userData(ch)="0"
	Button stage2MoveOut, picture=arrowPics#upArrow, pos={left+130,top}, title="", help={"Click this button to move one step"}, proc=moveRel_button, userData(direction)="1", userData(ch)="0"
	Button stage2MoveIn, picture=arrowPics#downArrow, pos={left+130, top+80}, title="", help={"Click this button to move one step"}, proc=moveRel_button, userData(direction)="1", userData(ch)="0"
	
	// stage 2, row 2, column 1
	top += 120
	DrawText left+5, top, "Step"
	PopupMenu stageStep3Popup, mode=5, pos = {left+5,top+5}, size={80,10}, proc=updateStageStep, title="X"
	PopupMenu stageStep3Popup, value="5000 um;1000 um;500 um;200 um;100 um;50 um;20 um;10 um;5um;2um;1 um;0.5 um;0.2 um;0.1 um;other..."
	PopupMenu stageStep3Popup, help={"The distance moved when you click the relative move buttons"}, userData(ch)="0"
	SetVariable stageStep3, title="", format="%.2f nm", pos={left+2,top-100}, size={50, 20}, noproc, disable=1
	SetVariable stageStep3, limits={-inf,inf,0}, value=root:global_variables:smaract_mcs:step_3
	
	PopupMenu stageStep4Popup, mode=5, pos = {left+5,top+25}, size={80,10}, proc=updateStageStep, title="Y"
	PopupMenu stageStep4Popup, value="5000 um;1000 um;500 um;200 um;100 um;50 um;20 um;10 um;5um;2um;1 um;0.5 um;0.2 um;0.1 um;other..."
	PopupMenu stageStep4Popup, help={"The distance moved when you click the relative move buttons"}, userData(ch)="0"
	SetVariable stageStep4, title="", format="%.2f nm", pos={left+75,top+-118}, size={50, 20}, noproc, disable=1
	SetVariable stageStep4, limits={-inf,inf,0}, value=root:global_variables:smaract_mcs:step_4
	
	PopupMenu stageStep5Popup, mode=5, pos = {left+5,top+45}, size={80,10}, proc=updateStageStep, title="Z"
	PopupMenu stageStep5Popup, value="5000 um;1000 um;500 um;200 um;100 um;50 um;20 um;10 um;5um;2um;1 um;0.5 um;0.2 um;0.1 um;other..."
	PopupMenu stageStep5Popup, help={"The distance moved when you click the relative move buttons"}, userData(ch)="0"
	SetVariable stageStep5, title="", format="%.2f nm", pos={left+120,top-70}, size={50, 20}, noproc, disable=1
	SetVariable stageStep5, limits={-inf,inf,0}, value=root:global_variables:smaract_mcs:step_5	
	
	// stage 2, row 2, column 2
	valdisplay stagePos3, pos={left+80, top+5}, size={60,20}, bodyWidth=60, title=""
	valdisplay stagePos3, limits={0,0,0}, barmisc={0,1000}
	valdisplay stagePos3, value= #"root:global_variables:smaract_mcs:pos_3"
	
	valdisplay stagePos4, pos={left+80, top+25}, size={60,20}, bodyWidth=60, title=""
	valdisplay stagePos4, limits={0,0,0}, barmisc={0,1000}
	valdisplay stagePos4, value= #"root:global_variables:smaract_mcs:pos_4"
	
	valdisplay stagePos5, pos={left+80, top+45}, size={60,20}, bodyWidth=60, title=""
	valdisplay stagePos5, limits={0,0,0}, barmisc={0,1000}
	valdisplay stagePos5, value= #"root:global_variables:smaract_mcs:pos_5"
	
	// stage1, row 3, column 1
	top += 85
	DrawText left+5, top, "Speed"
	PopupMenu stageSpeed3Popup, mode=5, pos = {left+5,top+5}, size={80,10}, proc=updateStageStep, title="X"
	PopupMenu stageSpeed3Popup, value="5000 um;1000 um;500 um;200 um;100 um;50 um;20 um;10 um;5um;2um;1 um;0.5 um;0.2 um;0.1 um;other..."
	PopupMenu stageSpeed3Popup, help={"The distance moved when you click the relative move buttons"}, userData(ch)="0"
	SetVariable stageSpeed3, title="", format="%.2f nm", pos={left+2,top-105}, size={50, 20}, noproc, disable=1
	SetVariable stageSpeed3, limits={-inf,inf,0}, value=root:global_variables:smaract_mcs:speed_3
	
	PopupMenu stageSpeed4Popup, mode=5, pos = {left+5,top+25}, size={80,10}, proc=updateStageStep, title="Y"
	PopupMenu stageSpeed4Popup, value="5000 um;1000 um;500 um;200 um;100 um;50 um;20 um;10 um;5um;2um;1 um;0.5 um;0.2 um;0.1 um;other..."
	PopupMenu stageSpeed4Popup, help={"The distance moved when you click the relative move buttons"}, userData(ch)="0"
	SetVariable stageSpeed4, title="", format="%.2f nm", pos={left+75,top+-123}, size={50, 20}, noproc, disable=1
	SetVariable stageSpeed4, limits={-inf,inf,0}, value=root:global_variables:smaract_mcs:speed_4
	
	PopupMenu stageSpeed5Popup, mode=5, pos = {left+5,top+45}, size={80,10}, proc=updateStageStep, title="Z"
	PopupMenu stageSpeed5Popup, value="5000 um;1000 um;500 um;200 um;100 um;50 um;20 um;10 um;5um;2um;1 um;0.5 um;0.2 um;0.1 um;other..."
	PopupMenu stageSpeed5Popup, help={"The distance moved when you click the relative move buttons"}, userData(ch)="0"
	SetVariable stageSpeed5, title="", format="%.2f nm", pos={left+120,top-75}, size={50, 20}, noproc, disable=1
	SetVariable stageSpeed5, limits={-inf,inf,0}, value=root:global_variables:smaract_mcs:speed_5
	
	// stage 2, row 3, column 2
	valdisplay stageSpeedVal3, pos={left+80, top+5}, size={60,20}, bodyWidth=60, title=""
	valdisplay stageSpeedVal3, limits={0,0,0}, barmisc={0,1000}
	valdisplay stageSpeedVal3, value= #"root:global_variables:smaract_mcs:speed_3"
	
	valdisplay stageSpeedVal4, pos={left+80, top+25}, size={60,20}, bodyWidth=60, title=""
	valdisplay stageSpeedVal4, limits={0,0,0}, barmisc={0,1000}
	valdisplay stageSpeedVal4, value= #"root:global_variables:smaract_mcs:speed_4"
	
	valdisplay stageSpeedVal5, pos={left+80, top+45}, size={60,20}, bodyWidth=60, title=""
	valdisplay stageSpeedVal5, limits={0,0,0}, barmisc={0,1000}
	valdisplay stageSpeedVal5, value= #"root:global_variables:smaract_mcs:speed_5"
	
	// stage 2, row 4, column 1
	top += 85
	DrawText left+5, top, "Acceleration"
	PopupMenu stageAcc3Popup, mode=5, pos = {left+5,top+5}, size={80,10}, proc=updateStageStep, title="X"
	PopupMenu stageAcc3Popup, value="5000 um;1000 um;500 um;200 um;100 um;50 um;20 um;10 um;5um;2um;1 um;0.5 um;0.2 um;0.1 um;other..."
	PopupMenu stageAcc3Popup, help={"The distance moved when you click the relative move buttons"}, userData(ch)="0"
	SetVariable stageAcc3, title="", format="%.2f nm", pos={left+2,top-105}, size={50, 20}, noproc, disable=1
	SetVariable stageAcc3, limits={-inf,inf,0}, value=root:global_variables:smaract_mcs:acc_3
	
	PopupMenu stageAcc4Popup, mode=5, pos = {left+5,top+25}, size={80,10}, proc=updateStageStep, title="Y"
	PopupMenu stageAcc4Popup, value="5000 um;1000 um;500 um;200 um;100 um;50 um;20 um;10 um;5um;2um;1 um;0.5 um;0.2 um;0.1 um;other..."
	PopupMenu stageAcc4Popup, help={"The distance moved when you click the relative move buttons"}, userData(ch)="0"
	SetVariable stageAcc4, title="", format="%.2f nm", pos={left+75,top+-123}, size={50, 20}, noproc, disable=1
	SetVariable stageAcc4, limits={-inf,inf,0}, value=root:global_variables:smaract_mcs:acc_4
	
	PopupMenu stageAcc5Popup, mode=5, pos = {left+5,top+45}, size={80,10}, proc=updateStageStep, title="Z"
	PopupMenu stageAcc5Popup, value="5000 um;1000 um;500 um;200 um;100 um;50 um;20 um;10 um;5um;2um;1 um;0.5 um;0.2 um;0.1 um;other..."
	PopupMenu stageAcc5Popup, help={"The distance moved when you click the relative move buttons"}, userData(ch)="0"
	SetVariable stageAcc5, title="", format="%.2f nm", pos={left+120,top-75}, size={50, 20}, noproc, disable=1
	SetVariable stageAcc5, limits={-inf,inf,0}, value=root:global_variables:smaract_mcs:acc_5	
	
	// stage 2, row 4, column 2
	valdisplay stageAccVal3, pos={left+80, top+5}, size={60,20}, bodyWidth=60, title=""
	valdisplay stageAccVal3, limits={0,0,0}, barmisc={0,1000}
	valdisplay stageAccVal3, value= #"root:global_variables:smaract_mcs:acc_3"
	
	valdisplay stageAccVal4, pos={left+80, top+25}, size={60,20}, bodyWidth=60, title=""
	valdisplay stageAccVal4, limits={0,0,0}, barmisc={0,1000}
	valdisplay stageAccVal4, value= #"root:global_variables:smaract_mcs:acc_4"
	
	valdisplay stageAccVal5, pos={left+80, top+45}, size={60,20}, bodyWidth=60, title=""
	valdisplay stageAccVal5, limits={0,0,0}, barmisc={0,1000}
	valdisplay stageAccVal5, value= #"root:global_variables:smaract_mcs:acc_5"
	
	return cmplx(l_size, t_size)
end