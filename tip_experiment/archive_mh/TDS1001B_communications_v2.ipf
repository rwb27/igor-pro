#pragma rtGlobals=1		// Use modern global access method.

// 12/09/2012

function openOscComms()
	
	// Access global variables
	SVAR resourceName = root:gVariables:tekOscilloscope:resourceName
	NVAR sessionID = root:gVariables:tekOscilloscope:sessionID
	NVAR instrID = root:gVariables:tekOscilloscope:instrID
	
	// Check if comms are already open
	if(!(sessionID==-1 || instrID == -1))
		print "Comms already open!"
		return 0
	endif
	
	variable session = sessionID, instr = instrID			// Make local copies of global variables
	variable status=0, retCnt
	
	// Open communication
	status = viOpenDefaultRM(session)
	status = viOpen(session, resourceName, 0, 0, instr)
	
	sessionID = session								// Overwrite global variables with updated local values
	instrID = instr
	
	oscStartUp()

end

function closeOscComms()

	// Access global variables
	SVAR resourceName = root:gVariables:tekOscilloscope:resourceName
	NVAR sessionID = root:gVariables:tekOscilloscope:sessionID
	NVAR instrID = root:gVariables:tekOscilloscope:instrID
	
	// Check if comms are already closed
	if(sessionID==-1 || instrID == -1)
		print "Comms already closed!"
		return 0
	endif	
	
	variable session = sessionID, instr = instrID			// Make local copies of global variables
	variable status=0
	
	// Close session
	status = viClose(session)
	
	sessionID = -1									// Set global variables to -1
	instrID = -1

end

function oscStartUp()
	// Series of commands to initialize oscilloscope
	NVAR N = root:gVariables:tekOscilloscope:numberOfPoints
	oscCmd("DAT:SOU CH1")
	//oscCmd("CH1:POS 0")
	oscCmd("DAT:STAR 1")
	oscCmd("DAT:STOP " + num2str(N))
	oscCmd("DAT:WID 2")
	oscCmd("DAT:ENC RIBINARY")
	oscCmd("DAT:SOU CH2")
	//oscCmd("CH2:POS 0")
	oscCmd("DAT:STAR 1")
	oscCmd("DAT:STOP " + num2str(N))
	oscCmd("DAT:WID 2")
	oscCmd("DAT:ENC RIBINARY")
	oscCmd("HEAD OFF")

	make/o/n=(N) root:gVariables:tekOscilloscope:dataWave1, root:gVariables:tekOscilloscope:dataWave2
	make/o/n=(N+3) root:gVariables:tekOscilloscope:dataWave

	oscConversionParameters()

end

function oscConversionParameters()

	NVAR Yzero1 = root:gVariables:tekOscilloscope:Yzero1
	NVAR Ymul1 = root:gVariables:tekOscilloscope:Ymul1
	NVAR Yof1 = root:gVariables:tekOscilloscope:Yof1
	NVAR Yzero2 = root:gVariables:tekOscilloscope:Yzero2		
	NVAR Ymul2 = root:gVariables:tekOscilloscope:Ymul2
	NVAR Yof2 = root:gVariables:tekOscilloscope:Yof2
	NVAR Xin = root:gVariables:tekOscilloscope:Xin
	NVAR Xzero = root:gVariables:tekOscilloscope:Xzero
	
	oscCmd("DAT:SOU CH1")
	Yzero1 = str2num(oscCmd("WFMP:YZE?"))
	Ymul1 = str2num(oscCmd("WFMP:YMUL?"))
	Yof1 = str2num(oscCmd("WFMP:YOF?"))
	oscCmd("DAT:SOU CH2")
	Yzero2 = str2num(oscCmd("WFMP:YZE?"))
	Ymul2 = str2num(oscCmd("WFMP:YMUL?"))
	Yof2 = str2num(oscCmd("WFMP:YOF?"))
	Xin = str2num(oscCmd("WFMP:XIN?"))
	Xzero = str2num(oscCmd("WFMP:XZE?"))
	
	wave w1 = root:gVariables:tekOscilloscope:dataWave1
	wave w2 = root:gVariables:tekOscilloscope:dataWave2
	setScale/P x, Xzero, Xin, w1
	setScale/P x, Xzero, Xin, w2
	
end

function oscMean(channel)
	// Returns the mean of the specified channel
	variable channel
	variable waveMean
	
	oscCmd("MEASU:IMM:SOU CH"+num2str(channel))				// Set Channel  
	oscCmd("MEASU:IMM:TYP MEAN")							// Set measurement type
	waveMean = str2num(oscCmd("MEASU:IMM:VAL?"))				// Get mean
	
	return waveMean
end

