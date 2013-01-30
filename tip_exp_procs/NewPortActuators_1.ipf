
#pragma rtGlobals=1

//========================================================================================
Function InitGlobalsAC()

Variable/G CurrXAC,CurrYAC,CurrZAC
Variable/G stepXAC, stepYAC, stepZAC

End

Function InitGlobalsAC1()

Variable/G MotorControl

End

Function InitGlobalsAC2()
Variable/G PrevCurrXAC,PrevCurrYAC,PrevCurrZAC
End
//=========================Sends a command PI 733.3CD stage================================================

Function/S cmdHLX(nn)															//Sends a command to PI 733.3CD (3-axis) stage 
	
	String nn
	Variable status2
	Variable defaultRM2
	Variable viAC1
	Variable ActuatorID0 = 1
	String errdesc2
	String resourceName2 = "ASRL10" 									//VISA address of the PI stage
	status2 = viOpenDefaultRM(defaultRM2)										//Open instrument manager session
	//print defaultRM2
	if (status2<0)																//Error handling
		viStatusDesc(viAC1, status2, errdesc2)
  		Print errdesc2
  		Abort "No comms1"
	endif
	
	status2 = viOpen(defaultRM2, resourceName2, 0, 0, viAC1)							//Open instrument session
	
	if (status2<0)																//Error handling
		viStatusDesc(viAC1, status2, errdesc2)
  		Print errdesc2
  		Abort "No comms2_HLX"
	endif
	
	String buffer2="", command2 = num2str(ActuatorID0)+nn+"\r\n"
	Variable cnt2 = strlen(command2), retCnt2
	
	status2 = viWrite(viAC1, command2, cnt2 , retCnt2)
	
	if (status2<0)																//Error handling
		viStatusDesc(viAC1, status2, errdesc2)
  		Print errdesc2
  		Abort "No comms3"
	endif
	
	if (strsearch(command2,"?",0)<0)											//If there is no '?' in the command sent the stage (i.e. a query) then do not read back any data
		viClose(viAC1)
		viClose(defaultRM2)
		//return()																//might solve that little annoying problem about having to delete the 'left-over' command in the command line
	else
		VISARead/T="\r\n" viAC1, buffer2											//If there is a '?' read back the data from the PI stage controller
		viClose(viAC1)
		viClose(defaultRM2)
		return(buffer2)
	endif
	
	//if (strsearch(command1,"CFG",0)>0)											//If there is no '?' in the command sent the stage (i.e. a query) then do not read back any data
		//VISARead/T="\n" viPI, buffer1											//If there is a '?' read back the data from the PI stage controller
		//viClose(viPI)
		//viClose(defaultRM1)
		//return(buffer1)
	//EndIf
End
//===========================TestCommands=================================================

Function CurrentPositionHLX()
print cmdHLX("TP?")
End
//===========================General commands=========================================
Function moveHLX(PosHL)

Variable PosHL

PosHL = PosHL/1000
//PosHL = -PosHL
//If ((PosHL>=25) || (PosHL<0))
	//Abort "Out of range X"
//Endif
//print PosHL
cmdHLX("PR"+Num2str(PosHL))

End

Function/S posHLX()

String FullPosX
String PosX
Variable FullPosXLength

FullPosX = cmdHLX("TP?")

FullPosXLength  = Strlen(FullPosX) - 1

PosX = FullPosX[3,FullPosXLength]

//print PosX
return(PosX)
End

Function/S ReadyStatusHLX()

String ReadyInfo
String ReadyState

ReadyInfo = cmdHLX("TS?")

ReadyState = ReadyInfo[7,8]

//print ReadyState
return(ReadyState)

End

Function HomeSearch()

cmdHLX("OR")

End

Function SetVelocityHLX()

cmdHLX("VA0.1")

End


//===============================================================================

