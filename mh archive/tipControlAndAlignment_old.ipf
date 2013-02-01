#pragma rtGlobals=1		// Use modern global access method.



//=============================================================
// PZ actuator commands

function PZactuator_currPos()
	// Get current positions and store in global variables
	NVAR posA = root:gVariables:PZactuators:posA
	NVAR posB = root:gVariables:PZactuators:posB
	NVAR posC = root:gVariables:PZactuators:posC
	
	posA = str2num(cmdPI("pos? A"))
	posB = str2num(cmdPI("pos? B"))
	posC = str2num(cmdPI("pos? C"))

end

function PZactuator_startingPos()
	// Move PZ to starting position then update position variables
	movePI("A",20)
	movePI("B",20)
	movePI("C",5)
	sleep/s 3
	PZactuator_currPos()
end

function PZactuator_startUp()
	// Turn on motors, initialize variables, and get inital positions and velocities
	variable/g root:gVariables:PZactuators:posA = 0
	variable/g root:gVariables:PZactuators:posB = 0
	variable/g root:gVariables:PZactuators:posC = 0
	variable/g root:gVariables:PZactuators:stepA = 0
	variable/g root:gVariables:PZactuators:stepB = 0
	variable/g root:gVariables:PZactuators:stepC = 0
	
	startUp()	
	
	PZactuator_currPos()
	PZactuator_velocityQuery()
end

function PZactuator_shutDown()
	// Turn off motors, reset variables
	variable/g root:gVariables:PZactuators:posA = 0
	variable/g root:gVariables:PZactuators:posB = 0
	variable/g root:gVariables:PZactuators:posC = 0
	variable/g root:gVariables:PZactuators:stepA = -1
	variable/g root:gVariables:PZactuators:stepB = -1
	variable/g root:gVariables:PZactuators:stepC = -1

	
	shutDown()	
end

function PZactuator_velocityQuery()
	// Query controller for velocities and update global variables

	NVAR velA = root:gVariables:PZactuators:velA
	NVAR velB = root:gVariables:PZactuators:velB
	NVAR velC = root:gVariables:PZactuators:velC
	
	velA = str2num(cmdPI("vel? A"))
	velB = str2num(cmdPI("vel? B"))
	velC = str2num(cmdPI("vel? C"))

end

function PZactuator_velocitySet()
	// Set PZ veolocities, then query controller and update global variables to confirm

	NVAR velA = root:gVariables:PZactuators:velA
	NVAR velB = root:gVariables:PZactuators:velB
	NVAR velC = root:gVariables:PZactuators:velC
	
	cmdPI("vel A"+num2str(velA))
	cmdPI("vel B"+num2str(velB))
	cmdPI("vel C"+num2str(velC))
	
	PZactuator_velocityQuery()
	
end

function PZactuator_dcoQuery()
	// Query controller for drift compensation status and update global variables

	NVAR dcoA = root:gVariables:PZactuators:dcoA
	NVAR dcoB = root:gVariables:PZactuators:dcoB
	NVAR dcoC = root:gVariables:PZactuators:dcoC
	
	dcoA = str2num(cmdPI("dco? A"))
	dcoB = str2num(cmdPI("dco? B"))
	dcoC = str2num(cmdPI("dco? C"))
	
end

function PZactuator_dcoSet()
	// Set PZ veolocities, then query controller and update global variables to confirm

	NVAR dcoA = root:gVariables:PZactuators:dcoA
	NVAR dcoB = root:gVariables:PZactuators:dcoB
	NVAR dcoC = root:gVariables:PZactuators:dcoC
	
	cmdPI("dco A"+num2str(dcoA))
	cmdPI("dco B"+num2str(dcoB))
	cmdPI("dco C"+num2str(dcoC))
	
	PZactuator_dcoQuery()
	
end


//=============================================================
// Newport AC commands

function newportAC_currPos()
	// Get current positions and store in global variables
	NVAR PZZpos =  root:gVariables:newPortActuators:PZZpos
	NVAR PZYpos = root:gVariables:newPortActuators:PZYpos
	NVAR HLXpos = root:gVariables:newPortActuators:HLXpos
	
	PZZpos = str2num(posPZZ())/100		// PZZ actuator position
	PZYpos = str2num(posPZY())/100		// PZY actuator position
	HLXpos = str2num(posHLX())*1000		// HLX actuator position
end

function newportAC_startUp()
	// Turn on motors, initialize variables, and get inital positions
	variable/g root:gVariables:newPortActuators:PZZpos = 0
	variable/g root:gVariables:newPortActuators:PZYpos = 0
	variable/g root:gVariables:newPortActuators:HLXpos = 0
	variable/g root:gVariables:newPortActuators:PZZstep = 1
	variable/g root:gVariables:newPortActuators:PZYstep = 1
	variable/g root:gVariables:newPortActuators:HLXstep = 1
	
	cmdHLX("MM1")
	cmdPZZ("MO")
	cmdPZY("MO")
	Sleep/S 1.0
	
	newportAC_currPos()
	
end

function newportAC_shutDown()
	// Turn on motors, initialize variables, and get inital positions
	variable/g root:gVariables:newPortActuators:PZZpos = 0
	variable/g root:gVariables:newPortActuators:PZYpos = 0
	variable/g root:gVariables:newPortActuators:HLXpos = 0
	variable/g root:gVariables:newPortActuators:PZZstep = -1
	variable/g root:gVariables:newPortActuators:PZYstep = -1
	variable/g root:gVariables:newPortActuators:HLXstep = -1
	
	cmdHLX("MM0")
	cmdPZZ("MF")
	cmdPZY("MF")
	Sleep/S 1.0
	
	// newportAC_currPos()
	
end

function PZZmove(deltaPos)
	// Move PZZ actuator by 'deltaPos' (in um units)
	variable deltaPos
	string cmd = "PR"+num2str(deltaPos*100)
	cmdPZZ(cmd)
end

function PZYmove(deltaPos)
	// Move PZY actuator by 'deltaPos' (in um units)
	variable deltaPos
	string cmd = "PR"+num2str(deltaPos*100)
	cmdPZY(cmd)
end

function HLXmove(deltaPos)
	// Move HLX actuator by 'deltaPos' (in um units)
	variable deltaPos
	string cmd = "PR"+num2str(deltaPos/1000)
	cmdHLX(cmd)
end


