#pragma rtGlobals=1		// Use modern global access method.

//=========================== Send a command to the Agilent33220A Sig Gen================================================
Function/S cmdSigGen_agilent(ss)											//Sends a command to signal generator
	
	String ss
//	Wave CurveB1
	Variable status
	Variable defaultRM
	Variable viHP //Attrib, Timeout	
								
	String errdesc
	String resourceName = "USB0::0x0957::0x0407::MY44037993::0::INSTR" 	//VISA address of the signal generator
	
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

Function SetFreq_agilent(Frequency)		// in Hz

Variable Frequency
String FrequencyS

FrequencyS = "FREQ "+(num2str(Frequency))+"\n"

cmdSigGen_agilent(FrequencyS)

End

//===================Set Amplitude of waveform==========================================

function SetVmax_agilent(Vmax)

	variable Vmax
	cmdSigGen_agilent("VOLT:HIGH "+num2str(Vmax))	
	
end


function SetVmin_agilent(Vmin)

	variable Vmin
	cmdSigGen_agilent("VOLT:LOW "+num2str(Vmin))	
	
end

Function SetAmplitudePP_agilent(AmpOut)			//in Volts (peak to peak)

Variable AmpOut
Variable Amp
String AmpS

//Amp = AmpOut/40
Amp = AmpOut/20

//if (Amp >0.5)
//Abort "Voltage will exceed 20V"
//Endif

AmpS = "Voltage "+(num2str(Amp))+"\n"

cmdSigGen_agilent(AmpS)

End

//==================Set DC offset of waveform=====================================

Function SetDCOffset_agilent(OffsetOut)		//in Volts

Variable OffsetOut
Variable Offset
String OffsetS

//Offset = OffsetOut/40
Offset = OffsetOut/20

//if (Offset>0.25)
//Abort "DC offset will exceed 10V"
//Endif

OffsetS = "Voltage:Offset "+(num2str(Offset))+"\n"

cmdSigGen_agilent(OffsetS)

End

//=====================Set waveform shape ======================================

Function SetWaveShape_agilent(shape)		

string shape

shape = "FUNC "+shape

cmdSigGen_agilent(shape)

End