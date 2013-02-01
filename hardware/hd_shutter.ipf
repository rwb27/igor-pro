#pragma rtGlobals=1		// Use modern global access method.

function initialiseShtr(hShtr)
	variable hShtr
	switch(hShtr)
		case 1:
			VDT2/P=COM18 baud=9600
			break
	endswitch
	return 0
end

function opencommsShtr(hShtr)
	variable hShtr
	switch(hShtr)
		case 1:
			VDTOperationsPort2 COM18
			VDTOpenPort2 COM18
			break
		default:
			print "Shutter not available"
			return -1
	endswitch
	return 0
end

function closecommsShtr(hShtr)
	variable hShtr
	switch(hShtr)
		case 1:
			VDTOperationsPort2 None
			VDTClosePort2 COM18
			break
		default:
			print "Not a valid shutter"
			return -1
	endswitch
	return 0
end

function openShtrA(hShtr)
	variable hShtr
	variable status
	//status = opencommsShtr(hShtr)
	VDTWrite2 "openA\n"
	//status = closecommsShtr(hShtr)
	return status
end

function closeShtrA(hShtr)
	variable hShtr
	variable status
	//status = opencommsShtr(hShtr)
	VDTWrite2 "closeA\n"
	//status = closecommsShtr(hShtr)
	return status
end

function flipShtrA(hShtr)
	variable hShtr
	variable status
	//status = opencommsShtr(hShtr)
	VDTWrite2 "flipA\n"
	//status = closecommsShtr(hShtr)
	return status
end

function openShtrB(hShtr)
	variable hShtr
	variable status
	VDTWrite2 "openB\n"
	return status
end

function closeShtrB(hShtr)
	variable hShtr
	variable status
	VDTWrite2 "closeB\n"
	return status
end

function flipShtrB(hShtr)
	variable hShtr
	variable status
	VDTWrite2 "flipB\n"
	return status
end

function openShtrs(hShtr)
	variable hShtr
	variable status
	VDTWrite2 "open\n"
	return status
end

function closeShtrs(hShtr)
	variable hShtr
	variable status
	VDTWrite2 "close\n"
	return status
end

function flipShtrs(hShtr)
	variable hShtr
	variable status
	VDTWrite2 "flip\n"
	return status
end

function opencommsShtr_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			opencommsShtr(1)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

function closecommsShtr_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			closecommsShtr(1)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

function openShtrA_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			openShtrA(1)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

function closeShtrA_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			closeShtrA(1)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

function flipShtrA_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			flipShtrA(1)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

function openShtrB_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			openShtrB(1)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

function closeShtrB_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			closeShtrB(1)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

function flipShtrB_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			flipShtrB(1)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

function openShtrs_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			openShtrs(1)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

function closeShtrs_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			closeShtrs(1)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

function flipShtrs_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			flipShtrs(1)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
end

Window HD_MultiShtr() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(786,78,1066,188) as "HD Multi-Shutter"
	ModifyPanel frameStyle=1
	ShowTools/A
	TitleBox HDmultishtr,pos={5,5},size={137,13},title="Hard-Drive Multi-Shutter"
	TitleBox HDmultishtr,frame=0,fStyle=1
	Button opencomms,pos={5,25},size={80,20},proc=opencommsShtr_button,title="Open Comms"
	Button opencomms,labelBack=(65535,65535,65535),fSize=11,fColor=(65280,65280,0)
	Button closecomms,pos={5,45},size={80,20},proc=closecommsShtr_button,title="Close Comms"
	Button closecomms,labelBack=(65535,65535,65535),fSize=11,fColor=(52224,0,0)
	Button openshtrA,pos={5,65},size={50,20},proc=openShtrA_button,title="Open A"
	Button openshtrA,labelBack=(65535,65535,65535),fSize=11,fColor=(26112,52224,0)
	Button closeshtrA,pos={55,65},size={50,20},proc=closeShtrA_button,title="Close A"
	Button closeshtrA,labelBack=(65535,65535,65535),fSize=11,fColor=(52224,0,0)
	Button flipshtrA,pos={105,65},size={50,20},proc=flipShtrA_button,title="Flip A"
	Button flipshtrA,labelBack=(65535,65535,65535),fSize=11,fColor=(65280,65280,0)
	Button openshtrB,pos={5,85},size={50,20},proc=openShtrB_button,title="Open B"
	Button openshtrB,labelBack=(65535,65535,65535),fSize=11,fColor=(26112,52224,0)
	Button closeshtrB,pos={55,85},size={50,20},proc=closeShtrB_button,title="Close B"
	Button closeshtrB,labelBack=(65535,65535,65535),fSize=11,fColor=(52224,0,0)
	Button flipshtrB,pos={105,85},size={50,20},proc=flipShtrB_button,title="Flip B"
	Button flipshtrB,labelBack=(65535,65535,65535),fSize=11,fColor=(65280,65280,0)
	Button openshtrAB,pos={155,65},size={40,40},proc=openShtrs_button,title="Open\rA&B"
	Button openshtrAB,labelBack=(65535,65535,65535),fSize=11,fColor=(26112,52224,0)
	Button closeshtrAB,pos={195,65},size={40,40},proc=closeShtrs_button,title="Close\rA&B"
	Button closeshtrAB,labelBack=(65535,65535,65535),fSize=11,fColor=(52224,0,0)
	Button flipshtrAB,pos={235,65},size={40,40},proc=flipShtrs_button,title="Flip\rA&B"
	Button flipshtrAB,labelBack=(65535,65535,65535),fSize=11,fColor=(65280,65280,0)
	ValDisplay statusshtrA,pos={90,25},size={84,14},bodyWidth=40,title="Status A"
	ValDisplay statusshtrA,fSize=11,frame=2,limits={0,0,0},barmisc={0,1000},mode= 1
	ValDisplay statusshtrA,value= #"0"
	ValDisplay statusshtrB,pos={90,45},size={84,14},bodyWidth=40,title="Status B"
	ValDisplay statusshtrB,fSize=11,frame=2,limits={0,0,0},barmisc={0,1000},mode= 1
	ValDisplay statusshtrB,value= #"0"
EndMacro