//=============================================================
// Create actuator control and alignment panel
Window ActuatorsAndAlignment() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(715,297,1255,872)
	ShowTools/A
	SetDrawLayer UserBack
	SetDrawEnv fsize= 14,fstyle= 1
	DrawText 19,27,"Newport Actuator Control (coarse movement, both tips)"
	SetDrawEnv linethick= 4
	DrawLine 9,151,465,151
	SetDrawEnv fsize= 14,fstyle= 1
	DrawText 16,179,"PZ Actuator Control (fine movement, left tip only)"
	DrawText 410,66,"Right/Left"
	DrawText 410,94,"Focus (Away/Towards)"
	DrawText 410,124,"Up/Down"
	DrawText 413,213,"Left/Right"
	DrawText 413,243,"Down/Up"
	DrawText 414,271,"Focus"
	SetDrawEnv fstyle= 4
	DrawText 409,43,"Sample Moves:"
	SetDrawEnv fstyle= 4
	DrawText 381,182,"Sample Moves:"
	SetDrawEnv linethick= 4
	DrawLine 9,386,465,386
	SetDrawEnv fsize= 14,fstyle= 1
	DrawText 17,414,"Alignment Electronics"
	SetDrawEnv fsize= 14,fstyle= 1
	DrawText 16,511,"Tip Alignment Scan"
	ValDisplay valdisp0,pos={81,49},size={112,17},bodyWidth=60,title="PZZpos"
	ValDisplay valdisp0,fSize=14,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp0,value= #"root:gVariables:newPortActuators:PZZpos"
	ValDisplay valdisp1,pos={80,78},size={113,17},bodyWidth=60,title="PZYpos"
	ValDisplay valdisp1,fSize=14,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp1,value= #"root:gVariables:newPortActuators:PZYpos"
	ValDisplay valdisp2,pos={81,107},size={112,17},bodyWidth=60,title="HLXpos"
	ValDisplay valdisp2,fSize=14,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp2,value= #"root:gVariables:newPortActuators:HLXpos"
	SetVariable setvar0,pos={312,48},size={95,20},bodyWidth=40,title="PZZstep"
	SetVariable setvar0,fSize=14
	SetVariable setvar0,limits={-inf,inf,0},value= root:gVariables:newPortActuators:PZZstep
	SetVariable setvar1,pos={312,77},size={96,20},bodyWidth=40,title="PZYstep"
	SetVariable setvar1,fSize=14
	SetVariable setvar1,limits={-inf,inf,0},value= root:gVariables:newPortActuators:PZYstep
	SetVariable setvar2,pos={312,106},size={95,20},bodyWidth=40,title="HLXstep"
	SetVariable setvar2,fSize=14
	SetVariable setvar2,limits={-inf,inf,0},value= root:gVariables:newPortActuators:HLXstep
	Button button0,pos={13,35},size={60,50},proc=ButtonProc,title="Startup",fSize=12
	Button button0,fColor=(0,52224,0)
	Button button1,pos={13,90},size={60,50},proc=ButtonProc_1,title="Shutdown"
	Button button1,fSize=12,fColor=(65280,0,0)
	Button PZZposUP,pos={201,45},size={50,25},proc=ButtonProc_2,title="Up",fSize=14
	Button PZZposDOWN,pos={255,45},size={50,25},proc=ButtonProc_3,title="Down"
	Button PZZposDOWN,fSize=14
	Button PZYposUP,pos={201,74},size={50,25},proc=ButtonProc_4,title="Up",fSize=14
	Button PZYposDOWN,pos={255,74},size={50,25},proc=ButtonProc_5,title="Down"
	Button PZYposDOWN,fSize=14
	Button HLXposUP,pos={201,103},size={50,25},proc=ButtonProc_6,title="Up",fSize=14
	Button HLXposDOWN,pos={255,103},size={50,25},proc=ButtonProc_7,title="Down"
	Button HLXposDOWN,fSize=14
	Button button2,pos={13,192},size={92,50},proc=ButtonProc_8,title="Startup"
	Button button2,fSize=12,fColor=(0,52224,0)
	Button button3,pos={13,322},size={92,50},proc=ButtonProc_9,title="Shutdown"
	Button button3,fSize=12,fColor=(65280,0,0)
	ValDisplay valdisp3,pos={126,196},size={96,17},bodyWidth=60,title="posA"
	ValDisplay valdisp3,fSize=14,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp3,value= #"root:gVariables:PZactuators:posA"
	ValDisplay valdisp4,pos={126,226},size={96,17},bodyWidth=60,title="posB"
	ValDisplay valdisp4,fSize=14,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp4,value= #"root:gVariables:PZactuators:posB"
	ValDisplay valdisp5,pos={126,255},size={96,17},bodyWidth=60,title="posC"
	ValDisplay valdisp5,fSize=14,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp5,value= #"root:gVariables:PZactuators:posC"
	SetVariable setvar3,pos={331,195},size={79,20},bodyWidth=40,title="stepA"
	SetVariable setvar3,fSize=14
	SetVariable setvar3,limits={-inf,inf,0},value= root:gVariables:PZactuators:stepA
	SetVariable setvar4,pos={331,225},size={79,20},bodyWidth=40,title="stepB"
	SetVariable setvar4,fSize=14
	SetVariable setvar4,limits={-inf,inf,0},value= root:gVariables:PZactuators:stepB
	SetVariable setvar5,pos={331,255},size={79,20},bodyWidth=40,title="stepC"
	SetVariable setvar5,fSize=14
	SetVariable setvar5,limits={-inf,inf,0},value= root:gVariables:PZactuators:stepC
	Button button4,pos={13,257},size={92,50},proc=ButtonProc_10,title="Starting\rPositions"
	Button button4,fSize=12
	Button button5,pos={162,281},size={248,36},proc=ButtonProc_11,title="UpdatePositions"
	Button button5,fSize=12
	Button button6,pos={223,192},size={50,25},proc=ButtonProc_12,title="Up",fSize=14
	Button button7,pos={276,192},size={50,25},proc=ButtonProc_13,title="Down"
	Button button7,fSize=14
	Button button8,pos={223,222},size={50,25},proc=ButtonProc_14,title="Up",fSize=14
	Button button9,pos={276,222},size={50,25},proc=ButtonProc_15,title="Down"
	Button button9,fSize=14
	Button button09,pos={223,251},size={50,25},proc=ButtonProc_16,title="Up"
	Button button09,fSize=14
	Button button10,pos={277,251},size={50,25},proc=ButtonProc_17,title="Down"
	Button button10,fSize=14
	SetVariable setvar6,pos={17,416},size={145,20},bodyWidth=50,title="Frequency (Hz)"
	SetVariable setvar6,fSize=14
	SetVariable setvar6,limits={0,1.5e+07,0},value= root:gVariables:HPsigGenerator:sigGenFrequency
	Button button11,pos={172,416},size={50,20},proc=ButtonProc_20,title="Set"
	Button button11,fSize=14
	SetVariable setvar7,pos={12,440},size={150,20},bodyWidth=50,title="Amplitude (Vpp)"
	SetVariable setvar7,fSize=14
	SetVariable setvar7,limits={0,50,0},value= root:gVariables:HPsigGenerator:sigGenAmplitude
	SetVariable setvar8,pos={34,465},size={128,20},bodyWidth=50,title="DC offset (V)"
	SetVariable setvar8,fSize=14
	SetVariable setvar8,limits={-inf,inf,0},value= root:gVariables:HPsigGenerator:sigGenDC
	SetVariable setvar9,pos={238,416},size={175,20},bodyWidth=50,title="Start Frequency (Hz)"
	SetVariable setvar9,fSize=14
	SetVariable setvar9,limits={-inf,inf,0},value= root:gVariables:HPsigGenerator:sigGenFreqStart
	SetVariable setvar10,pos={237,440},size={176,20},bodyWidth=50,title="Stop Frequency (Hz)"
	SetVariable setvar10,fSize=14
	SetVariable setvar10,limits={-inf,inf,0},value= root:gVariables:HPsigGenerator:sigGenFreqStop
	SetVariable setvar11,pos={237,465},size={176,20},bodyWidth=50,title="Frequency Step (Hz)"
	SetVariable setvar11,fSize=14
	SetVariable setvar11,limits={-inf,inf,0},value= root:gVariables:HPsigGenerator:sigGenFreqStep
	Button button14,pos={420,416},size={50,70},proc=ButtonProc_23,title="Run\rScan"
	Button button14,fSize=14
	Button button12,pos={172,440},size={50,20},proc=ButtonProc_21,title="Set"
	Button button12,fSize=14
	Button button13,pos={172,465},size={50,20},proc=ButtonProc_22,title="Set"
	Button button13,fSize=14
	SetVariable setvar12,pos={25,518},size={137,20},bodyWidth=50,title="Grid Size (um)"
	SetVariable setvar12,fSize=14
	SetVariable setvar12,limits={0,inf,0},value= root:gVariables:tipAlignment:gridSize
	SetVariable setvar13,pos={23,542},size={139,20},bodyWidth=50,title="Grid Step (um)"
	SetVariable setvar13,fSize=14
	SetVariable setvar13,limits={0,inf,0},value= root:gVariables:tipAlignment:gridStep
	Button button15,pos={169,515},size={70,50},proc=ButtonProc_18,title="Run\rScan"
	Button button15,fSize=14
	ValDisplay valdisp6,pos={254,520},size={116,17},bodyWidth=50,title="Centroid B"
	ValDisplay valdisp6,fSize=14,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp6,value= #"root:gVariables:tipAlignment:centroidB"
	ValDisplay valdisp7,pos={254,546},size={116,17},bodyWidth=50,title="Centroid C"
	ValDisplay valdisp7,fSize=14,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp7,value= #"root:gVariables:tipAlignment:centroidC"
	Button button16,pos={378,516},size={70,50},proc=ButtonProc_19,title="Move To\rCentroid"
	Button button16,fSize=14
	Button button17,pos={333,327},size={50,20},proc=ButtonProc_40,title="Query"
	Button button17,fSize=14
	SetVariable setvar14,pos={131,327},size={61,20},bodyWidth=30,title="velA"
	SetVariable setvar14,fSize=14
	SetVariable setvar14,limits={0,inf,0},value= root:gVariables:PZactuators:velA
	SetVariable setvar15,pos={197,327},size={61,20},bodyWidth=30,title="velB"
	SetVariable setvar15,fSize=14
	SetVariable setvar15,limits={0,inf,0},value= root:gVariables:PZactuators:velB
	SetVariable setvar16,pos={264,327},size={61,20},bodyWidth=30,title="velC"
	SetVariable setvar16,fSize=14
	SetVariable setvar16,limits={0,inf,0},value= root:gVariables:PZactuators:velC
	Button button18,pos={388,327},size={50,20},proc=ButtonProc_41,title="Set"
	Button button18,fSize=14
	SetVariable setvar17,pos={126,352},size={66,20},bodyWidth=30,title="dcoA"
	SetVariable setvar17,fSize=14
	SetVariable setvar17,limits={0,inf,0},value= root:gVariables:PZactuators:dcoA
	SetVariable setvar18,pos={192,352},size={66,20},bodyWidth=30,title="dcoB"
	SetVariable setvar18,fSize=14
	SetVariable setvar18,limits={0,inf,0},value= root:gVariables:PZactuators:dcoB
	SetVariable setvar19,pos={259,352},size={66,20},bodyWidth=30,title="dcoC"
	SetVariable setvar19,fSize=14
	SetVariable setvar19,limits={0,inf,0},value= root:gVariables:PZactuators:dcoC
	Button button19,pos={388,352},size={50,20},proc=ButtonProc_43,title="Set"
	Button button19,fSize=14
	Button button20,pos={333,352},size={50,20},proc=ButtonProc_42,title="Query"
	Button button20,fSize=14