Function/S cmdPZZ(cc)															//Sends a command to PI 733.3CD (3-axis) stage 
	
	String cc
	Variable status3
	Variable defaultRM3
	Variable viAC2
	Variable ActuatorID1 = 1
	String errdesc3
	String resourceName3 = "ASRL9" 									//VISA address of the PI stage
	status3 = viOpenDefaultRM(defaultRM3)										//Open instrument manager session
	
	if (status3<0)																//Error handling
		viStatusDesc(viAC2, status3, errdesc3)
  		Print errdesc3
  		Abort "No comms1"
	endif
	
	status3 = viOpen(defaultRM3, resourceName3, 0, 0, viAC2)							//Open instrument session
	
	if (status3<0)																//Error handling
		viStatusDesc(viAC2, status3, errdesc3)
  		Print errdesc3
  		Abort "No comms2_PZZ"
	endif
	
	String buffer3="", command3 = num2str(ActuatorID1)+cc+"\r\n"
	Variable cnt3 = strlen(command3), retCnt3
	//print command3
	status3 = viWrite(viAC2, command3, cnt3 , retCnt3)
	
	if (status3<0)																//Error handling
		viStatusDesc(viAC2, status3, errdesc3)
  		Print errdesc3
  		Abort "No comms3"
	endif
	
	if (strsearch(command3,"?",0)<0)											//If there is no '?' in the command sent the stage (i.e. a query) then do not read back any data
		viClose(viAC2)
		viClose(defaultRM3)
		//return()																//might solve that little annoying problem about having to delete the 'left-over' command in the command line
	else
		VISARead/T="\r\n" viAC2, buffer3											//If there is a '?' read back the data from the PI stage controller
		viClose(viAC2)
		viClose(defaultRM3)
		//print buffer3
		return(buffer3)
	endif
	
	//if (strsearch(command1,"CFG",0)>0)											//If there is no '?' in the command sent the stage (i.e. a query) then do not read back any data
		//VISARead/T="\n" viPI, buffer1											//If there is a '?' read back the data from the PI stage controller
		//viClose(viPI)
		//viClose(defaultRM1)
		//return(buffer1)
	//EndIf
End

//===========================TestCommands=================================================

Function CurrentPositionPZZ()

print cmdPZZ("TP?")

End

//===========================General commands=========================================
Function movePZZ(PosPZZ)

Variable PosPZZ
String FPosPZZ
Variable PosPZZ1
PosPZZ1 = PosPZZ*60
//PosPZZ1 = -PosPZZ1
PosPZZ1 = round(PosPZZ1)

sprintf FPosPZZ, "%8d\r", PosPZZ1
//printf "%8.3f\r", PosPZZ1
//print FPosPZZ

//If ((PosPZZ>=12) || (PosPZZ<0))
	//Abort "Out of range Z"
//Endif
//print Num2str(F1PosPZZ)
cmdPZZ("PR"+FPosPZZ)

End

Function/S posPZZ()

String FullPosZ
String PosZ
Variable FullPosZLength

FullPosZ = cmdPZZ("TP?")

FullPosZLength  = Strlen(FullPosZ) - 1

PosZ = FullPosZ[5,FullPosZLength]

//print PosZ
return(PosZ)

End

Function/S ReadyStatusPZZ()

String ReadyInfo1
String ReadyState1

ReadyInfo1 = cmdPZZ("TS?")

ReadyState1 = ReadyInfo1[5]

//print ReadyState
return(ReadyState1)

End

//=========================================================================================

Function/S cmdPZY(dd)															//Sends a command to PI 733.3CD (3-axis) stage 
	
	String dd
	Variable status4
	Variable defaultRM4
	Variable viAC3
	Variable ActuatorID2 = 1
	String errdesc4
	String resourceName4 = "ASRL8" 									//VISA address of the PI stage
	status4 = viOpenDefaultRM(defaultRM4)										//Open instrument manager session
	
	if (status4<0)																//Error handling
		viStatusDesc(viAC3, status4, errdesc4)
  		Print errdesc4
  		Abort "No comms1"
	endif
	
	status4 = viOpen(defaultRM4, resourceName4, 0, 0, viAC3)							//Open instrument session
	
	if (status4<0)																//Error handling
		viStatusDesc(viAC3, status4, errdesc4)
  		Print errdesc4
  		Abort "No comms2"
	endif
	
	String buffer4="", command4 = num2str(ActuatorID2)+dd+"\r\n"
	Variable cnt4 = strlen(command4), retCnt4
	
	status4 = viWrite(viAC3, command4, cnt4 , retCnt4)
	if (retCnt4!=cnt4)
		Print "Not written all comands"
	Endif
	
	if (status4<0)																//Error handling
		viStatusDesc(viAC3, status4, errdesc4)
  		Print errdesc4
  		Abort "No comms3"
	endif
	
	if (strsearch(command4,"?",0)<0)											//If there is no '?' in the command sent the stage (i.e. a query) then do not read back any data
		viClose(viAC3)
		viClose(defaultRM4)
		//return()																//might solve that little annoying problem about having to delete the 'left-over' command in the command line
	else
		VISARead/T="\r\n" viAC3, buffer4											//If there is a '?' read back the data from the PI stage controller
		viClose(viAC3)
		viClose(defaultRM4)
		return(buffer4)
	endif
	
	//if (strsearch(command1,"CFG",0)>0)											//If there is no '?' in the command sent the stage (i.e. a query) then do not read back any data
		//VISARead/T="\n" viPI, buffer1											//If there is a '?' read back the data from the PI stage controller
		//viClose(viPI)
		//viClose(defaultRM1)
		//return(buffer1)
	//EndIf
