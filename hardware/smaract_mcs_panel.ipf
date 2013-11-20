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

Function/S numericPopupItems(start, stop, [units, otherValue, formatString])
	//this function returns a semicolon-separated list of items for a numeric pop up menu
	//they will be 1,2,5 * 10^n for integer n
	//units specifies a unit to be appended to the strings (NB the numbers are displayed with SI prefixes)
	//otherValue adds an "other..." option, if it is set to a numeric value that value is added to the bottom.
	//if otherValue is NaN, the "other..." option is displayed but no extra value is shown.
	variable start, stop
	string units, formatString
	variable otherValue
	if(paramIsDefault(units))
		units = ""
	endif
	if(paramIsDefault(formatString))
		formatString = "%.0W1P"
	endif
	
	variable startn = floor(log(start)), stopn = ceil(log(stop))
	make/free mantissa = {1,2,5}
	variable n, i
	string items = "", item
	for(n=startn; n<=stopn; n+=1)
		for(i=0; i<numpnts(mantissa); i+=1)
			if(start <= mantissa[i] * 10^n && mantissa[i] * 10^n <= stop)
				sprintf item, formatString+units+";", mantissa[i] * 10^n
				items += item
			endif
		endfor
	endfor
	if(!paramIsDefault(otherValue))
		items += "other..."
		if(numType(otherValue)==0)
			sprintf item, ";"+formatString+units, otherValue
			items += item
		endif
	endif
	return items
end

function numericPopupItemValue(start, index)
	//calculate the numeric value of an item from a numeric popup (useful because the SI notation can be hard to parse)
	variable start, index
	variable startn = floor(log(start))
	make/free mantissa = {1,2,5}
	variable starti
	for(starti=0; starti<numpnts(mantissa); starti+=1)
		if(start <= mantissa[starti])
			break;
		endif
	endfor
	return 10^(startn + floor( (index + starti) /numpnts(mantissa) ) ) * mantissa[mod(index + starti, numpnts(mantissa))]
end

Function handleNumericPopupWithOther(action)
	//this returns the value of a numeric popup item generated with the function of a similar name...
	//if the user selected "other", it displays a dialog and then adds the new value to the popup and selects it.
	Struct wmPopupAction &action
	if(action.eventCode == 2)
		if(stringmatch(action.popStr, "*other*"))
			variable otherValue = 0;
			prompt otherValue, "Enter the new value in "+getUserData(action.win, action.ctrlName, "units")
			doPrompt "Custom Value", otherValue
			string items
			items = "\""+numericPopupItems(str2num(getUserData(action.win, action.ctrlName, "start")), str2num(getUserData(action.win, action.ctrlName, "stop")), units=getUserData(action.win, action.ctrlName, "units"), otherValue=otherValue)+"\""
			popupMenu $action.ctrlName, value=#items
			popupMenu $action.ctrlName, mode=itemsInList(items)
			return otherValue
		else
			return numericPopupItemValue(str2num(getUserData(action.win, action.ctrlName, "start")), action.popNum-1)
		endif
	else
		return NaN
	endif
end
Function updateGlobalFromNumericPopup(action)
	//helper function to ensure a variable is kept up to date with the contents of a numeric popup menu
	Struct wmPopupAction &action
	variable newValue =  handleNumericPopupWithOther(action)
	string varname = getUserData(action.win, action.ctrlName, "globalToUpdate")
	if(strlen(varname)>0)
		if(!exists(varname))
			variable/g $varname
		endif
		NVAR globalToUpdate = $varname
		globalToUpdate = newValue
	endif
end	

Function numericPopup(ctrlName, start, stop, [units, otherValue, globalVariableName])
	//create a popupMenu control with numeric values.  It can optionally have an "other" item, which enables the input of arbitrary values.
	//start and stop set the first and last numeric values; at the moment it is fixed to 1,2,5 * 10^n for the values (other interpolations may be
	//added in the future).  Giving it "units" does the obvious thing, bear in mind that it adds SI prefixes, so use m rather than nm or odd 
	//things may happen!
	string ctrlName, units, globalVariableName
	variable start, stop, otherValue
	if(paramIsDefault(units))
		units = ""
	endif
	string items
	items = "\""+numericPopupItems(start, stop, units=units, otherValue=otherValue)+"\""
	popupMenu $ctrlName, value=#items, userData(units)=units, userData(start)=num2str(start), userData(stop)=num2str(stop)
	if(!paramIsDefault(globalVariableName))
		popupMenu $ctrlName userData(globalToUpdate)=globalVariableName, proc=updateGlobalFromNumericPopup
	endif
End

Function/c insert_xyz_arrows(left, top, namePrefix, procname, channel) : panel
	variable left, top
	string namePrefix, procname, channel
	
	string names = "Left;Right;Down;Up;Out;In"
	string arrows = "left;right;down;up;up;down"
	string directions = "-1;0;0|1;0;0|0;-1;0|0;1;0|0;0;1|0;0;-1"
	make/Free pos = {{5,45}, {80,45}, {50,80}, {50,0}, {130,0}, {130,80}}
	
	variable i
	for(i=0; i<6; i+=1)
		string buttonName = namePrefix + StringFromList(i, names)
		string arrowPicture = "arrowPics#" + StringFromList(i, arrows) + "Arrow"
		Button $buttonName, picture=$arrowPicture, pos={left+pos[0][i],top+pos[1][i]}, title="", help={"Click this button to move one step"}, proc=$procname, userData(direction)=StringFromList(i, directions, "|"), userData(ch)=(channel)
	endfor
	
	return cmplx(170, 120)
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
	left += 5; top += 25
	
	// stage 1 - groupbox containing each stage movements
	groupbox stage1_group,pos={left, top},size={groupBoxWidth, groupBoxHeight},title="Stage 1"
	groupbox stage1_group, labelBack=(60928,60928,60928), fStyle=1
	top += 20
	
	// stage 1, row 1 - movement controls
	top += imag( insert_xyz_arrows(left, top, "stage1Move", "moveRel_button", "0"))
	
	// stage 1, row 2, column 1 & 2
	DrawText left+5, top, "Step"
	variable i
	string axes = "X;Y;Z"
	for(i=0; i<3; i+=1)
		string popupName = "stageStep"+num2str(i)+"Popup"
		numericPopup(popupName, 1e-9, 5e-3, units="m", otherValue=NaN, globalVariableName="root:global_variables:smaract_mcs:step_"+num2str(i))
		PopupMenu $popupName, mode=5, pos = {left+5,top+5+20*i}, size={80,10}, title=stringFromList(i,axes)
		PopupMenu $popupName, help={"The distance moved when you click the relative move buttons"}, userData(ch)="0"
		
		string vdName = "stagePos"+num2str(i)
		string valueName = "root:global_variables:smaract_mcs:pos_"+num2str(i)
		valdisplay $vdName, pos={left+80, top+5+20*i}, size={60,20}, bodyWidth=60, title="", limits={0,0,0}, barmisc={0,1000}, value= #valueName
	endfor
	
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
	
	top += imag( insert_xyz_arrows(left, top, "stage2Move", "moveRel_button", "0"))
	
	// stage 2, row 2, column 1
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