function oscGetWave(channel, wName)
	// Get oscilloscope waveform from specified channel and store in specified wave
	variable channel
	string wName

	// Get conversion parameters
	if(channel == 1)
		NVAR Yzero = root:gVariables:tekOscilloscope:Yzero1
		NVAR Ymul = root:gVariables:tekOscilloscope:Ymul1
		NVAR Yof = root:gVariables:tekOscilloscope:Yof1
	elseif(channel == 2)
		NVAR Yzero = root:gVariables:tekOscilloscope:Yzero2		
		NVAR Ymul = root:gVariables:tekOscilloscope:Ymul2
		NVAR Yof = root:gVariables:tekOscilloscope:Yof2
	endif
	
	NVAR Xin = root:gVariables:tekOscilloscope:Xin
	NVAR Xzero = root:gVariables:tekOscilloscope:Xzero

	oscCmd("*OPC?")
	oscCmd("DAT:SOU CH"+num2str(channel))
	oscCmd("curve?")
	wave w = root:gVariables:tekOscilloscope:dataWave
	duplicate/o/r=[3,2502] w,$wName
	wave w1 = $wName
	w1 = ((w1 - Yof)*Ymul)+Yzero
	setScale/P x, Xzero, Xin, w1
	variable test = mean(w1)
end

function oscAdjustOffset(channel, waveMean)
	// function to adjust the vertical offset of the specified channel to centre the wave about its mean value (waveMean)
	variable channel, waveMean
	
	// Get volts/div and Yoffset for appropriate channel
	if(channel == 1)
		NVAR voltAxis = root:gVariables:tekOscilloscope:voltAxis1
		NVAR Yof = root:gVariables:tekOscilloscope:Yof1
	elseif(channel == 2)
		NVAR voltAxis = root:gVariables:tekOscilloscope:voltAxis2
		NVAR Yof = root:gVariables:tekOscilloscope:Yof2
	endif
	
	oscCmd("CH"+num2str(channel)+":POS "+num2str(-waveMean/voltAxis))		// Change offset
	
	// Update Yoffset parameter
	oscCmd("DAT:SOU CH"+num2str(channel))
	oscCmd("*OPC?")
	Yof = str2num(oscCmd("WFMP:YOF?"))
end

function oscAutoAdjustOffset(channel)
	// Measures waveform from the specified channel then centres it on the screen
	variable channel
	oscGetWave(channel, "root:autoAdjustTemp")
	wave w = root:autoAdjustTemp
	oscAdjustOffset(1,mean(w))
end


//=======================Send a command to the OSC (TDS1001B)===============================================
function/S oscCmd(ss)											//Sends a command to TEK oscilloscope
	
	string ss
	
	// Access global variables
	NVAR sessionID = root:gVariables:tekOscilloscope:sessionID
	NVAR instrID = root:gVariables:tekOscilloscope:instrID	
	
	// Check if comms are closed
	if(sessionID==-1 || instrID == -1)
		print "Comms are closed!"
		abort
	endif	
	
	variable session = sessionID, instr = instrID			// Make local copies of global variables	
	
	string command = ss+"\n"
	variable cnt = strlen(command)
	variable retCnt											
	
	viWrite(instr, command, cnt , retCnt)
	
	if (stringmatch(command, "curve?\n") == 1)							//add in commands that return data to be read to waves here
		wave w = root:gVariables:tekOscilloscope:dataWave
		w = 0
//		VISAReadWave/N=5/T=",\n" viTEK, Curve1						//read back from instrument directly to a wave file (used for ASCII format data)
		VISAReadBinaryWave/TYPE=(0x10) instr, w						//read back from instrument directly to a wave file (used for 16bit binary format data)
	elseif (strsearch(command,"?",0)>0)								//all queries (commands for which something is read back) end in a question mark.  These do not need to be read to a wave.
		String buffer = ""												//clears buffer ready for next command
		VISARead/N=500/T="\n" instr, buffer							//read back reply from instrument.      	
		return(buffer)		
  	endif	

end