EndMacro


//=========================================================
// Newport actuator controls
Function ButtonProc(ba) : ButtonControl
	// Newport AC startup button
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			newportAC_startUp()			
			break
	endswitch

	return 0
End

Function ButtonProc_1(ba) : ButtonControl
	// Newport AC shutdown button
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			newportAC_shutDown()
			break
	endswitch

	return 0
End

Function ButtonProc_2(ba) : ButtonControl
	// Increment PZZposition by PZZstep
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			NVAR PZZstep = root:gVariables:newPortActuators:PZZstep
			PZZmove(PZZstep)
			sleep/s PZZstep/1000		// Delay (10s/mm) to allow stable movement
			newportAC_currPos()		// Update position variables
			break
	endswitch

	return 0
End

Function ButtonProc_3(ba) : ButtonControl
	// Decrement PZZposition by PZZstep
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			NVAR PZZstep = root:gVariables:newPortActuators:PZZstep
			PZZmove(-PZZstep)
			sleep/s PZZstep/1000		// Delay (10s/mm) to allow stable movement			
			newportAC_currPos()		// Update position variables
			break
	endswitch

	return 0
End

Function ButtonProc_4(ba) : ButtonControl
	// Increment PZYposition by PZYstep
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			NVAR PZYstep = root:gVariables:newPortActuators:PZYstep
			PZYmove(PZYstep)
			sleep/s PZYstep/1000		// Delay (10s/mm) to allow stable movement
			newportAC_currPos()		// Update position variables			
			break
	endswitch

	return 0
End

Function ButtonProc_5(ba) : ButtonControl
	// Decrement PZYposition by PZYstep
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			NVAR PZYstep = root:gVariables:newPortActuators:PZYstep
			PZYmove(-PZYstep)
			sleep/s PZYstep/1000		// Delay (10s/mm) to allow stable movement
			newportAC_currPos()		// Update position variables			
			break
	endswitch

	return 0
End

Function ButtonProc_6(ba) : ButtonControl
	// Increment HLXposition by HLXstep
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			NVAR HLXstep = root:gVariables:newPortActuators:HLXstep
			HLXmove(HLXstep)
			sleep/s HLXstep/1000		// Delay (10s/mm) to allow stable movement			
			newportAC_currPos()		// Update position variables			
			// click code here
			break
	endswitch

	return 0
End

Function ButtonProc_7(ba) : ButtonControl
	// Decrement HLXposition by HLXstep
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			NVAR HLXstep = root:gVariables:newPortActuators:HLXstep
			HLXmove(-HLXstep)
			sleep/s HLXstep/1000		// Delay (10s/mm) to allow stable movement			
			newportAC_currPos()		// Update position variables		
			// click code here
			break
	endswitch

	return 0
End


//=========================================================
// PZ actuator controls

Function ButtonProc_8(ba) : ButtonControl
	// PZ actuator startup
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			PZactuator_startUp()
			break
	endswitch

	return 0
End

Function ButtonProc_9(ba) : ButtonControl
	// PZ actuator shutdown
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			PZactuator_shutDown()
			break
	endswitch

	return 0
End

Function ButtonProc_10(ba) : ButtonControl
	// PZ actuator - go to starting positions (20,20,5)
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			 PZactuator_startingPos()
			break
	endswitch

	return 0
End

Function ButtonProc_11(ba) : ButtonControl
	// Update PZ actuator positions
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			PZactuator_currPos()
			break
	endswitch

	return 0
End

Function ButtonProc_12(ba) : ButtonControl
	// Increment PZ channel A by stepA and update posA variable
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			NVAR stepA = root:gVariables:PZactuators:stepA
			NVAR posA = root:gVariables:PZactuators:posA
			NVAR delay = root:gVariables:PZactuators:delay
			// movePI("A", posA+stepA)
			moveRelPI("A",stepA)
			sleep/s stepA/10+delay
			posA = str2num(cmdPI("pos? A"))
			break
	endswitch

	return 0
End

Function ButtonProc_13(ba) : ButtonControl
	// Decrement PZ channel A by stepA and update posA variable
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			NVAR stepA = root:gVariables:PZactuators:stepA
			NVAR posA = root:gVariables:PZactuators:posA
			NVAR delay = root:gVariables:PZactuators:delay
			// movePI("A", posA-stepA)
			moveRelPI("A",-stepA)
			sleep/s stepA/10+delay			
			posA = str2num(cmdPI("pos? A"))
			break
	endswitch

	return 0
End

Function ButtonProc_14(ba) : ButtonControl
	// Increment PZ channel B by stepB and update posB variable
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			NVAR stepB = root:gVariables:PZactuators:stepB
			NVAR posB = root:gVariables:PZactuators:posB
			NVAR delay = root:gVariables:PZactuators:delay
			//movePI("B", posB+stepB)
			moveRelPI("B",stepB)
			sleep/s stepB/10+delay				
			posB = str2num(cmdPI("pos? B"))
			// click code here
			break
	endswitch

	return 0
