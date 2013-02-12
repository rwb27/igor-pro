//=========================Sends a command PI 733.3CD stage================================================

Function/S cmdPI(pp)															//Sends a command to PI 733.3CD (3-axis) stage 
	
	String pp
	Variable status1
	Variable defaultRM1
	Variable viPI
	String errdesc1
	//String resourceName1 = "GPIB0::14::INSTR" 									//VISA address of the PI stage
	String resourceName1 = "ASRL2::INSTR" 									//VISA address of the PI stage
	status1 = viOpenDefaultRM(defaultRM1)										//Open instrument manager session
	
	if (status1<0)																//Error handling
		viStatusDesc(viPI, status1, errdesc1)
  		Print errdesc1
  		Abort "No comms1"
	endif
	
	status1 = viOpen(defaultRM1, resourceName1, 0, 0, viPI)							//Open instrument session
	
	if (status1<0)																//Error handling
		viStatusDesc(viPI, status1, errdesc1)
  		Print errdesc1
  		Abort "No comms2"
	endif
	
	String buffer1="", command1 = pp+"\n"
	Variable cnt1 = strlen(command1), retCnt1
	
	status1 = viWrite(viPI, command1, cnt1 , retCnt1)
	
	if (status1<0)																//Error handling
		viStatusDesc(viPI, status1, errdesc1)
  		Print errdesc1
  		Abort "No comms3"
	endif
	
	if (strsearch(command1,"?",0)<0)											//If there is no '?' in the command sent the stage (i.e. a query) then do not read back any data
		viClose(viPI)
		viClose(defaultRM1)
		//return()																//might solve that little annoying problem about having to delete the 'left-over' command in the command line
	else
		VISARead/T="\n" viPI, buffer1											//If there is a '?' read back the data from the PI stage controller
		viClose(viPI)
		viClose(defaultRM1)
		return(buffer1)
	endif
	
	//if (strsearch(command1,"CFG",0)>0)											//If there is no '?' in the command sent the stage (i.e. a query) then do not read back any data
		//VISARead/T="\n" viPI, buffer1											//If there is a '?' read back the data from the PI stage controller
		//viClose(viPI)
		//viClose(defaultRM1)
		//return(buffer1)
	//EndIf
End

//===================================Set PI stage to 'closed-loop' operation (required for 'movePI' command to work)=====================

Function closeloopPI()

cmdPI("SVO A1")
cmdPI("SVO B1")
cmdPI("SVO C1")

End

//===================================Set PI stage to 'open-loop' operation (always run before turning the controller to 'offline mode' and then powering down)=====================

Function openloopPI()

cmdPI("SVO A0")
cmdPI("SVO B0")
cmdPI("SVO C0")

End

//=====================================Prepares PI stage to recieve commands from IGOR=================================

Function Startup()

cmdPI("onl 1")
Sleep/S 0.5
closeloopPI()
Sleep/S 0.5
ZeroStagePos()
//PISetup()

End

//=========================Move PI stage to a certain absolute position============================================

Function movePI(ch,posn)										//A is ch1, B is ch2, C is ch3	  Needs loop closed!
	
Variable posn
String ch

if  ((stringmatch(ch, "A") == 1) || (stringmatch(ch, "B") == 1))		//Stops the stage being commanded to move beyond its limits of movement	
	  if ((posn<0)||(posn>=100))
	    	Abort "Out of range XY"
	 endif
else
	if ((posn<0)||(posn>=10))
	    	Abort "Out of range Z"
	 endif
endif
	
//cmdPI("MOV "+num2char(64+ch)+num2str(posn))
cmdPI("MOV "+ch+num2str(posn))								//Send move string command to PI stage

//Print "X = "+cmdPI("POS? A")
//Print "Y = "+cmdPI("POS? B")
//Print "Z = "+cmdPI("POS? C")								
	
End

//=========================Move PI stage to a certain relative position============================================

Function moveRelPI(ch,Rpos)										//A is ch1, B is ch2, C is ch3	  Needs loop closed!
	
