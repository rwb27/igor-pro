#pragma rtGlobals=1		// Use modern global access method.

// mh654 - 08/11/2012
// Modified to fit onto tip rig experiment and to incorporate freq generator control for external modulations

Menu "Cube"
	   "Initialise Cube" , /Q, Cube_setup()
End

Function Cube_Write(ss)		// write to Coherent Cube laser
String ss
VDTOperationsPort2 COM1
if (Cube_pendingread()>0)
  Cube_readout()
endif
ss += "\r"
VDTWrite2/O=3 ss
Sleep/Q/T 10	// otherwise goes too fast and misses buffer read
End

Function/S Cube_readout()
String Srd="",Sbit,Srd2
Variable slen
do
  if (Cube_pendingread()==0)
    break
  endif
  VDTRead2/T="\r"/O=3/N=(Cube_pendingread()) Sbit
  Srd += Sbit
while (1)
//sprintf Srd2,"%."+num2str(strlen(Srd)-2)+"s",Srd	// strips last character
Srd2 = Srd
//Srd2 = Srd[0,strlen(Srd)-2]
return(Srd2)
End

Function Cube_pendingread()
VDTGetStatus2 0,0,0
return(V_VDT)
End

Macro Cube_purge()
Cube_readout()
VDTGetStatus2 0,1,1
if ((V_VDT %& 1) != 0)
		Abort "A serial port software overrun error occurred."
endif
if (V_VDT != 0)
	Printf "Serial error code: %0X\r", V_VDT
	Abort "Some other serial port error occurred."
endif
EndMacro

Function/S Cube_status()
Cube_Write("?STA")
String Std = Cube_readout()
return(Std)
End

Function Cube_readnominalpower()		// returns nominal power in mW
Cube_Write("?NOMP")
String Srd = Cube_readout()
Variable pp
sscanf Srd,"NOMP=%f",pp
return(pp)
End

Function Cube_readpower()		// returns power in mW
Cube_Write("?P")
String Srd = Cube_readout()
Variable pp
sscanf Srd,"P=%f",pp
return(pp)
End

Function/S Cube_writeRead(cmd)		//
string cmd
Cube_Write(cmd)
String Srd = Cube_readout()
return(Srd)
End

Function Cube_setpower(pp)		// sets power in mW
Variable pp
if (pp>100)
  Print "power too high"
  return 1
endif
Cube_Write("P="+num2str(pp))
Sleep/T 30
//Print Cube_readout()
return(Cube_readpower())
End

Macro Cube_setup()
	variable/G root:gVariables:CUBEcontrol:Cube_power
	variable/g root:gVariables:CUBEcontrol:Cube_EXT
	string/G root:gVariables:CUBEcontrol:CubeCOM="COM1"

	String CubeCOM = root:gVariables:CUBEcontrol:CubeCOM

	Cube()
	
	VDTClosePort2 $CubeCom
	VDT2/P=$CubeCom baud=19200, stopbits=1, databits=8, parity=0, terminalEOL=0
	VDTOpenPort2 $CubeCom
	
	// Initialize
	Cube_Write("EXT=0")										// Set EXT=0
	root:gVariables:CUBEcontrol:Cube_power = 0				// Set power to zero
	Cube_setpower(root:gVariables:CUBEcontrol:Cube_power)

EndMacro


