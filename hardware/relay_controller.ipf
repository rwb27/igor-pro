#pragma rtGlobals=1		// Use modern global access method.

function initialiseSBox()
	VDT2/P=COM24 baud=9600
	return 0
end

function opencommsSBox()
	VDTOperationsPort2 COM24
	VDTOpenPort2 COM24
	return 0
end

function closecommsSBox()
	VDTOperationsPort2 None
	VDTClosePort2 COM24
	return 0
end

function switchAC()
	variable status
	//status = opencommsShtr(hShtr)
	VDTWrite2 "switchAC\n"
	//status = closecommsShtr(hShtr)
	return status
end

function switchDC()
	variable status
	//status = opencommsShtr(hShtr)
	VDTWrite2 "switchDC\n"
	//status = closecommsShtr(hShtr)
	return status
end

function switchDCamp()
	variable status
	//status = opencommsShtr(hShtr)
	VDTWrite2 "switchDCamp\n"
	//status = closecommsShtr(hShtr)
	return status
end

function config()
	variable status
	//status = opencommsShtr(hShtr)
	VDTWrite2 "config?\n"
	VDTRead2
	//status = closecommsShtr(hShtr)
	return status
end

function opencommsSBox_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			opencommsSBox()
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

function closecommsSBox_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			closecommsSBox()
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

function switchAC_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			switchAC()
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

function switchDC_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			switchDC()
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

function switchDCamp_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			switchDCamp()
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

Window SBox_Controller() : Panel
	PauseUpdate; Silent 1		// building window...
	variable l = 786, t = 78, r = l + 125 + 80 + 5, b = t + 45 + 20 + 5
	NewPanel /W=(l,t,r,b) as "SwitchBox Controller"
	ModifyPanel frameStyle=1
	ShowTools/A
	TitleBox SBoxCont,pos={5,5},size={137,13},title="Switch Box Controller"
	TitleBox SBoxCont,frame=0,fStyle=1
	Button opencomms,pos={5,25},size={80,20},proc=opencommsSBox_button,title="Open Comms"
	Button opencomms,labelBack=(65535,65535,65535),fSize=11,fColor=(65280,65280,0)
	Button closecomms,pos={85,25},size={80,20},proc=closecommsSBox_button,title="Close Comms"
	Button closecomms,labelBack=(65535,65535,65535),fSize=11,fColor=(52224,0,0)
	Button switchAC,pos={5,45},size={60,20},proc=switchAC_button,title="Switch AC"
	Button switchAC,labelBack=(65535,65535,65535),fSize=11,fColor=(26112,52224,0)
	Button switchDC,pos={65,45},size={60,20},proc=switchDC_button,title="Switch DC"
	Button switchDC,labelBack=(65535,65535,65535),fSize=11,fColor=(52224,0,0)
	Button switchDCamp,pos={125,45},size={80,20},proc=switchDCamp_button,title="Switch DC Amp"
	Button switchDCamp,labelBack=(65535,65535,65535),fSize=11,fColor=(65280,65280,0)
EndMacro