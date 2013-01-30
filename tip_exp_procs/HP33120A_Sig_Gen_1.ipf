
//=========================== Send a command to the HP33120A Sig Gen================================================
Function/S cmdSig(ss)											//Sends a command to signal generator
	
	String ss
//	Wave CurveB1
	Variable status
	Variable defaultRM
	Variable viHP //Attrib, Timeout	
								
	String errdesc
	String resourceName = "GPIB0::3::INSTR" 	//VISA address of the signal generator oscilloscope
	
	status = viOpenDefaultRM(defaultRM)							//Open instrument manager session
//	Print status
	if (status<0)													//error handling
		viStatusDesc(viHP, status, errdesc)
  		Print errdesc
  		Abort "VISA Comms Error"
	endif
	
	status = viOpen(defaultRM, resourceName, 0, 0, viHP)			//Open instrument session

//	Attrib = viGetAttribute(viTEK, VI_ATTR_TMO_VALUE, Timeout)	//Find out/set different attributes of the VISA comms
//	print Timeout
	
	if (status<0)													//error handling
		viStatusDesc(viHP, status, errdesc)
  		Print errdesc
  		Abort "VISA Comms Error"
	endif	
													
	String command = ss+"\n"
	Variable cnt = strlen(command)
	Variable retCnt											
	
	viWrite(viHP, command, cnt , retCnt)
	
//	if (stringmatch(command, "curve?\n") == 1)							//add in commands that return data to be read to waves here
//	 	CurveB1 = 0
//		VISAReadWave/N=5/T=",\n" viTEK, Curve1						//read back from instrument directly to a wave file (used for ASCII format data)
//		VISAReadBinaryWave/TYPE=(0x10) viTEK, CurveB1				//read back from instrument directly to a wave file (used for 16bit binary format data)
//		viClose(viTEK)												//Close session
//		viClose(defaultRM)
	If (strsearch(command,"?",0)>0)									//all queries (commands for which something is read back) end in a question mark.  These do not need to be read to a wave.
		String buffer = ""												//clears buffer ready for next command
		VISARead/N=500/T="\n" viHP, buffer							//read back reply from instrument.      	
      		viClose(viHP)
		viClose(defaultRM)
		return(buffer)		
      Endif
      
      	viClose(viHP)
	viClose(defaultRM)
  		
End

//=====================Set Frequency of waveform======================================

Function SetFreqSigGen(Frequency)		// in Hz

Variable Frequency
String FrequencyS

FrequencyS = "FREQ "+(num2str(Frequency))+"\n"

cmdSig(FrequencyS)

End

//===================Set Amplitude of waveform==========================================

Function SetAmplitudePP(AmpOut)			//in Volts (peak to peak)

Variable AmpOut
Variable Amp
String AmpS

//Amp = AmpOut/40
Amp = AmpOut/20

//if (Amp >0.5)
//Abort "Voltage will exceed 20V"
//Endif

// Set output terminal to high
cmdSig("OUTPut:LOAD INF")

AmpS = "Voltage "+(num2str(Amp))+"\n"

cmdSig(AmpS)

End

//==================Set DC offset of waveform=====================================

Function SetDCOffset(OffsetOut)		//in Volts

Variable OffsetOut
Variable Offset
String OffsetS

//Offset = OffsetOut/40
Offset = OffsetOut/20

//if (Offset>0.25)
//Abort "DC offset will exceed 10V"
//Endif

OffsetS = "Voltage:Offset "+(num2str(Offset))+"\n"

cmdSig(OffsetS)

End

//==============================================================================