Window Cube() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(179,189,362,533)
	ShowTools/A
	SetDrawLayer UserBack
	SetDrawEnv fsize= 16
	DrawText 20,22,"Cube Laser control"
	SetDrawEnv linethick= 3
	DrawLine 9,141,173,141
	SetDrawEnv fsize= 16
	DrawText 22,167,"Agilent Freq. Gen."
	DrawText 57,330,"(SIN, SQU, or RAMP)"
	SetVariable setvar0,pos={92,27},size={75,20},proc=SetVarProc,title=" ",fSize=14
	SetVariable setvar0,limits={0,25,0},value= root:gVariables:CUBEcontrol:Cube_power
	Button button0,pos={12,27},size={75,20},proc=ButtonProc_cube2,title="Power (mW)"
	Button button0,fSize=12
	Button button1,pos={12,52},size={75,50},proc=ButtonProc_cube3,title="Laser\rOn"
	Button button1,fSize=14,fColor=(0,39168,0)
	Button button2,pos={92,52},size={75,50},proc=ButtonProc_Cube4,title="Laser\rOff"
	Button button2,fSize=14,fColor=(52224,0,0)
	SetVariable setvar1,pos={6,205},size={109,20},bodyWidth=50,title="Freq (Hz)"
	SetVariable setvar1,fSize=14
	SetVariable setvar1,limits={0,inf,0},value= root:gVariables:Agilent33220A:Agilent33220A_freq
	Button button3,pos={120,205},size={50,20},proc=ButtonProc_Cube10,title="Set"
	Button button3,fSize=14
	SetVariable setvar2,pos={11,233},size={104,20},bodyWidth=50,title="Vmin (V)"
	SetVariable setvar2,fSize=14
	SetVariable setvar2,limits={0,5,0},value= root:gVariables:Agilent33220A:Agilent33220A_Vmin
	Button button4,pos={120,233},size={50,20},proc=ButtonProc_Cube9,title="Set"
	Button button4,fSize=14
	SetVariable setvar3,pos={7,262},size={108,20},bodyWidth=50,title="Vmax (V)"
	SetVariable setvar3,fSize=14
	SetVariable setvar3,limits={0,5,0},value= root:gVariables:Agilent33220A:Agilent33220A_Vmax
	Button button5,pos={120,262},size={50,20},proc=ButtonProc_Cube8,title="Set"
	Button button5,fSize=14
	Button button6,pos={12,172},size={155,25},proc=ButtonProc_Cube5,title="Setup"
	Button button6,fSize=14,fColor=(0,39168,0)
	SetVariable setvar4,pos={21,291},size={94,20},bodyWidth=50,title="Shape"
	SetVariable setvar4,fSize=14
	SetVariable setvar4,value= root:gVariables:Agilent33220A:Agilent33220A_shape
	Button button7,pos={120,291},size={50,20},proc=ButtonProc_Cube6,title="Set"
	Button button7,fSize=14
	Button button8,pos={92,105},size={75,23},proc=ButtonProc_Cube7,title="Set"
	Button button8,fSize=14,fColor=(52224,52224,52224)
	SetVariable setvar5,pos={12,106},size={72,20},bodyWidth=50,title="Ext",fSize=14
	SetVariable setvar5,limits={0,1,1},value= root:gVariables:CUBEcontrol:Cube_EXT
EndMacro

Function SetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	Nvar Cube_power = root:gVariables:CUBEcontrol:Cube_power
	Cube_power = Cube_setpower(Cube_power)
End

Function ButtonProc_cube2(ctrlName) : ButtonControl
	String ctrlName
	Nvar Cube_power = root:gVariables:CUBEcontrol:Cube_power
	Cube_power = Cube_readpower()
End


Function ButtonProc_Cube3(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			Cube_Write("L=1")			// Turn Cube on
			NVAR Cube_state = root:gVariables:CUBEcontrol:Cube_State
			Cube_state = 1
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_Cube4(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			Cube_Write("L=0")			// Turn Cube off
			NVAR Cube_state = root:gVariables:CUBEcontrol:Cube_State
			Cube_state = 0
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function ButtonProc_Cube5(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	// Set-up Agilent freq. generator	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			cmdSigGen_agilent("OUTP:LOAD INF")	// High-Z output terminal
			SetWaveShape_agilent("SIN")			// Sine wave
			SetVmin_agilent(0.9)					// Set Vmin to 0.9V
			SetVmax_agilent(1.1)					// Set Vmax to 1.1V
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_Cube6(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			SVAR shape = root:gVariables:Agilent33220A:Agilent33220A_shape
			
			if(stringmatch(shape, "SIN"))
				SetWaveShape_agilent(shape)	
				break
			elseif(stringmatch(shape, "SQU"))
				SetWaveShape_agilent(shape)
				break
			elseif(stringmatch(shape, "RAMP"))
				SetWaveShape_agilent(shape)
				break
			endif
			print "Invalid shape!"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_Cube7(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			NVAR Cube_EXT = root:gVariables:CUBEcontrol:Cube_EXT
			Cube_Write("EXT="+num2str(Cube_EXT))			// Set External modulation
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function ButtonProc_Cube8(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			NVAR Vmax = root:gVariables:Agilent33220A:Agilent33220A_Vmax
			SetVmax_agilent(Vmax)

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_Cube9(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			NVAR Vmin = root:gVariables:Agilent33220A:Agilent33220A_Vmin
			SetVmin_agilent(Vmin)

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_Cube10(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			NVAR freq = root:gVariables:Agilent33220A:Agilent33220A_freq
			SetFreq_agilent(freq)

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