Variable Rpos
String ch

//if  ((stringmatch(ch, "A") == 1) || (stringmatch(ch, "B") == 1))		//Stops the stage being commanded to move beyond its limits of movement	
//	  
//	  if (((str2num(cmdPI("pos? A")))-Rpos<0)||((Rpos+(str2num(cmdPI("pos? A"))))>=100))
//	    	Abort "Out of range XY"
//	 endif
//	 
//	 if (((str2num(cmdPI("pos? B")))-Rpos<0)||((Rpos+(str2num(cmdPI("pos? B"))))>=100))
//	    	Abort "Out of range XY"
//	 endif
//	 
//else 
//	if (((str2num(cmdPI("pos? C")))-Rpos<0)||((Rpos+(str2num(cmdPI("pos? C"))))>=10))
//	    	Abort "Out of range Z"
//	 endif
//endif
	
//cmdPI("MOV "+num2char(64+ch)+num2str(posn))
cmdPI("MVR "+ch+num2str(Rpos))								//Send move string command to PI stage

//Print "X = "+cmdPI("POS? A")
//Print "Y = "+cmdPI("POS? B")
//Print "Z = "+cmdPI("POS? C")								
	
End

//===========================Zero the position of the PI stage====================================================

Function ZeroStagePos()

cmdPI("MOV A0")
cmdPI("MOV B0")
cmdPI("MOV C0")

Print "X = "+cmdPI("POS? A")
Print "Y = "+cmdPI("POS? B")
Print "Z = "+cmdPI("POS? C")	

End
//================================In case of problems run this to shutdown the stage==========================

Function Shutdown()

ZeroStagePos()
Sleep/S 20.0
OpenloopPI()
Sleep/S 0.5
cmdPI("onl 0")

End

//==============================EmergencySTOP===============================================
Function Stop()

cmdPI("STP A")

End

//==============================Set Velocity of all three axes========================================

Function SetVelocity(Vel)

Variable Vel
String VelSS

VelSS = num2str(Vel)

cmdPI("vco A1")
cmdPI("vco B1")
cmdPI("vco C1")

cmdPI("vel A"+VelSS)
cmdPI("vel B"+VelSS)
cmdPI("vel C"+VelSS)

End

//=========================Initialise the position control panel======================================

Function PIsetup1()
	Nvar CurrX,CurrY,Currz
	Nvar stepX, stepY, stepZ
	CurrX = str2num(cmdPI("Pos? B"))
	CurrY = str2num(cmdPI("Pos? C"))	// limited ranage of travel (vertical)	
	CurrZ =  str2num(cmdPI("Pos? A"))
	stepX = 0.1
	stepY = 0.1
	stepZ = 0.1
End

//=======================================================================================

Function TestPI(cha,posna)

Variable posna
String cha 
Variable VelCHV, PosCHV, Diff
String VelCH, PosCH

VelCH = cmdPI("VEL? "+cha )
Sleep/S 0.3
print VelCH
PosCH = cmdPI("POS? "+cha)
Sleep/S 0.3
print PosCH

PosCHV = str2num(PosCH)
VelCHV = str2num(VelCH)

Diff = posna-PosCHV

if (Diff<0)

	Diff = Diff*(-1)
Endif

if  ((stringmatch(cha, "A") == 1) || (stringmatch(cha, "B") == 1))		//Stops the stage being commanded to move beyond its limits of movement	
	  if ((posna<0)||(posna>=100))
	    	Abort "Out of range XY"
	 endif
else
	if ((posna<0)||(posna>=10))
	    	Abort "Out of range Z"
	 endif
endif
	
//cmdPI("MOV "+num2char(64+ch)+num2str(posn))
cmdPI("MOV "+cha+num2str(posna))
sleep/S (Diff/VelCHV)
Sleep/S 0.3
print cmdPI("POS? "+cha) 
 

End

Function TestPI2()

print cmdPI("POS? A")
print cmdPI("POS? B")
print cmdPI("POS? C")

End