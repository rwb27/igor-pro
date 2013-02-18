#pragma ModuleName = tip_control
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "data_handling"
#include "pi_pi733_3cd_stage"

function starting_pos()
	pi_stage#move("a", 20)
	pi_stage#move("b", 20)
	pi_stage#move("c", 5)
end

// Panel //

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