Window TDS1001B_panel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(143,241,787,715)
	ShowTools/A
	SetDrawLayer UserBack
	SetDrawEnv fsize= 16,fstyle= 1
	DrawText 5,25,"TDS1001B Oscilloscope"
	SetVariable setvar0,pos={10,32},size={397,20},bodyWidth=270,title="VISA resource name"
	SetVariable setvar0,fSize=14,value= root:gVariables:tekOscilloscope:resourceName
	ValDisplay valdisp0,pos={73,55},size={174,17},bodyWidth=110,title="sessionID"
	ValDisplay valdisp0,fSize=14,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp0,value= #"root:gVariables:tekOscilloscope:sessionID"
	ValDisplay valdisp1,pos={96,78},size={151,17},bodyWidth=110,title="instrID"
	ValDisplay valdisp1,fSize=14,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp1,value= #"root:gVariables:tekOscilloscope:instrID"
	Button button0,pos={254,54},size={75,40},proc=ButtonProc_44,title="Open\rComms"
	Button button0,fSize=14,fColor=(0,39168,0)
	Button button1,pos={332,54},size={75,40},proc=ButtonProc_45,title="Close\rComms"
	Button button1,fSize=14,fColor=(65280,0,0)
	SetVariable setvar6,pos={19,98},size={111,20},bodyWidth=50,title="Ch1 V/div"
	SetVariable setvar6,fSize=14
	SetVariable setvar6,limits={-inf,inf,0},value= root:gVariables:tekOscilloscope:voltAxis1
	SetVariable setvar7,pos={198,97},size={153,20},bodyWidth=50,title="Time Axis (s/div)"
	SetVariable setvar7,fSize=14
	SetVariable setvar7,limits={-inf,inf,0},value= root:gVariables:tekOscilloscope:timeAxis
	SetVariable setvar8,pos={204,124},size={147,20},bodyWidth=50,title="Numpnts/Wave"
	SetVariable setvar8,fSize=14
	SetVariable setvar8,limits={-inf,inf,0},value= root:gVariables:tekOscilloscope:numberOfPoints
	Button button8,pos={356,124},size={50,20},proc=ButtonProc_49,title="Set"
	Button button8,fSize=14
	Button button6,pos={356,97},size={50,20},proc=ButtonProc_48,title="Set",fSize=14
	Button button4,pos={135,98},size={50,20},proc=ButtonProc_46,title="Set",fSize=14
	Button button5,pos={423,32},size={120,30},proc=ButtonProc_50,title="Read Ch1"
	Button button5,fSize=14,fColor=(0,52224,52224)
	Button button7,pos={423,66},size={120,30},proc=ButtonProc_51,title="Read Ch2"
	Button button7,fSize=14,fColor=(0,34816,52224)
	SetVariable setvar9,pos={19,124},size={111,20},bodyWidth=50,title="Ch2 V/div"
	SetVariable setvar9,fSize=14
	SetVariable setvar9,limits={-inf,inf,0},value= root:gVariables:tekOscilloscope:voltAxis2
	Button button2,pos={135,124},size={50,20},proc=ButtonProc_47,title="Set"
	Button button2,fSize=14
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:gVariables:tekOscilloscope:
	Display/W=(19,144,622,441)/HOST=#  dataWave1
	AppendToGraph/R dataWave2
	SetDataFolder fldrSav0
	ModifyGraph marker=19
	ModifyGraph rgb(dataWave2)=(0,12800,52224)
	ModifyGraph useMrkStrokeRGB=1
	ModifyGraph tick(left)=2,tick(bottom)=2
	ModifyGraph mirror(bottom)=1
	ModifyGraph nticks(left)=4,nticks(bottom)=3
	ModifyGraph fSize=16
	ModifyGraph standoff(left)=0,standoff(bottom)=0
	Label left "Ch1 (V)"
	Label bottom "Time (s)"
	Label right "Ch2 (V)"
	Legend/C/N=text0/J/F=0/A=MC/X=48.37/Y=-66.67 "\\Z16\\s(dataWave1) Ch1 \\s(dataWave2) Ch2"
	RenameWindow #,G0
	SetActiveSubwindow ##
EndMacro



Function ButtonProc_44(ba) : ButtonControl
	// Button to open oscilloscope communications
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			openOscComms()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_45(ba) : ButtonControl
	// Button to close oscilloscope communications
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			closeOscComms()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_46(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// Set oscilloscope vert scale
			NVAR voltAxis1 = root:gVariables:tekOscilloscope:voltAxis1
			oscCmd("CH1:SCA " + num2str(voltAxis1))
			oscConversionParameters()
			// click code here
			break
	endswitch

	return 0
End

Function ButtonProc_47(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// Set oscilloscope vert scale
			NVAR voltAxis2 = root:gVariables:tekOscilloscope:voltAxis2
			oscCmd("CH2:SCA " + num2str(voltAxis2))
			oscConversionParameters()
			// click code here
			break
	endswitch

	return 0
End

Function ButtonProc_48(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// Set oscilloscope time scale
			NVAR timescale = root:gVariables:tekOscilloscope:timeAxis
			oscCmd("HOR:MAI:SCA " + num2str(timeScale))
			oscConversionParameters()
			// click code here
			break
	endswitch

	return 0
End

Function ButtonProc_49(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// Set number of points to collect
			NVAR N = root:gVariables:tekOscilloscope:numberOfPoints
			oscCmd("DAT:SOU CH1")
			oscCmd("DAT:STOP " + num2str(N))
			oscCmd("DAT:SOU CH2")
			oscCmd("DAT:STOP " + num2str(N))
			redimension/N=(N) root:gVariables:tekOscilloscope:dataWave1, root:gVariables:tekOscilloscope:dataWave2
			redimension/N=(N+3) root:gVariables:tekOscilloscope:dataWave
			// click code here
			break
	endswitch

	return 0
End

Function ButtonProc_50(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// Read wave from channel 1
			oscGetWave(1,"root:gVariables:tekOscilloscope:dataWave1")	
						
			break
	endswitch

	return 0
End

Function ButtonProc_51(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// Read wave from channel 2
			oscGetWave(2,"root:gVariables:tekOscilloscope:dataWave2")
			break
	endswitch

	return 0
End