End

Function ButtonProc_15(ba) : ButtonControl
	// Decrement PZ channel B by stepB and update posB variable
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			NVAR stepB = root:gVariables:PZactuators:stepB
			NVAR posB = root:gVariables:PZactuators:posB
			NVAR delay = root:gVariables:PZactuators:delay
			//movePI("B", posB-stepB)
			moveRelPI("B",-stepB)
			sleep/s stepB/10+delay
			posB = str2num(cmdPI("pos? B"))
			// click code here
			break
	endswitch

	return 0
End

Function ButtonProc_16(ba) : ButtonControl
	// Increment PZ channel C by stepC and update posC variable
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			NVAR stepC = root:gVariables:PZactuators:stepC
			NVAR posC = root:gVariables:PZactuators:posC
			NVAR delay = root:gVariables:PZactuators:delay
			//movePI("C", posC+stepC)
			moveRelPI("C",stepC)
			sleep/s stepC/10+delay
			posC = str2num(cmdPI("pos? C"))			
			break
	endswitch

	return 0
End

Function ButtonProc_17(ba) : ButtonControl
	// Decrement PZ channel C by stepC and update posC variable
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			NVAR stepC = root:gVariables:PZactuators:stepC
			NVAR posC = root:gVariables:PZactuators:posC
			NVAR delay = root:gVariables:PZactuators:delay
			//movePI("C", posC-stepC)
			moveRelPI("C",-stepC)
			sleep/s stepC/10+delay
			posC = str2num(cmdPI("pos? C"))
			break
	endswitch

	return 0
End

