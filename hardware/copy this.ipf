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