End

//===========================TestCommands=================================================

Function CurrentPositionPZY()

print cmdPZY("TP?")

End
//=============================General commands==========================================
Function movePZY(PosPZY)

Variable PosPZY
String FPosPZY
Variable PosPZY1
PosPZY1 = PosPZY*80
//PosPZY1 = -PosPZY1
PosPZY1 = round(PosPZY1)
sprintf FPosPZY, "%8d\r", PosPZY1
//printf "%8.3f\r", PosPZY1
//print FPosPZY

//If ((PosPZY>=12) || (PosPZY<0))
	//Abort "Out of range Y"
//Endif
//print Num2str(F1PosPZY)
cmdPZY("PR"+FPosPZY)

End


Function/S posPZY()

String FullPosY
String PosY
Variable FullPosYLength

FullPosY = cmdPZY("TP?")

FullPosYLength  = Strlen(FullPosY) - 1

PosY = FullPosY[5,FullPosYLength]

//print PosY
return(PosY)
End

Function/S ReadyStatusPZY()

String ReadyInfo2
String ReadyState2

ReadyInfo2 = cmdPZY("TS?")

ReadyState2 = ReadyInfo2[5]

//print ReadyState
return(ReadyState2)

End

//======================Commands for all three controllers simultaeously=====================================

Function MotorsON()

cmdHLX("MM1")
cmdPZZ("MO")
cmdPZY("MO")
Sleep/S 1.0
ACsetup()

End

Function MotorsOFF()

cmdHLX("MM0")
cmdPZZ("MF")
cmdPZY("MF")
Sleep/S 1.0
ACsetup()

End

Function StopAll()

cmdHLX("ST")
cmdPZZ("ST")
cmdPZY("ST")

End

//==========================Panel Creation===================================================