Function ButtonProc_40(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
				// Query controller for velocities and update global variables
				PZactuator_velocityQuery()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_41(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
				// Query controller for velocities and update global variables
				PZactuator_velocitySet()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_42(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			PZactuator_dcoQuery()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_43(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			PZactuator_dcoSet()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//=========================================================
// Tip Alignment buttons

Function ButtonProc_18(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			// Run tip alignment scan
			tipAlign()
			break
	endswitch

	return 0
End

Function ButtonProc_19(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// Get centroid position from global variables and move to position 
			NVAR centB = root:gVariables:tipAlignment:centroidB
			NVAR centC = root:gVariables:tipAlignment:centroidC
			
			movePI("B", centB)
			movePI("C", centC)
			
			// Update position variables
			PZactuator_currPos()
		
			break
	endswitch

	return 0
End



//=========================================================
// Signal generator buttons

Function ButtonProc_20(ba) : ButtonControl
	// Set frequency generator frequency
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			NVAR freq = root:gVariables:HPsigGenerator:sigGenFrequency
			setFreqSigGen(freq)

			break
	endswitch

	return 0
End

Function ButtonProc_21(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			NVAR amplitude = root:gVariables:HPsigGenerator:sigGenAmplitude
			SetAmplitudePP(amplitude)	
			
			break
	endswitch

	return 0
End

Function ButtonProc_22(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			NVAR DCoffset = root:gVariables:HPsigGenerator:sigGenDC
			SetDCOffset(DCoffset)
			
			break
	endswitch

	return 0
End

Function ButtonProc_23(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			// Run scan
			sigResScan()
			
			// Update frequency global variable
			NVAR freq = root:gVariables:HPsigGenerator:sigGenFrequency 
			freq = str2num(cmdSig("FREQ?"))
			
			break
	endswitch

	return 0
End



//======================================================
// Function to do a tip-tip alignment scan

function tipAlign()

	// Scan is in "B" (up/down) and "C" (focus) channels
	
	NVAR gridStep = root:gVariables:tipAlignment:gridStep
	NVAR gridSize = root:gVariables:tipAlignment:gridSize
	
	// Get and store starting PZ position (return here at end)
	PZactuator_currPos()
	NVAR initB = root:gVariables:PZactuators:posB
	NVAR initC = root:gVariables:PZactuators:posC

	// Variables
	variable posB, posC			// Position variables
	variable qB = 0, qC = 0, qMax = gridSize/gridStep		// Loop counters
	variable/c data				// Lock-in output (complex)
	
	// Make new data folder to store data
	newScanFolder3()
	
	// Log scan parameters
	NVAR globalTemp =root:gVariables:tipAlignment:gridSize
	variable/g gridSize = globalTemp
	NVAR globalTemp =root:gVariables:tipAlignment:gridStep
	variable/g gridStep = globalTemp
	NVAR globalTemp = root:gVariables:HPsigGenerator:sigGenFrequency
	variable/g sigGenFrequency = globalTemp
	NVAR globalTemp = root:gVariables:HPsigGenerator:sigGenAmplitude
	variable/g sigGenAmplitude = globalTemp
	NVAR globalTemp = root:gVariables:HPsigGenerator:sigGenDC
	variable/g sigGenDC = globalTemp		
	NVAR globalTemp = root:gVariables:PZactuators:posA
	variable/g startA = globalTemp		
	NVAR globalTemp = root:gVariables:PZactuators:posB
	variable/g startB = globalTemp	
	NVAR globalTemp = root:gVariables:PZactuators:posC
	variable/g startC = globalTemp	
	
	string/g timeStamp = date() + " " + time()
	
	// Create dayLog wave if it doesn't exist
	

	
	// Create wave to hold results
	make/o/n=(qMax,qMax) tipAlignGridScan_X, tipAlignGridScan_Y, tipAlignGridScan_R, tipAlignGridScan_theta
	tipAlignGridScan_X = 0
	tipAlignGridScan_Y = 0
	tipAlignGridScan_R = 0
	tipAlignGridScan_theta = 0
	
	// Graphing results
	plotTipAlign(getDataFolder(1))
	
	// Set first grid point
	posB = initB - gridSize/2
	posC = initC - gridSize/2 
	
	setScale/P x, posB, gridStep, tipAlignGridScan_X, tipAlignGridScan_Y, tipAlignGridScan_R, tipAlignGridScan_theta
	setScale/P y, posC, gridStep, tipAlignGridScan_X, tipAlignGridScan_Y, tipAlignGridScan_R, tipAlignGridScan_theta
	
	// Move PZ to first grid point
	movePI("B", posB)
	movePI("C", posC)
	sleep/s 1
	
	// Autoset Lock-in phase and allow 1s settling time
	cmdSR830_1("APHS\r")
	sleep/s 1
	
	do
		do
			// Take measurement
			data = SR830_XY()
			tipAlignGridScan_X[qB][qC] = real(data)
			tipAlignGridScan_Y[qB][qC] = imag(data)
			tipAlignGridScan_R[qB][qC] = sqrt(tipAlignGridScan_X[qB][qC]^2+tipAlignGridScan_Y[qB][qC]^2)
			tipAlignGridScan_theta[qB][qC] = atan2(tipAlignGridScan_Y[qB][qC],tipAlignGridScan_X[qB][qC])
			doUpdate
			
			// Increment B position
			posB = posB + gridStep
			movePI("B",posB)
			sleep/s 0.5

			qB = qB+1
		while(qB<qMax)
		
		// Move B back to initial position and increment C position
		posB = initB - gridSize/2
		posC = posC + gridStep
		movePI("B",posB)
		movePI("C",posC)
		sleep/s 0.5
		
		// Recent B counter and increment C counter
		qB = 0
		qC = qC+1
	while(qC<qMax)
	
	// Return to initial position
	movePI("B",initB)
	movePI("C",initC)
	sleep/s 1
	
	// Fit all data
	fitAlignmentData()
	
	
	// Return to root directory
	setDataFolder root:
	
end


// Plot alignment scan data

function plotTipAlign(scanName)

	string scanName

	setDataFolder $scanName
	SVAR svanFolder = root:gVariables:tipAlignment:scanFolder
	svanFolder = scanName

	// Graphing results
	doWindow/K alignmentData
	NewPanel /W=(150,77,475,744)/N=alignmentData
	
	// Fit buttons
	Button button0,pos={260,48},size={50,50},proc=ButtonProc_52,title="Fit X"
	Button button0,fSize=14
	Button button1,pos={260,165},size={50,50},proc=ButtonProc_53,title="Fit Y",fSize=14
	Button button2,pos={260,274},size={50,50},proc=ButtonProc_54,title="FitR",fSize=14
	Button button3,pos={260,400},size={50,50},proc=ButtonProc_55,title="Fit \\F'Symbol'q",fSize=14
	Button button4,pos={242,559},size={60,50},proc=ButtonProc_56,title="Set\rCentroid"
	Button button4,fSize=14,fColor=(0,34816,52224)
	TitleBox title0,pos={27,515},size={210,21}
	TitleBox title0,variable= root:gVariables:tipAlignment:scanFolder
	ValDisplay valdisp0,pos={16,537},size={90,14},bodyWidth=75,title="z0"
	ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp0,value= #"root:gVariables:tipAlignment:z0"
	ValDisplay valdisp1,pos={15,555},size={91,14},bodyWidth=75,title="a0"
	ValDisplay valdisp1,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp1,value= #"root:gVariables:tipAlignment:a0"
	ValDisplay valdisp2,pos={16,574},size={90,14},bodyWidth=75,title="x0"
	ValDisplay valdisp2,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp2,value= #"root:gVariables:tipAlignment:x0"
	ValDisplay valdisp3,pos={16,593},size={90,14},bodyWidth=75,title="y0"
	ValDisplay valdisp3,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp3,value= #"root:gVariables:tipAlignment:y0"
	ValDisplay valdisp4,pos={9,612},size={97,14},bodyWidth=75,title="sigx"
	ValDisplay valdisp4,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp4,value= #"root:gVariables:tipAlignment:sigx"
	ValDisplay valdisp5,pos={9,631},size={97,14},bodyWidth=75,title="sigy"
	ValDisplay valdisp5,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp5,value= #"root:gVariables:tipAlignment:sigy"
	ValDisplay valdisp6,pos={9,648},size={97,14},bodyWidth=75,title="corr"
	ValDisplay valdisp6,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp6,value= #"root:gVariables:tipAlignment:corr"
	ValDisplay valdisp7,pos={119,537},size={108,14},bodyWidth=75,title="err_z0"
	ValDisplay valdisp7,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp7,value= #"root:gVariables:tipAlignment:err_z0"
	ValDisplay valdisp8,pos={118,555},size={109,14},bodyWidth=75,title="err_a0"
	ValDisplay valdisp8,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp8,value= #"root:gVariables:tipAlignment:err_a0"
	ValDisplay valdisp9,pos={119,574},size={108,14},bodyWidth=75,title="err_x0"
	ValDisplay valdisp9,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp9,value= #"root:gVariables:tipAlignment:err_x0"
	ValDisplay valdisp04,pos={119,593},size={108,14},bodyWidth=75,title="err_y0"
	ValDisplay valdisp04,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp04,value= #"root:gVariables:tipAlignment:err_y0"
	ValDisplay valdisp05,pos={112,612},size={115,14},bodyWidth=75,title="err_sigx"
	ValDisplay valdisp05,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp05,value= #"root:gVariables:tipAlignment:err_sigx"
	ValDisplay valdisp06,pos={112,631},size={115,14},bodyWidth=75,title="err_sigy"
	ValDisplay valdisp06,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp06,value= #"root:gVariables:tipAlignment:err_sigy"
	ValDisplay valdisp07,pos={112,648},size={115,14},bodyWidth=75,title="err_corr"
	ValDisplay valdisp07,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp07,value= #"root:gVariables:tipAlignment:err_corr"
	
	
	Display/W=(0,0,1,1)/HOST=#
	
	appendimage/L=L1/B=B1 tipAlignGridScan_X
	appendimage/L=L2/B=B2 tipAlignGridScan_Y
	appendimage/L=L3/B=B3 tipAlignGridScan_R
	appendimage/L=L4/B=B4 tipAlignGridScan_theta
	
	modifyGraph width=170.079,height=453.543	

	label L1 "X"
	ModifyGraph lblPos(L1)=40
	modifyGraph freePos(L1)=0
	modifyGraph mirror(L1)=1
	modifyGraph axisEnab(L1)={0.75,1}
	modifyGraph tick(L1)=2
	modifyGraph freePos(B1)={0.75,kwFraction} 
	modifyGraph tick(B1)=1,noLabel(B1)=2
	
	label L2 "Y"
	ModifyGraph lblPos(L2)=40
	modifyGraph freePos(L2)=0
	modifyGraph mirror(L2)=1
	modifyGraph axisEnab(L2)={0.5,0.75}
	modifyGraph tick(L2)=2
	modifyGraph freePos(B2)={0.5,kwFraction} 
	modifyGraph tick(B2)=1,noLabel(B2)=2
	
	label L3 "R"
	ModifyGraph lblPos(L3)=40
	modifyGraph freePos(L3)=0
	modifyGraph mirror(L3)=1
	modifyGraph axisEnab(L3)={0.25,0.5}
	modifyGraph tick(L3)=2
	modifyGraph freePos(B3)={0.25,kwFraction} 
	modifyGraph tick(B3)=1,noLabel(B3)=2
	
	label L4 "theta"
	ModifyGraph lblPos(L4)=40
	modifyGraph freePos(L4)=0
	modifyGraph mirror(L4)=1
	modifyGraph axisEnab(L4)={0,0.25}
	modifyGraph tick(L4)=2
	modifyGraph freePos(B4)={0.0,kwFraction} 	
	modifyGraph tick(B4)=2,mirror(B4)=1
	
	modifyGraph standoff=0
	modifyGraph fSize=12
	
	modifyImage tipAlignGridScan_X ctab= {*,*,Geo32,0}
	modifyImage tipAlignGridScan_Y ctab= {*,*,Geo32,0}
	modifyImage tipAlignGridScan_R ctab= {*,*,Geo32,0}
	modifyImage tipAlignGridScan_theta ctab= {*,*,Geo32,0}


	// Return to root directory
	//setDataFolder root:	

end

function fitAlignmentData()
	
	analyzeGridScan("tipAlignGridScan_X")			// Fit X-data
	wave W_coef, W_sigma
	duplicate W_coef, W_coef_X					// Store X-data best fit parameters
	duplicate W_sigma, W_sigma_X				// Store X-data error estimates
	analyzeGridScan("tipAlignGridScan_Y")			// Fit Y-data
	duplicate W_coef, W_coef_Y					// Store Y-data best fit parameters
	duplicate W_sigma, W_sigma_Y				// Store Y-data error estimates
	analyzeGridScan("tipAlignGridScan_R")			// Fit R-data
	duplicate W_coef, W_coef_R					// Store R-data best fit parameters
	duplicate W_sigma, W_sigma_R				// Store R-data error estimates
	analyzeGridScan("tipAlignGridScan_theta")		// Fit theta-data
	duplicate W_coef, W_coef_theta					// Store theta-data best fit parameters
	duplicate W_sigma, W_sigma_theta				// Store theta-data error estimates
	
end


//======================================================
// Function to do a resonance frequency scan of the tip-tip system
function sigResScan()

	NVAR freqStart = root:gVariables:HPsigGenerator:sigGenFreqStart
	NVAR freqStop = root:gVariables:HPsigGenerator:sigGenFreqStop
	NVAR freqStep = root:gVariables:HPsigGenerator:sigGenFreqStep
	
	variable freq = freqStart, q = 0
	
	// Make new data folder to store data
	newScanFolder2()
	
	make/c/o/n=0 sigResScanData
	make/o/n=0 frequency

	display sigResScanData vs frequency
	appendtograph/L=L2/B=B2 sigResScanData vs frequency
	
	label left "Theta (deg)"; label L2 "3w Current (pA)"; label bottom "Frequency (Hz)"; delayupdate
	modifygraph mirror=0,tick=2,standoff=0; delayupdate
	ModifyGraph mode=0,rgb(sigResScanData#1)=(0,15872,65280); delayupdate
	ModifyGraph cmplxMode(sigResScanData#1)=1, cmplxMode(sigResScanData)=2; delayupdate
	
	ModifyGraph axisEnab(left)={0,0.5},axisEnab(L2)={0.05,1},freePos(L2)=0; delayupdate
	ModifyGraph axisEnab(L2)={0.5,1}; delayupdate
	ModifyGraph axisEnab(left)={0,0.45},axisEnab(L2)={0.55,1}; delayupdate
	ModifyGraph freePos(B2)={0.55,kwFraction}, lblPos(L2)=80; delayupdate
	ModifyGraph width=283.465,height=283.465; delayUpdate
	ModifyGraph muloffset(sigResScanData#1)={0,10000}
	
	TextBox/C/N=text0/E/A=MT GetDataFolder(1)
	
	// Autoset Lock-in phase and allow 1s settling time
	setFreqSigGen(freq)
	sleep/s 1
	cmdSR830_1("APHS\r")
	sleep/s 1
		
	do
		
		setFreqSigGen(freq)
		Sleep/S 0.5				// Delay to allow SR_830 to settle
		redimension/n=(q+1) sigResScanData
		redimension/n=(q+1) frequency

		sigResScanData[q] = SR830_Rtheta()		
		frequency[q] = freq
		
		doUpdate
		
		q=q+1
		freq = freq + freqStep
	while(freq<=freqStop)
	
	// Return to root directory
	setDataFolder root:

end

function newScanFolder2()

	// Create new folder to store tip resonance frequency data
	// Creates a unique data folder for a new scan
	string dirPath
	// Get current date
	string currDate = date()
	string day, monthYear
	
	day = "day"+currDate[0,1]
	monthYear = currDate[3,5]+currDate[7,10]

	dirPath = "root:data:"
	if(!dataFolderExists(dirPath))
		newDataFolder $dirPath
	endif

	dirPath = "root:data:"+monthYear
	if(!dataFolderExists(dirPath))
		newDataFolder $dirPath
	endif
	
	dirPath = "root:data:"+monthYear+":"+day
	if(!dataFolderExists(dirPath))
		newDataFolder $dirPath
	endif	

	dirPath = "root:data:"+monthYear+":"+day+":resFreq"
	if(!dataFolderExists(dirPath))
		newDataFolder $dirPath
	endif	

	// Find unique scan number
	variable q = 1
	do
		dirPath = "root:data:"+monthYear+":"+day+":resFreq:"+"scan_"+num2str(q)
		if(!dataFolderExists(dirPath))
			newDataFolder/s $dirPath
			break
		endif		
		q = q+1
	while(1)
	
end
	
function newScanFolder3()

	// Create new folder to store tip alignment scan data
	// Creates a unique data folder for a new scan
	string dirPath
	// Get current date
	string currDate = date()
	string day, monthYear
	
	day = "day"+currDate[0,1]
	monthYear = currDate[3,5]+currDate[7,10]

	dirPath = "root:data:"
	if(!dataFolderExists(dirPath))
		newDataFolder $dirPath
	endif

	dirPath = "root:data:"+monthYear
	if(!dataFolderExists(dirPath))
		newDataFolder $dirPath
	endif
	
	dirPath = "root:data:"+monthYear+":"+day
	if(!dataFolderExists(dirPath))
		newDataFolder $dirPath
	endif	

	dirPath = "root:data:"+monthYear+":"+day+":tipAlign"
	if(!dataFolderExists(dirPath))
		newDataFolder $dirPath
	endif	

	// Find unique scan number
	variable q = 1
	do
		dirPath = "root:data:"+monthYear+":"+day+":tipAlign:"+"scan_"+num2str(q)
		if(!dataFolderExists(dirPath))
			newDataFolder/s $dirPath
			break
		endif		
		q = q+1
	while(1)
	
end


// =========================================================
// =========================================================
// Tip-alignment grid scan analysis functions
// MH
// May 12, 2011

function gridScanFit(wName)

	// function to tranform xy data into R data	
	// wName provides the name of the wave to be transformed
	// Creates a new wave "wName_Rdata" containing the new data

	string wName
	
	string wName2 = wName + "Im", wName3 = wName + "_Rdata"	
	wave wX = $wName, wY = $wName
	
	duplicate/o wX, $wName3	
	wave wR = $wName3
	
	variable q1 = 0, q2 = 0
	
	do
		do
			wR[q1][q2] = sqrt(wX[q1][q2]^2 + wY[q1][q2]^2)
			q1 = q1+1
		while(q1<dimSize(wR,1))
	
		q1 = 0
		q2 = q2+1
	while(q2<dimSize(wR,0))
	
	 plotGridScan(wName3)
	 analyzeGridScan(wName3)
	
end

function plotGridScan(wName)

	string wName
	wave w = $wName

	// Plots the specified 2D wave
	
	// Create image plot of wave
	Display/n=$wName
		
	AppendImage w
	
	ModifyImage $wName ctab= {*,*,Geo32,0}	
	// modifyGraph width=360, height=360

end


function analyzeGridScan(wName)
		
	string wName
	wave w = $wName

	//---------------------------------------------------------------------------------------------------------
	// Make semi-intelligent guesses for initial parameters

	variable z0, a0, x0, sigx, y0, sigy, corr						// Fit parameters
	
	// Background: Take the average of the grid's four corner points
	variable N, M, J, K
	N = dimSize(w,0)
	M = dimSize(w,1)
	z0 =  0.25*(w[0][0]+w[N-1][0]+w[0][M-1]+w[N-1][M-1])
		
	// Amplitude: Difference between z0 and the grid centre value
	imagestats w
	//a0 = z0-V_min
	a0 = w[N/2][M/2] - z0
	wavestats/Q w
	
	// Centre-points: 
	// The location of the minimum grid value
	//x0 = V_minRowLoc
	//y0 = V_minColLoc
	
	// Centre points: grid centre
	x0 = DimOffset(w,0)+N/2*DimDelta(w,0)
	y0 = DimOffset(w,1)+M/2*DimDelta(w,1)
	
	// Peak width: Set to 250 nm, a typical starting point
	sigx = 0.25
	sigy = 0.25
	
	// xy correlation: Set to 0
	corr = 0
	
	// Constraints on fit
	// Note: {K0,K1,K2,K3,K4,K5,K6} = {z0,a0,x0,y0,sigx,sigy,corr}
	make/o/t/n=0 constraintWave
	variable q = 0		// Constraint counter
	
	// Constraint -- x0 and y0 must lie within the scan area
	redimension/n=(q+2) constraintWave
	constraintWave[q] = "K2 > " + num2str(dimOffset(w,0)) ; q = q+1
	constraintWave[q] = "K2 < " + num2str(dimOffset(w,0)+N*dimDelta(w,0)); q = q+1
	redimension/n=(q+2) constraintWave
	constraintWave[q] = "K3 > " + num2str(dimOffset(w,1)); q = q+1
	constraintWave[q] = "K3 < " + num2str(dimOffset(w,1)+N*dimDelta(w,1)); q = q+1
	
	// Constraint -- sigx and sigy must be between 50nm and 1um
	redimension/n=(q+2) constraintWave
	constraintWave[q] = "K4 > 0.05"; q = q+1
	constraintWave[q] = "K4 < 1"; q = q+1
	redimension/n=(q+2) constraintWave
	constraintWave[q] = "K5 > 0.05"; q = q+1
	constraintWave[q] = "K5 < 1"; q = q+1
	
	// Constraint -- corr must be between -1 and 1
	redimension/n=(q+2) constraintWave
	constraintWave[q] = "K6 > -1"; q = q+1
	constraintWave[q] = "K6 < 1"; q = q+1
	
	
	
	//---------------------------------------------------------------------------------------------------------	
	// Fit function to data
	
	Make/D/N=7/O W_coef
	W_coef[0] = {z0,a0,x0,y0,sigx,sigy,corr}
	//FuncFitMD/NTHR=0/Q inverted2DGaussianElliptic W_coef  w /D
	FuncFitMD/NTHR=0/Q Gauss2Delliptic W_coef  w /D/C=constraintWave
	
	string fitName = "fit_" + wName
	ModifyContour $fitName labels=0
	ModifyContour $fitName ctabLines={*,*,Geo32,0}
	
	wave W_sigma

	// Set global variables to hold fitted parameters
	setBestFitParameters(W_coef[0],W_coef[1],W_coef[2],W_coef[3],W_coef[4],W_coef[5],W_coef[6])	
	setBestFitErrors(W_sigma[0],W_sigma[1],W_sigma[2],W_sigma[3],W_sigma[4],W_sigma[5],W_sigma[6])	

end

function 	setBestFitParameters(z0,a0,x0,y0,sigx,sigy,corr)			
	variable z0,a0,x0,y0,sigx,sigy,corr
	
	NVAR gTemp = root:gVariables:tipAlignment:z0
	gTemp = z0
	NVAR gTemp = root:gVariables:tipAlignment:a0
	gTemp = a0
	NVAR gTemp = root:gVariables:tipAlignment:x0
	gTemp = x0
	NVAR gTemp = root:gVariables:tipAlignment:y0
	gTemp = y0
	NVAR gTemp = root:gVariables:tipAlignment:sigx
	gTemp = sigx
	NVAR gTemp = root:gVariables:tipAlignment:sigy
	gTemp = sigy
	NVAR gTemp = root:gVariables:tipAlignment:corr
	gTemp = corr
end

function 	setBestFitErrors(err_z0,err_a0,err_x0,err_y0,err_sigx,err_sigy,err_corr)			
	variable err_z0,err_a0,err_x0,err_y0,err_sigx,err_sigy,err_corr
	
	NVAR gTemp = root:gVariables:tipAlignment:err_z0
	gTemp = err_z0
	NVAR gTemp = root:gVariables:tipAlignment:err_a0
	gTemp = err_a0
	NVAR gTemp = root:gVariables:tipAlignment:err_x0
	gTemp = err_x0
	NVAR gTemp = root:gVariables:tipAlignment:err_y0
	gTemp = err_y0
	NVAR gTemp = root:gVariables:tipAlignment:err_sigx
	gTemp = err_sigx
	NVAR gTemp = root:gVariables:tipAlignment:err_sigy
	gTemp = err_sigy
	NVAR gTemp = root:gVariables:tipAlignment:err_corr
	gTemp = err_corr

end


Function Gauss2Delliptic(w,x,y) : FitFunc
	Wave w
	Variable x
	Variable y

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x,y) = z0+A0*exp(-1/2/(1-corr^2)*((x-x0)^2/sigx^2+(y-y0)^2/sigy^2)-2*corr*(x-x0)*(y-y0)/sigx/sigy)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 2
	//CurveFitDialog/ x
	//CurveFitDialog/ y
	//CurveFitDialog/ Coefficients 7
	//CurveFitDialog/ w[0] = z0
	//CurveFitDialog/ w[1] = A0
	//CurveFitDialog/ w[2] = x0
	//CurveFitDialog/ w[3] = y0
	//CurveFitDialog/ w[4] = sigx
	//CurveFitDialog/ w[5] = sigy
	//CurveFitDialog/ w[6] = corr

	return w[0]+w[1]*exp(-1/2/(1-w[6]^2)*((x-w[2])^2/w[4]^2+(y-w[3])^2/w[5]^2)-2*w[6]*(x-w[2])*(y-w[3])/w[4]/w[5])
End


Function inverted2DGaussianElliptic(w,x,y) : FitFunc
	Wave w
	Variable x
	Variable y

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x,y) = z0+A0*exp(-1/2/(1-p^2)*((x-x0)^2/sigx^2+(y-y0)^2/sigy^2)-2*p*(x-x0)*(y-y0)/sigx/sigy)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 2
	//CurveFitDialog/ x
	//CurveFitDialog/ y
	//CurveFitDialog/ Coefficients 7
	//CurveFitDialog/ w[0] = z0
	//CurveFitDialog/ w[1] = A0
	//CurveFitDialog/ w[2] = x0
	//CurveFitDialog/ w[3] = y0
	//CurveFitDialog/ w[4] = sigx
	//CurveFitDialog/ w[5] = sigy
	//CurveFitDialog/ w[6] = p

	return w[0]+w[1]*exp(-1/2/(1-w[6]^2)*((x-w[2])^2/w[4]^2+(y-w[3])^2/w[5]^2)-2*w[6]*(x-w[2])*(y-w[3])/w[4]/w[5])
End

// =========================================================
// =========================================================


Function ButtonProc_52(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			SVAR scanFolder = root:gVariables:tipAlignment:scanFolder	// Get folder with scan data
			setDataFolder $scanFolder								// Swicth to folder
			analyzeGridScan("tipAlignGridScan_X")
			setDataFolder root:	
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_53(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			SVAR scanFolder = root:gVariables:tipAlignment:scanFolder	// Get folder with scan data
			setDataFolder $scanFolder								// Swicth to folder
			analyzeGridScan("tipAlignGridScan_Y")
			setDataFolder root:	
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_54(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			SVAR scanFolder = root:gVariables:tipAlignment:scanFolder	// Get folder with scan data
			setDataFolder $scanFolder								// Swicth to folder
			analyzeGridScan("tipAlignGridScan_R")
			setDataFolder root:	
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_55(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			SVAR scanFolder = root:gVariables:tipAlignment:scanFolder	// Get folder with scan data
			setDataFolder $scanFolder								// Swicth to folder
			analyzeGridScan("tipAlignGridScan_theta")
			setDataFolder root:	
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function ButtonProc_56(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			// Update centroid values with fit parameters
			NVAR centroidB = root:gVariables:tipAlignment:centroidB
			NVAR centroidC = root:gVariables:tipAlignment:centroidC
			
			NVAR x0 = root:gVariables:tipAlignment:x0
			NVAR y0 = root:gVariables:tipAlignment:y0
			
			centroidB = x0
			centroidC = y0
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



function generateTipAlignReport(folderName)

	string folderName							// "eg. root:Nov2012:day14:tipAlign"
	
	if(!dataFolderExists(folderName))			// Check folder exits
		print "Folder does not exist"
		return 0
	endif

	if(!stringmatch(folderName,"*tipAlign"))		// Make sure data folder is a tipAlign folder
		print "Folder is not a tipAlign folder"
		return 0
	endif
		
	setDataFolder $folderName				// Switch to folder

	make/o/n=(1,2)/T dayReportStr				// Make dayReportStr to hold string data	
	make/o/n=(1,64) dayReport				// Make dayReport wave to hold variable data
	generateDayReportKey() 					// Create text wave of parameter names

	variable q
	string fName								// String to hold scan folder name
	do										// Loop through scan folders
		fName = getIndexedObjName("",4,q)	// Get scan folder name
		
		setDataFolder $fName					// Switch to scan folder
		
		// Log string data
		string/g timeStamp
		
		dayReportStr[q][0] = folderName+":"+fName
		dayReportStr[q][1] = timeStamp
		
		// Log variable data
		variable/g sigGenFrequency
		variable/g sigGenAmplitude		
		variable/g sigGenDC
		variable/g startA
		variable/g startB
		variable/g startC
		variable/g gridSize
		variable/g gridStep
		wave wX = W_coef_X
		wave wX_err = W_sigma_X
		wave wY = W_coef_Y
		wave wY_err = W_sigma_Y
		wave wR = W_coef_R
		wave wR_err = W_sigma_R
		wave wtheta = W_coef_theta
		wave wtheta_err = W_sigma_theta
		
		dayReport[q][0] = sigGenFrequency		
		dayReport[q][1] = sigGenAmplitude		
		dayReport[q][2] = sigGenDC
		dayReport[q][3] = startA
		dayReport[q][4] = startB
		dayReport[q][5] = startC
		dayReport[q][6] = gridSize
		dayReport[q][7] = gridStep
		
		dayReport[q][8] = wX[0]
		dayReport[q][9] = wX[1]
		dayReport[q][10] = wX[2]
		dayReport[q][11] = wX[3]
		dayReport[q][12] = wX[4]
		dayReport[q][13] = wX[5]
		dayReport[q][14] = wX[6]

		dayReport[q][15] = wX_err[0]
		dayReport[q][16] = wX_err[1]
		dayReport[q][17] = wX_err[2]
		dayReport[q][18] = wX_err[3]
		dayReport[q][19] = wX_err[4]
		dayReport[q][20] = wX_err[5]
		dayReport[q][21] = wX_err[6]

		dayReport[q][22] = wY[0]
		dayReport[q][23] = wY[1]
		dayReport[q][24] = wY[2]
		dayReport[q][25] = wY[3]
		dayReport[q][26] = wY[4]
		dayReport[q][27] = wY[5]
		dayReport[q][28] = wY[6]
		
		dayReport[q][29] = wY_err[0]
		dayReport[q][30] = wY_err[1]
		dayReport[q][31] = wY_err[2]
		dayReport[q][32] = wY_err[3]
		dayReport[q][33] = wY_err[4]
		dayReport[q][34] = wY_err[5]
		dayReport[q][35] = wY_err[6]
		
		dayReport[q][36] = wR[0]
		dayReport[q][37] = wR[1]
		dayReport[q][38] = wR[2]
		dayReport[q][39] = wR[3]
		dayReport[q][40] = wR[4]
		dayReport[q][41] = wR[5]
		dayReport[q][42] = wR[6]

		dayReport[q][43] = wR_err[0]
		dayReport[q][44] = wR_err[1]
		dayReport[q][45] = wR_err[2]
		dayReport[q][46] = wR_err[3]
		dayReport[q][47] = wR_err[4]
		dayReport[q][48] = wR_err[5]
		dayReport[q][49] = wR_err[6]
		
		dayReport[q][50] = wtheta[0]
		dayReport[q][51] = wtheta[1]
		dayReport[q][52] = wtheta[2]
		dayReport[q][53] = wtheta[3]
		dayReport[q][54] = wtheta[4]
		dayReport[q][55] = wtheta[5]
		dayReport[q][56] = wtheta[6]
		
		dayReport[q][57] = wtheta_err[0]
		dayReport[q][58] = wtheta_err[1]
		dayReport[q][59] = wtheta_err[2]
		dayReport[q][60] = wtheta_err[3]
		dayReport[q][61] = wtheta_err[4]
		dayReport[q][62] = wtheta_err[5]
		dayReport[q][63] = wtheta_err[6]


		setDataFolder $folderName			// Switch to tipAlign folder
		
		q = q+1
		if(q>=countobjects("",4))
			break
		endif
		
		redimension/n=(q+1,64) dayReport		// Increase size of wave
		redimension/n=(q+1,2) dayReportStr	// Increase size of wave
		
	while(1)	// Exit via break
	
	// Append data to the dayReport wave

	
	setDataFolder root:					// Return to root folder


end

function generateDayReportKey() 					// Creates a text wave of parameter names

	make/T/o/n=(1,64) dayReportKey				
	
		dayReportKey[0][0] = "sigGenFrequency"
		dayReportKey[0][1] = "sigGenAmplitude"
		dayReportKey[0][2] = "sigGenDC"
		dayReportKey[0][3] = "startA"
		dayReportKey[0][4] = "startB"
		dayReportKey[0][5] = "startC"
		dayReportKey[0][6] = "gridSize"
		dayReportKey[0][7] = "gridStep"
	
		dayReportKey[0][8] = "X_z0"
		dayReportKey[0][9] = "X_a0"
		dayReportKey[0][10] = "X_x0"
		dayReportKey[0][11] = "X_y0"
		dayReportKey[0][12] = "X_sigx"
		dayReportKey[0][13] = "X_sigy"
		dayReportKey[0][14] = "X_corr"

		dayReportKey[0][15] = "X_z0_err"
		dayReportKey[0][16] = "X_a0_err"
		dayReportKey[0][17] = "X_x0_err"
		dayReportKey[0][18] = "X_y0_err"
		dayReportKey[0][19] = "X_sigx_err"
		dayReportKey[0][20] = "X_sigy_err"
		dayReportKey[0][21] = "X_corr_err"

		dayReportKey[0][22] = "Y_z0"
		dayReportKey[0][23] = "Y_a0"
		dayReportKey[0][24] = "Y_x0"
		dayReportKey[0][25] = "Y_y0"
		dayReportKey[0][26] = "Y_sigx"
		dayReportKey[0][27] = "Y_sigy"
		dayReportKey[0][28] = "Y_corr"
		
		dayReportKey[0][29] = "Y_z0_err"
		dayReportKey[0][30] = "Y_a0_err"
		dayReportKey[0][31] = "Y_x0_err"
		dayReportKey[0][32] = "Y_y0_err"
		dayReportKey[0][33] = "Y_sigx_err"
		dayReportKey[0][34] = "Y_sigy_err"
		dayReportKey[0][35] = "Y_corr_err"
		
		dayReportKey[0][36] = "R_z0"
		dayReportKey[0][37] = "R_a0"
		dayReportKey[0][38] = "R_x0"
		dayReportKey[0][39] = "R_y0"
		dayReportKey[0][40] = "R_sigx"
		dayReportKey[0][41] = "R_sigy"
		dayReportKey[0][42] = "R_corr"

		dayReportKey[0][43] = "R_z0_err"
		dayReportKey[0][44] = "R_a0_err"
		dayReportKey[0][45] = "R_x0_err"
		dayReportKey[0][46] = "R_y0_err"
		dayReportKey[0][47] = "R_sigx_err"
		dayReportKey[0][48] = "R_sigy_err"
		dayReportKey[0][49] = "R_corr_err"

		dayReportKey[0][50] = "theta_z0"
		dayReportKey[0][51] = "theta_a0"
		dayReportKey[0][52] = "theta_x0"
		dayReportKey[0][53] = "theta_y0"
		dayReportKey[0][54] = "theta_sigx"
		dayReportKey[0][55] = "theta_sigy"
		dayReportKey[0][56] = "theta_corr"
		
		dayReportKey[0][57] = "theta_z0_err"
		dayReportKey[0][58] = "theta_a0_err"
		dayReportKey[0][59] = "theta_x0_err"
		dayReportKey[0][60] = "theta_y0_err"
		dayReportKey[0][61] = "theta_sigx_err"
		dayReportKey[0][62] = "theta_sigy_err"
		dayReportKey[0][63] = "theta_corr_err"
	
end