Function SetVarProc_1AC(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	Nvar CurrXAC, PrevCurrXAC
	//print CurrXAC
	moveHLX(CurrXAC-PrevCurrXAC)
	HLXSetup()
End


Function SetVarProc_2AC(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	Nvar CurrYAC, PrevCurrYAC
	movePZY(CurrYAC-PrevCurrYAC)
	PZYSetup()

End

Function SetVarProc_3AC(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	Nvar CurrZAC, PrevCurrZAC
	movePZZ(CurrZAC-PrevCurrZAC)
	PZZSetup()

End

Function SetVarProc_4AC(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	Nvar stepXAC
	SetVariable setvar0 limits={0,inf,stepXAC}
End



Function SetVarProc_6AC(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	Nvar stepZAC
	SetVariable setvar2 limits={0,inf,stepZAC}
End

Function SetVarProc_5AC(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	Nvar stepYAC
	//stepYAC = -stepYAC
	SetVariable setvar1 limits={0,inf,stepYAC}
End

Function ButtonProc_1AC(ctrlName) : ButtonControl
	String ctrlName
	StopAll()

End

Function CheckProcAC(ctrlName,value) : CheckBoxControl
	String ctrlName
	Variable value
	NVAR MotorControl= root:MotorControl
	strswitch (ctrlName)
		case "check0":
			MotorControl= 1
			MotorsON()
			break
		case "check1":
			MotorControl= 2
			MotorsOFF()
			break
	endswitch
	CheckBox check0,value= MotorControl==1
	CheckBox check1,value= MotorControl==2

End

//Function CheckProcAC1(ctrlName,checked) : CheckBoxControl
	//String ctrlName
	//Variable checked
	//MotorsOFF()

//End

Function ACsetup()
	Nvar CurrXAC,CurrYAC,CurrZAC
	Nvar stepXAC, stepYAC, stepZAC
	Nvar PrevCurrXAC,PrevCurrYAC,PrevCurrZAC
	//Variable/G CurrX,CurrY,CurrZ
	//Variable/G stepX, stepY, stepZ
	CurrXAC = 1000*(str2num(posHLX()))
	CurrYAC = (str2num(posPZY()))/80	
	CurrZAC =  (str2num(posPZZ()))/60
	PrevCurrXAC = CurrXAC
	PrevCurrYAC = CurrYAC
	PrevCurrZAC = CurrZAC
	stepXAC = 500.0
	stepYAC = 500.0
	stepZAC = 500.0
	//print CurrXAC
	//print CurrYAC
	//print CurrZAC
End

Function Positions()
	Nvar CurrXAC,CurrYAC,CurrZAC
	CurrXAC = 1000*(str2num(posHLX())) // limited ranage of travel (vertical)
	CurrYAC = (str2num(posPZY()))/80		
	CurrZAC =  (str2num(posPZZ()))/60
	print CurrXAC
	print CurrYAC
	print CurrZAC
End

Function HLXSetup()

Nvar CurrXAC
Nvar PrevCurrXAC
String RS = ""
//Sleep/S 1.0

//RS = ReadyStatusHLX()

do 
	RS = ReadyStatusHLX()
while (stringmatch(RS,"33") == 0)

CurrXAC = 1000*(str2num(posHLX()))
PrevCurrXAC = CurrXAC
	
End

Function PZZSetup()

Nvar CurrZAC
Nvar PrevCurrZAC

String RS1 = ""
//Sleep/S 1.0

//RS = ReadyStatusPZZ()

do 
	RS1 = ReadyStatusPZZ()
	//print RS1
while (stringmatch(RS1,"Q") == 0)

CurrZAC = (str2num(posPZZ()))/60
PrevCurrZAC = CurrZAC

End

Function PZYSetup()

Nvar CurrYAC
Nvar PrevCurrYAC
String RS2 = ""
//Sleep/S 1.0

//RS = ReadyStatusPZY()

do 
	RS2 = ReadyStatusPZY()
while (stringmatch(RS2,"Q") == 0)

CurrYAC = (str2num(posPZY()))/80
PrevCurrYAC = CurrYAC

End


Window PanelAC() : Panel
	//Variable/G CurrX, CurrY, CurrZ
	//Variable/G stepX, stepY, stepZ
	Variable root:CurrXAC
	Variable root:CurrYAC
	Variable root:CurrZAC
	Variable root:stepXAC
	Variable root:stepYAC
	Variable root:stepZAC
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(599,228,1198,355)
	ShowTools/A
	SetDrawLayer UserBack
	DrawText 457,53,"larger Z moves right"
	DrawText 274,53,"y moves focus"
	DrawText 35,52,"larger X moves up"
	SetVariable setvar0,pos={7,7},size={140,26},proc=SetVarProc_1AC,title="X"
	SetVariable setvar0,fSize=20,format="%8.3f",limits={-inf,inf,0.3},value= CurrXAC
	SetVariable setvar1,pos={232,7},size={142,26},proc=SetVarProc_2AC,title="Y"
	SetVariable setvar1,fSize=20,format="%8.3f",limits={-inf,inf,0.1},value= CurrYAC
	SetVariable setvar2,pos={436,7},size={140,26},proc=SetVarProc_3AC,title="Z"
	SetVariable setvar2,fSize=20,format="%8.3f",limits={-inf,inf,0.1},value= CurrZAC
	SetVariable setvar3,pos={7,65},size={189,22},proc=SetVarProc_4AC,fSize=16
	SetVariable setvar3,format="%8.3f",limits={0,inf,0.03},value= stepXAC
	SetVariable setvar4,pos={205,65},size={189,22},proc=SetVarProc_5AC,fSize=16
	SetVariable setvar4,format="%8.3f",limits={0,inf,0.016},value= stepYAC
	SetVariable setvar5,pos={404,66},size={188,22},proc=SetVarProc_6AC,fSize=16
	SetVariable setvar5,format="%8.3f",limits={0,inf,0.01},value= stepZAC
	Button button0,pos={23,100},size={74,20},proc=ButtonProc_1AC,title="STOP ALL"
	Button button0,labelBack=(65535,65535,65535),fStyle=1,fColor=(65280,0,0)
	CheckBox check0,pos={116,102},size={76,15},proc=CheckProcAC,title="Motors ON"
	CheckBox check0,value=0,mode=1
	CheckBox check1,pos={208,103},size={81,15},proc=CheckProcAC,title="Motors OFF"
	CheckBox check1,value=0,mode=1
EndMacro