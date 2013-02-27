#pragma rtGlobals=1		// Use modern global access method.

// v4.2 Jan Mertens (jm806) (20Nov2012)
// added ability to swap between different reference spectra - requires user to save reference spectra with button "save spectra". Different reference spectra can be choosen by setting the Ref Index to the scan index
// and pressing button "Set Ref 1"
// v4.1 PF added ability to export data to text files
// Version 4 - James Hugall
// v4.0 (08Feb2011)- Changed to work with new v5 XOP functions, OOIgor_Open(), OOIgor_GetPixels(OOsnum), OOIgor_GetName(OOsnum), OOIgor_Close() - should be better memory handling in XOP.
// (created OOIgor_Config2, which also intializes integration time to 100ms as a fall back)
// OOIgor_GetDarkPixels(OOsnum) gets the dark pixel count of CCD.
// Program is now a lot more stable and has increased error handling both in IPF and XOP: no big feature changes.
// Key Changes:
// added OO_LIVEREFRESH_PERIOD constant, so speed of Live update can easily be adjusted at top of file.
// changed live to a named background task for more modern programming style and less interference with other programs
// changed button position of # of integrations and average so that no overlap when switchin to 2 spectrometers.
// changed swap, so only available when >1 spec. connected
// added feature so spec, drop-down only displays 1 or 2 depending on how many spectrometers attached
// green button to left of spectrometers reintializes spectrometers
// intialise displays names and serial numbers of found spectrometers
// FINALLY sorted swap spectra error, was happening due to spectrometers being read before waves being correctly configured to write lengths (as swapped)... caused memory mismatch errors and fatal crash!
// N.B. Despite efforts, still seems to be some (minor) memory handle problem when re-intialising. This shouldn't cause any noticeable effects, but if you are doing this a lot (unlikely) and experiencing probs, considering restarting Igor.

//3.10 Note: Cannot uncheck 'create absorbance spectra' whilst in live display mode (as spectra is on display) - RT
// 3.10 Added absorbance feature and graph toggle JH
//3.10 Added Doupdate on kinetics feature, also removed unnecessary (and error causing) function on NumSpectra variable control - RT/JH
//3.09 RD  Multiple spectra auqisition and averaging now also works for multiple integration times
//3.08 JJB added support for Omnidriver1.3 and NIRQuest
// had to move around buttons on menu (SM put in wrong place)

//v3.06 SM added kinetic measurement feature - reads and saves spectra after a specified delay time for a specified number of times 
//v3.05 JJB changed something?
// v3.04 2008 01 30    JJB: added TEC cooler for QE65000
// v3.03 who wrote this?
// v3.02 who wrote this? what is changed?
// v3.01 2008 29 09 	JJB, now uses OmniDriver, almost all works
// still to do: shutter on/off should be in different Panel only

/// v.2.16 2008 07 18 BFS adding multiple integration times for same spectrometer.
/// Notes on this:
/// Other changes:
/// Changed ways data gets saved to folders: instead of duplicate each wave separatly, the program now copies the raw folder into subfolder.
/// This means the data for the current scan should now be in Data:Current, instead of Data: Anyway, have a problem with this can 
/// come and talk with me

// v2.15 2008 06 23 JJB: added USB2G33262 redtide
// v2.14  2008 06 06  by Bruno Soares, Spectrometer USB2G16425 added
// Version 2.13- if you add a new spectrometer need to update OO_Calibration function with wl_wave coefficient values
// Version 2.12 update folder structure, return functions to initial data folder, rename functions, add onenote save, include variables (IntT) in saved data folders

// Version 2.11: Changes by: Robin Cole
// Notes: changed menu to point to OOspec, change default spectrometer popup tab to display 'no spectrometer selected' to avoid confusion
// Wishlist:
// Functions changed:

// Version 2.6 Robin clean up referencing to waves and globals, rename functions _OOspec
// Added buttons for second spectrometer to store reference waves

// Version 2.4: Last changes by JJB: added RedTide and HR2000
// Last Changes by Bruno: Corrected range of duplicate errors in single spectrometer use and a range of other minor problems.

//Notes = Igor reads out two NaN points from the spectrometers, wheras OO prog reads out only one NaN point- see makewaves function
// So currently out by 0.3nm

static constant OO_LIVEREFRESH_PERIOD=3 // refresh period of live display in ticks (1 tick=1/60th sec)

Menu "OOspec"
	   "Initialise OOspec" , /Q, OO_InitialiseProgram()
End

Function OO_InitialiseProgram()											//Run this first
	String savDF= GetDataFolder(1)									//Save current DF for restore.
	OO_CreateAllFolders()												//Create all folders needed
	OO_Init_Globals()	
	OO_Init_Waves()
		
	DoWindow/K/R OO_LiveSpectraGraph
	Execute "OO_LiveSpectraGraph()"	
	SetDataFolder savDF	
	OOIgor_Close() // Closes any open connections (shouldn't give error if already closed, otherwise may need to add handling)
	variable numSpecs=OOIgor_Open() // opens connections
	if (numspecs>0)
	//	OO_config_allspecs(numSpecs) - JTH now defunct
		variable ii
		string specs_str=""
		For (ii=0;ii<numspecs;ii+=1)
			specs_str+=num2str(ii)+":"+ OOIgor_getname(ii) + " ("+OOIgor_getusbserialnumber(ii)+"); "
		EndFor
		
		Print num2str(numspecs)+" spectrometers found attached:"+specs_str
		
		if (numspecs==1)
			PopupMenu Multiple_Spectrometers_popup,mode=1,popvalue="1",value= #"\"1\""
		else
			PopupMenu Multiple_Spectrometers_popup,mode=1,popvalue="1",value= #"\"1;2\""
		endif
		
		OO_PopMenuProc("Multiple_Spectrometers_popup",1,"")				// start single spectrometer
	else
		Print "Error: No spectrometers found."
	endif
End


Function OO_CreateAllFolders()											//Want to create global variables in Variables folder
	String savDF= GetDataFolder(1)									//Save current DF for restore.
	SetDataFolder root:												//Create global variables in root
	NewDataFolder/O/S root:OO
	NewDataFolder/O/S root:OO:GlobalVariables					//Then create globalvariables folder
	NewDataFolder/O/S root:OO:Data							//Wave and data folder
	NewDataFolder/O/S root:OO:Data:Current
	SetDataFolder savDF	
End

Function OO_Init_Waves()			// initialise waves for single spectrometer only
	String savDF= GetDataFolder(1)									//Save current DF for restore.
	SetDataFolder root:OO:Data:Current	
	Make/O/N=2048 Spectra, Spectrabkgd, SpectrabkgdTemp, wl_wave, Ref, RefTemp, SpectraRaw //Referenc wave= eg mirror reflectivity	
	SetDataFolder savDF
	Return 0
End

Function OO_Init_Globals()												//initialise all global variables etc
	String savDF= GetDataFolder(1)										//Save current DF for restore.
	SetDataFolder root:OO:GlobalVariables									//Then create globalvariables folder
	String/G DataWaveName =""
	String/G OneNotePath
	Variable/G NextSpecIndex=1 											//Save scan number, might go over original data
	Variable/G IntT = 3													//1st spectrometer int time
	Variable/G IntT_2 = 3													//2nd spectrometer int time
	Variable/G ScanTime=1												//Delay time between spectra
	Variable/G NumSpectra=1 											//Number of spectra to be recorded
	Variable/G Ymin = 0
	Variable/G Ymax =4000
	Variable/G Xmin = 360
	Variable/G Xmax =1000
	Variable/G Ymin_2 = 0
	Variable/G Ymax_2 =60000
	Variable/G AutocheckedY = 0										//AutoscaleY or not
	Variable/G AutocheckedX = 0										//AutoscaleY or not
	Variable/G Ref1Exists = 0											//Does reference wave exist? 0 = no
	Variable/G Ref2Exists = 0											//Does reference wave exist? 0 = no
	String/G Spectrometer = ""										//Which spectrometer
	String/G Spectrometer_2 = ""										//Second spectrometer
	Variable/G NumSpectrometers = 1
	Variable/G Logged = 0											//if this is 0 then linear scale, if 1 then logged
	Variable/G Swapped = 0											//swaps which spectrometer used for 0
	Variable/G MultiIntTimes = 0 				// 1= use multi int times; 0 use normal mode
	Variable/G numberint = 1					// number of aquired spectra
	Variable/G averagedspec =1				// Average or sum spectra
	Variable/G TECtemp = -10
	Variable/G Absorbance_checked=0
	Variable/G Absorbance_toggled=0
	Variable/G RefIndex = 0
	SetDataFolder savDF
	Return 0
End

Function OO_snum(ss)				// swaps logical spectrometer 0 to actual spectrometer 1: will crash if only one connected!
Variable ss
Variable sout = ss
Nvar Swapped = root:OO:GlobalVariables:Swapped
if (Swapped==1)
  sout = 1-ss
endif
return(sout)
End

Function OO_Calibrate(snum,wl_wave_ref)				//pass spectrometer number and wl_wave
	Variable snum									//which spectrometer is in use
	Wave wl_wave_ref								//wl_wave or wl_wave_2
	String savDF= GetDataFolder(1)
	SetDataFolder  root:OO:Data:Current
//	Wave wl_wave_ref_pointer=wl_wave_ref
//	OOIgor_Wl(OO_snum(snum),wl_wave_ref_pointer)				// calibration from spectrometer directly
	OOIgor_Wl(OO_snum(snum),wl_wave_ref)				// calibration from spectrometer directly

	SetDataFolder savDF
	Return 0
End

//Function OO_config_allspecs(nspecs) // created temporarily, but now defunct - JTH
//variable nspecs
//variable ii
//string sdFolder=getdatafolder(1)
//setdatafolder root:OO:GlobalVariables
//For (ii=0;ii<nspecs;ii+=1)
//	variable pixels=OOIgor_Config2(ii)
//	if(pixels<=-1)
//		Print "Error configuring spectrometer "+ num2str(ii)
//	else
//		Variable /g $"PixelsPhysSpec"+num2str(ii)=pixels
//	endif
//
//EndFor
//setdatafolder $sdFolder
//End

Function OO_Config(snum)
	Variable snum
	String savDF= GetDataFolder(1)
	Variable OOnpnts
	SetDataFolder  root:OO:Data:Current
	//	OOnpnts = OOIgor_Config2(OO_snum(snum)) // JTH removed to OO_config_allspecs(nspecs)
//	NVAR pixels=$"root:OO:GlobalVariables:PixelsPhysSpec"+num2str(OO_snum(snum)) // get actual physical spectrometers number of pixels (Stored on intiation)
	//OOnpnts=pixels
	OOnpnts = OOIgor_GetPixels(OO_snum(snum))
	if (snum==0)		// setup and calibrate 1st spectrometer
		Make/O/N=(OOnpnts) Spectra, Spectrabkgd, SpectrabkgdTemp, wl_wave, Ref, RefTemp, SpectraRaw //Referenc wave= eg mirror reflectivity	
		Spectrabkgd=0
		OO_Calibrate(snum,wl_wave)
		SVAR Spectrometer=root:OO:GlobalVariables:Spectrometer
		Spectrometer=OOIgor_GetUSBSerialNumber(OO_snum(snum))
	  	
		//  	Execute "root:OO:GlobalVariables:Spectrometer = OOIgor_GetUSBSerialNumber(OO_snum(0))"	// sometimes on the first call this gets garbled, not sure why, fine if call again, JJB
		//  	Execute "root:OO:GlobalVariables:Spectrometer = OOIgor_GetUSBSerialNumber(OO_snum(0))"	// sometimes on the first call this gets garbled, not sure why, fine if call again, JJB
		Nvar IntT=root:OO:GlobalVariables:IntT
	elseif (snum==1)				// setup and calibrate 2nd spectrometer
		Make/O/N=(OOnpnts) Spectra_2, Spectrabkgd_2, SpectrabkgdTemp_2, wl_wave_2, Ref_2, RefTemp_2, SpectraRaw_2 //Referenc wave= eg mirror reflectivity	
		Spectrabkgd_2=0
		OO_Calibrate(snum,wl_wave_2)
		SVAR Spectrometer_2=root:OO:GlobalVariables:Spectrometer_2
		Spectrometer_2=OOIgor_GetUSBSerialNumber(OO_snum(snum))
		//	 	Execute "root:OO:GlobalVariables:Spectrometer_2 = OOIgor_GetUSBSerialNumber(OO_snum(1))"
		// 		Execute "root:OO:GlobalVariables:Spectrometer_2 = OOIgor_GetUSBSerialNumber(OO_snum(1))"
		Nvar IntT=root:OO:GlobalVariables:IntT_2
	endif
	OOIgor_SetIntTime(OO_snum(snum),IntT*1000)
//	OO_Read() - This should only read once, both spectrometers are configured!! So removing from this function - JTH
//	OO_AutoScaleY() - needs to move as well
	SetDataFolder savDF
	Return 0
End


/////////////////////////////////////////////////////////////////////// Spectrometer code ////////////////////////////////

Function OO_Read()
						
	String savDF= GetDataFolder(1)
	SetDataFolder root:OO:GlobalVariables					//Then create globalvariables folder
	Nvar NumSpectrometers, MultiIntTimes, swapped; Svar Spectrometer, Spectrometer_2
	if (cmpstr(Spectrometer,"")==0)		// check spectrometer 1 is connected
		print "connect spectrometer !"
		abort
	endif
	if (NumSpectrometers==2)
		if (cmpstr(Spectrometer_2,"")==0)	// check spectrometer 2 is connected
			print "connect spectrometer 2 !"
			abort
		endif
	endif
	if (MultiIntTimes==0)					// single integration time only
		OO_read_Spectrometer(0)
		
		if (NumSpectrometers==2)
			OO_read_Spectrometer(1)
			
		endif
	elseif (multiIntTimes==1)				// Use the new int times routines
		OO_read_SpectrometerMulti(0)
		if (NumSpectrometers==2)			// If two spectrometers and multiple int times
			OO_read_SpectrometerMulti(1)
		endif
	endif
	
	Dowindow OO_LiveSpectraGraph
	SetDataFolder savDF
	Return 0
End
/////////////////////////////////////////////////////////
Function OO_read_Spectrometer(snum)
	Variable snum		// spectrometer number
	variable mintnum
	String savDF= GetDataFolder(1)
	SetDataFolder root:OO:GlobalVariables					//Then create globalvariables folder
	Nvar numberint,averagedspec, absorbance_checked
	if (snum==0)
		Nvar Refexists = Ref1exists
		Svar Spectrometer
	else
		Nvar Refexists = Ref2exists
		Svar Spectrometer=Spectrometer_2
	endif
	SetDataFolder root:OO:Data:Current					//Then create globalvariables folder
	if (snum==0)
		Wave Spectra,SpectraRaw,Spectrabkgd,Ref
	else
		Wave Spectra=Spectra_2,SpectraRaw=SpectraRaw_2,Spectrabkgd=Spectrabkgd_2,Ref=Ref_2
	endif
//	print snum, NameofWave(SpectraRaw)
	OOIgor_Read(OO_snum(snum),SpectraRaw)
	duplicate/O spectraraw spectrarawtemp					//temporary wave for multiple integrations

	for (mintnum=1;mintnum<numberint;mintnum+=1)		//loop for multiple integrations
		OOIgor_Read(OO_snum(snum),SpectraRaw)
		spectrarawtemp+=spectraraw
	endfor
	spectraraw=spectrarawtemp
	if (averagedspec==1)								//averages if requested
		spectraraw/=numberint
	endif
	if (Refexists ==0)
		Spectra = (SpectraRaw - Spectrabkgd)
	else
	 	Spectra = (SpectraRaw - Spectrabkgd)/(Ref)							//correct if take background before reference
	endif
	 
	
	if (absorbance_checked==1) // if command
		make_absorbance(Spectra, 0)
	else
		make_absorbance(Spectra, -1)	
	endif
	 
	  if (stringmatch(Spectrometer,"USB*")==1)
	 	Spectra[0,1]=Nan		//first two points from USB2000 spectrometer are NaN
	 endif
	 SetDataFolder savDF
	 Return 0
End
///////////////////////////////////////
//    Panel functions
//////////////////////////////////////

// sets the current reference spectrum to the spectrum with "index"
Function OO_SetRef(index)
	variable index
	String newRefPath = "root:OO:Data:Scan"+num2str(index)+":Spectra"
	wave Spectra = root:OO:Data:Scan
	wave Ref = root:OO:Data:Current:Ref
	Nvar Ref1Exists = root:OO:GlobalVariables:Ref1Exists
	Duplicate/O Spectra Ref
	Ref1Exists = 1		//sets ref exists variable to 1 		
End

Function OO_AutoProc(ctrlNameAuto,checked) : CheckBoxControl          		//Graph autoscale check box
	String ctrlNameAuto
	variable checked
	String savDF= GetDataFolder(1)
	SetDataFolder root:OO:GlobalVariables									//Then create globalvariables folder	
	Nvar NumSpectrometers, AutocheckedY, Ymin, Ymax, Ymin_2, Ymax_2, AutocheckedX, Xmin, Xmax, Logged, Swapped,averagedspec
	SetDataFolder root:OO:Data:Current											//Then create globalvariables folder	
	StrSwitch (ctrlNameAuto)	
	
//////////////////////// Graph spectra set variables 
	
	case "AverageButton":
		averagedspec=abs(averagedspec-1)
	break
	case "AutoscaleYButton":
		AutocheckedY=checked
		If (AutocheckedY==1)	
			OO_AutoScaleY()											//Auto-scale live spectra		
		Elseif (AutocheckedY==0)
			Dowindow OO_LiveSpectraGraph; SetAxis left Ymin, Ymax
			if(NumSpectrometers==2)
				Dowindow OO_LiveSpectraGraph; SetAxis right Ymin_2, Ymax_2 
			endif
		Endif
	break
	
	case "AutoscaleXButton":
		AutocheckedX=checked
		If (AutocheckedX==1)	
			OO_AutoScaleX()											//Auto-scale live spectra		
		Elseif (AutocheckedX==0)
			Dowindow OO_LiveSpectraGraph; SetAxis bottom Xmin, Xmax
		Endif
	break
	
	case "Logged_check":
		Logged=checked
		if (Logged==0)													//Normalscale
			ModifyGraph/W=OO_LiveSpectraGraph log(left)=0
			If (AutocheckedY==1)	
				OO_AutoScaleY()											//Auto-scale live spectra		
			Elseif (AutocheckedY==0)
				SetAxis/W=OO_LiveSpectraGraph left Ymin, Ymax
				if (NumSpectrometers==2)
					SetAxis/W=OO_LiveSpectraGraph right Ymin_2, Ymax_2 
				endif
			endif
			if (NumSpectrometers==2)
				ModifyGraph/W=OO_LiveSpectraGraph log(right)=0
			endif
		elseif (Logged==1)													//Log data
			ModifyGraph/W=OO_LiveSpectraGraph log(left)=1
			If (AutocheckedY==1)	
				OO_AutoScaleY()										//Auto-scale live spectra		
			Elseif (AutocheckedY==0)
				SetAxis/W=OO_LiveSpectraGraph left 1, Ymax
			endif
			if (NumSpectrometers==2)
				ModifyGraph/W=OO_LiveSpectraGraph log(right)=1
				if (AutocheckedY==0)
					SetAxis/W=OO_LiveSpectraGraph Right 1, Ymax_2
				endif
			endif
		endif
		break
	case "swap_check":
	//	Swapped=checked
		variable physicalspecs=OOIgor_GetNumSpectrometers()
		if (physicalspecs<2) // check there are spectrometers to swap with!
			Swapped=0
			//checked=0
		break
		endif
	//	print NumSpectrometers
		
		if (NumSpectrometers>1)
		OO_Config(1)			// this does the swap inside it
		endif
		OO_Config(0)			// this does the swap inside it
		
		OO_read() // jth
		OO_AutoScaleY()
		
		break
	case "MultInt_check":
		Nvar MultiIntTimes = root:OO:GlobalVariables:MultiIntTimes
		MultiIntTimes=checked
		if (MultiIntTimes==1)
			OO_UseMultiInt()
		else
			Nvar IntT = root:OO:GlobalVariables:IntT
			OOIgor_SetIntTime(OO_snum(0),IntT*1000)
		endif
		break
		
	case "absorbance_toggle":
		NVAR Absorbance_toggled=root:OO:GlobalVariables:Absorbance_toggled
		SetDataFolder root:OO:Data:Current
		Dowindow OO_LiveSpectraGraph
		if (Absorbance_toggled==1)
		//	print Absorbance_toggled
			Wave Spectra, Spectra_Absorbance, wl_wave
			if (waveexists(Spectra)==1&&waveexists(Spectra_Absorbance)==1)
				RemoveFromGraph Spectra
				AppendToGraph Spectra_Absorbance vs wl_wave
			else
			
			//	print "	"
				Absorbance_toggled=0
			endif
		else
			Wave Spectra, wl_wave, Spectra_Absorbance
			if (waveexists(Spectra)==1&&waveexists(Spectra_Absorbance)==1)
				RemoveFromGraph Spectra_Absorbance
				AppendToGraph Spectra vs wl_wave
			else
				Print "Error: Spectra/Absorbance not found"
			endif
		endif
		
	break
	default:
		Print "ERROR!"; Print ctrlNameAuto; Print checked
		break
	Endswitch 
	SetDataFolder savDF
End

Function OO_AutoScaleY()
	String savDF= GetDataFolder(1)
	Nvar NumSpectrometers=root:OO:GlobalVariables:NumSpectrometers
	Nvar Logged = root:OO:GlobalVariables:Logged
	Variable Spectramin, Spectramax
	Wave Spectra = root:OO:Data:Current:Spectra
	WaveStats/Q Spectra
	Spectramin = V_min; Spectramax = V_max
	if (Logged==1)
		Spectramin = 1
	endif
	SetAxis/W=OO_LiveSpectraGraph left Spectramin,Spectramax 
	if(NumSpectrometers==2)		//auto scale right axis also
		Wave Spectra_2 = root:OO:Data:Current:Spectra_2
		WaveStats/Q Spectra_2
		Spectramin = V_min; Spectramax = V_max
		if (Logged==1)
			Spectramin = 1
		endif
		SetAxis/W=OO_LiveSpectraGraph right Spectramin,Spectramax 
	endif
	SetDataFolder savDF
	Return 0
End 

Function OO_AutoScaleX()											//Replace for each spectrometer
	String savDF= GetDataFolder(1)
	Nvar NumSpectrometers=root:OO:GlobalVariables:NumSpectrometers
	SetDataFolder root:OO:Data:Current								//Then create globalvariables folder	
	Wave wl_wave, wl_wave_2
	Variable Spectramin, Spectramax
	WaveStats/Q wl_wave
	if(NumSpectrometers==2)								///////////// now auto if two spectrometers
		make/O/N = (2048,2) wavetemp
		wavetemp[][0]=wl_wave[p]
		wavetemp[][1]=wl_wave_2[p]
		WaveStats/Q wavetemp
		killwaves wavetemp	
	endif
	Spectramin = V_min; 	Spectramax = V_max
	Dowindow OO_LiveSpectraGraph; SetAxis bottom Spectramin,Spectramax 
	DoUpdate
	SetDataFolder savDF
	Return 0
End 

///////////////////////////////////////
// Live spectra graph functions
//////////////////////////////////////

Function OO_SetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	String savDF= GetDataFolder(1)
	SetDataFolder root:OO:GlobalVariables					//Then create globalvariables folder
	StrSwitch (ctrlName)
		////////////////////////Graph spectra set variables 
		case "Ymin_SetVariable":
			Nvar Ymin, Ymax
			Dowindow OO_LiveSpectraGraph; setaxis left Ymin, Ymax
			break
		case "Ymax_SetVariable":
			Nvar Ymin, Ymax
			Dowindow OO_LiveSpectraGraph; setaxis left Ymin, Ymax
			break
		case "Ymin2_SetVariable":
			Nvar Ymin_2, Ymax_2
			Dowindow OO_LiveSpectraGraph; setaxis right Ymin_2, Ymax_2
			break
		case "Ymax2_SetVariable":
			Nvar Ymin_2, Ymax_2
			Dowindow OO_LiveSpectraGraph; setaxis right Ymin_2, Ymax_2
			break
		case "Xmin_SetVariable":
			Nvar Xmin, Xmax
			Dowindow OO_LiveSpectraGraph; setaxis bottom Xmin, Xmax
			break
		case "Xmax_SetVariable":
			Nvar Xmin, Xmax
			Dowindow OO_LiveSpectraGraph; setaxis bottom Xmin, Xmax
			break
		case "Int__SetVariable":
			Nvar IntT
			OOIgor_SetIntTime(OO_snum(0),IntT*1000)
			break
		case "Int__SetVariable_2":
			Nvar IntT_2
			OOIgor_SetIntTime(OO_snum(1),IntT_2*1000)
			break
		case "ScanTime": 		//variable in kinetics measurements
			Nvar ScanTime
			ScanTime=varNum
			break
		case "TECsetT":
			Nvar TECTemp
			OOIgor_SetTECooler(OO_snum(0),TECTemp)
			break			
		default:
			Print "ERROR!"; Print ctrlname; Print varNum; Print varStr; Print varName
			break
	Endswitch 
	SetDataFolder savDF
End

Function OO_AutoScaleGraph()
	String savDF= GetDataFolder(1)
	SetDataFolder root:OO:GlobalVariables					//Then create globalvariables folder
	Nvar AutocheckedY,AutocheckedX,Ymin,YMax,Xmin,XMax
	If (AutocheckedY==1)										//Auto-scale live spectra		
		OO_AutoScaleY()
	Elseif (AutocheckedY==0)
		Dowindow OO_LiveSpectraGraph; SetAxis left Ymin, Ymax; SetAxis bottom Xmin, Xmax
	Endif
	If (AutocheckedX==1)	
		OO_AutoScaleX()											//Auto-scale live spectra		
	Elseif (AutocheckedX==0)
		Dowindow OO_LiveSpectraGraph; SetAxis bottom Xmin, Xmax
	Endif
	SetDataFolder savDF
	Return 0
End

Function OO_StartButton(theTag)
	String theTag		
	String savDF= GetDataFolder(1)
	SetDataFolder root:OO:GlobalVariables:												//Create global variables in root
	Nvar NumSpectrometers; Svar Spectrometer, Spectrometer_2
	if (cmpstr(Spectrometer,"")==0)
		print "connect spectrometer 1 !"
		abort
	endif
	if (NumSpectrometers==2)
		if (cmpstr(Spectrometer_2,"")==0)
			print "connect spectrometer 2 !"
			abort
		endif
	endif								
	If( cmpstr(theTag,"StartButton")==0 )														//compares name of button to TheTag, The button is renamed each time it is pressed 
		Button $theTag,rename=StopButton,title="Stop"
	//	SetBackground OO_read()
	//	CtrlBackground period=OO_LIVEREFRESH_PERIOD,dialogsOK=1,noBurst=1,start
		CtrlNamedBackground OO_live,period=OO_LIVEREFRESH_PERIOD,burst=0,proc=OO_read_bkgd
		CtrlNamedBackground OO_live,start
	//	print "here"
	Else
		Button $theTag,rename=StartButton,title="Live"
	//	CtrlBackground stop
		CtrlNamedBackground OO_live,stop
	Endif
	SetDataFolder savDF
	Return 0
End

Function OO_read_bkgd(s)
	STRUCT WMBackgroundStruct &s
	OO_read()
	return 0
End

Function OO_SaveSpectra()												
      	String savDF= GetDataFolder(1)
     	SetDataFolder root:OO:GlobalVariables:												//Create global variables in root
	Nvar nextspecindex, NumSpectrometers, numberint, IntT, IntT_2; Svar Spectrometer, Spectrometer_2
	Svar DataWaveName, OneNotePath
	String foldername="Scan"+ num2str(nextspecindex)
	nextspecindex+=1
	
	SetDataFolder root:OO:Data:Current	//Change to right folder
	String/G dataDescription				//Changed all below to this: BS
	dataDescription = DataWaveName
	Print foldername, dataDescription
//	NewDataFolder/O/S $foldername		// previously
	SetDataFolder root:OO:Data:
	DuplicateDataFolder Current, $foldername
// As things aren't coded neatly still need to copy the variables from the Global by hand. this shouldn't be in the global one though.
// THese variables should not have been global
	SetDataFolder $foldername
	Variable/G intT_save = IntT
	Variable/G numSpectrometers_save=NumSpectrometers
		Variable/G int_number = numberint					// number of aquired spectra

	String/G spectrometer_save = Spectrometer
	String/G Description=dataDescription 
	String/G OneNotePath_save=OneNotePath
	if (NumSpectrometers==2)
		Variable/G intT_2_save=IntT_2
		String/G Spectrometer_2_save=Spectrometer_2
	endif		
	SetDataFolder savDF
	Return 0
End


//////Kinetic measurements///////////////////// 
//reads and saves "Number of Spectra" spectra at delay intervals of "delay time"
Function OO_kinetics_button()
			    Nvar ScanTime=root:OO:GlobalVariables:ScanTime
			    Nvar NumSpectra=root:OO:GlobalVariables:NumSpectra
			    Nvar IntT=root:OO:GlobalVariables:IntT
			    variable i
			    string scan_num
			   	 if (IntT>ScanTime*1000) //check integration time is lower than delay time
			   	 print "Integration time larger than delay"
			   	 else
			   		 do	 
			    			    OO_Read()
			    			    OO_SaveSpectra()
			    			    DoUpdate // added to make spectra update 
			    			    i=i+1
			    			    scan_num="spectrum"+num2istr(i)+" recorded"
			    			    Print scan_num
			    			    //Print "scan"$i 
			    			    pauseupdate; sleep/S ScanTime 
			   		while (i<NumSpectra)
			   		print "kinetic measurement finished"
			   	Endif
 End

Window OO_LiveSpectraGraph() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:OO:Data:Current:
	Display /W=(204,61.25,717.75,425) Spectra vs wl_wave
	SetDataFolder fldrSav0
	ModifyGraph cbRGB=(48896,59904,65280)
	ModifyGraph mirror=2
	ModifyGraph lblMargin(left)=5
	ModifyGraph lblLatPos(left)=-1
	Label left "Intensity"
	Label bottom "Wavelength (nm)"
	SetAxis left -5.875,614.27490234375
	SetAxis bottom 450,700
	Cursor/P A Spectra 435
	ShowInfo
	ControlBar 154
	Button reintiate,pos={5,5},size={18,18},proc=OO_ButtonProc,title="\\W619"
	Button reintiate,fSize=14,fColor=(0,65280,0),valueColor=(0,52224,26368)
	Button StartButton,pos={182,106},size={50,20},proc=OO_StartButton,title="Live"
	CheckBox AutoscaleYButton,pos={533,110},size={75,14},proc=OO_AutoProc,title="Autoscale Y"
	CheckBox AutoscaleYButton,value= 1
	CheckBox AverageButton,pos={188,26},size={58,14},proc=OO_AutoProc,title="Average"
	CheckBox AverageButton,value= 0
	SetVariable Int__Setnumb,pos={139,5},size={107,16},title="Number of int"
	SetVariable Int__Setnumb,limits={1,inf,1},value= root:OO:GlobalVariables:numberint
	Button Read_Button,pos={231,106},size={50,20},proc=OO_ButtonProc,title="Read"
	Button kinetics_Button,pos={7,107},size={50,20},proc=OO_ButtonProc,title="kinetics"
	Button button101,pos={127,2},size={50,20},disable=1
	SetVariable Int__SetVariable,pos={63,47},size={88,16},bodyWidth=50,proc=OO_SetVarProc,title="Int (ms)"
	SetVariable Int__SetVariable,limits={3,inf,1},value= root:OO:GlobalVariables:IntT
	Button Zero_Background_Button,pos={252,2},size={80,20},proc=OO_ButtonProc,title="Zero Bkgd 1"
	SetVariable Ymin_SetVariable,pos={396,48},size={130,16},proc=OO_SetVarProc,title="Y axis 1 min"
	SetVariable Ymin_SetVariable,value= root:OO:GlobalVariables:Ymin
	SetVariable Ymax_SetVariable,pos={394,68},size={132,16},proc=OO_SetVarProc,title="Y axis 1 max"
	SetVariable Ymax_SetVariable,value= root:OO:GlobalVariables:Ymax
	Button Store_Background_Button,pos={252,22},size={80,20},proc=OO_ButtonProc,title="Store Bkgd 1"
	Button Save_Spectra_Button,pos={180,82},size={80,20},proc=OO_ButtonProc,title="Save Spectra"
	Button Store_Ref_Button,pos={336,21},size={80,20},proc=OO_ButtonProc,title="Store Ref 1"
	Button Zero_Ref_Button,pos={336,1},size={80,20},proc=OO_ButtonProc,title="Zero Ref 1"
	Button Set_Ref_Button,pos={425,2},size={88,20},proc=OO_ButtonProc,title="Set Ref 1"
	SetVariable NumSpectra1,pos={428,24},size={84,16},bodyWidth=35,title="Ref index"
	SetVariable NumSpectra1,limits={0,inf,1},value= root:OO:GlobalVariables:RefIndex,live= 1
	SetVariable Data_save_name,pos={177,45},size={203,16},bodyWidth=120,title="Scan description"
	SetVariable Data_save_name,value= root:OO:GlobalVariables:DataWaveName
	SetVariable Xmin_SetVariable,pos={406,87},size={120,16},proc=OO_SetVarProc,title="X axis min"
	SetVariable Xmin_SetVariable,value= root:OO:GlobalVariables:Xmin
	SetVariable Xmax_SetVariable,pos={404,107},size={122,16},proc=OO_SetVarProc,title="X axis max"
	SetVariable Xmax_SetVariable,value= root:OO:GlobalVariables:Xmax
	CheckBox AutoscaleXButton,pos={534,90},size={75,14},proc=OO_AutoProc,title="Autoscale X"
	CheckBox AutoscaleXButton,value= 1
	Button Save_data_folders,pos={285,106},size={73,20},proc=OO_ButtonProc,title="Save folders"
	Button Save_data_folders,labelBack=(65280,0,0),fColor=(65280,21760,0)
	PopupMenu Multiple_Spectrometers_popup,pos={26,3},size={116,21},proc=OO_PopMenuProc,title="Spectrometers"
	PopupMenu Multiple_Spectrometers_popup,mode=1,popvalue="1",value= #"\"1\""
	Button Init_spectrometer_Button_2,pos={181,77},size={50,20},disable=1,proc=OO_ButtonProc,title="Init #2"
	SetVariable Int__SetVariable_2,pos={47,83},size={104,16},bodyWidth=50,disable=1,proc=OO_SetVarProc,title="Int #2 (ms)"
	SetVariable Int__SetVariable_2,limits={3,inf,1},value= root:OO:GlobalVariables:IntT_2
	SetVariable ScanTime,pos={64,112},size={107,16},bodyWidth=40,proc=OO_SetVarProc,title="Delay time (s)"
	SetVariable ScanTime,limits={1,inf,1},value= root:OO:GlobalVariables:ScanTime,live= 1
	SetVariable NumSpectra,pos={38,132},size={133,16},bodyWidth=40,title="Number of Spectra"
	SetVariable NumSpectra,limits={1,inf,1},value= root:OO:GlobalVariables:NumSpectra,live= 1
	SetVariable Ymin2_SetVariable,pos={532,50},size={130,16},disable=1,proc=OO_SetVarProc,title="Y axis 2 min"
	SetVariable Ymin2_SetVariable,value= root:OO:GlobalVariables:Ymin_2
	SetVariable Ymax2_SetVariable,pos={530,69},size={132,16},disable=1,proc=OO_SetVarProc,title="Y axis 2 max"
	SetVariable Ymax2_SetVariable,value= root:OO:GlobalVariables:Ymax_2
	Button Zero_Background2_Button,pos={418,2},size={80,20},disable=1,proc=OO_ButtonProc,title="Zero Bkgd 2"
	Button Store_Background2_Button,pos={418,21},size={80,20},disable=1,proc=OO_ButtonProc,title="Store Bkgd 2"
	Button Zero_Ref2_Button,pos={499,1},size={80,20},disable=1,proc=OO_ButtonProc,title="Zero Ref 2"
	Button Store_Ref2_Button,pos={500,22},size={80,20},disable=1,proc=OO_ButtonProc,title="Store Ref 2"
	CheckBox Logged_check,pos={623,110},size={36,14},proc=OO_AutoProc,title="Log"
	CheckBox Logged_check,labelBack=(65535,65535,65535),value= 0
	SetVariable OneNotePath,pos={188,64},size={192,16},bodyWidth=120,proc=OO_SetVarProc,title="OneNote Path"
	SetVariable OneNotePath,value= root:OO:GlobalVariables:OneNotePath
	Button AutoIntTimesButton,pos={589,29},size={70,21},proc=OO_ButtonProc,title="Auto Times"
	TitleBox title0,pos={31,29},size={53,13},fSize=12,frame=0,fStyle=1
	TitleBox title0,variable= root:OO:GlobalVariables:Spectrometer
	TitleBox title1,pos={32,68},size={63,13},disable=1,frame=0,fStyle=1
	TitleBox title1,variable= root:OO:GlobalVariables:Spectrometer_2
	CheckBox swap_check,pos={116,28},size={43,14},proc=OO_AutoProc,title="swap"
	CheckBox swap_check,variable= root:OO:GlobalVariables:Swapped
	SetVariable setvar0,pos={265,83},size={70,16},title="Spec:"
	SetVariable setvar0,limits={1,inf,1},value= root:OO:GlobalVariables:NextSpecIndex
	CheckBox MultInt_check,pos={588,8},size={76,14},proc=OO_AutoProc,title="Multiple IntT"
	CheckBox MultInt_check,value= 0
	SetVariable TECsetT,pos={543,131},size={85,16},proc=OO_SetVarProc,title="TEC T="
	SetVariable TECsetT,value= root:OO:GlobalVariables:TECtemp
	Button TECgetT,pos={633,131},size={40,16},proc=OO_ButtonProc,title="curr T"
	CheckBox absorbance_check,pos={181,133},size={146,14},title="Create absorbance spectra"
	CheckBox absorbance_check,variable= root:OO:GlobalVariables:Absorbance_checked
	CheckBox absorbance_toggle,pos={333,133},size={110,14},proc=OO_AutoProc,title="Toggle absorbance"
	CheckBox absorbance_toggle,variable= root:OO:GlobalVariables:Absorbance_toggled
	Button Save_data_folders_txt,pos={359,106},size={32,20},proc=OO_ButtonProc,title="to .txt"
	Button Save_data_folders_txt,fColor=(65535,65535,65535)
	SetDrawLayer UserFront
	DrawRect 0.346076458752515,-0.479289940828402,-0.116700201207243,-0.686390532544379
	DrawRect -0.114688128772636,-0.680473372781065,0.340040241448692,-0.467455621301775
	DrawRect 0.303547171352991,-0.49112426035503,0.375981778998866,-0.313609467455621
	DrawRect -0.112676056338028,-0.674556213017751,0.354124748490946,-0.431952662721893
	DrawRect 0.323667895699068,-0.431952662721893,0.32165582326446,-0.473372781065089
	DrawText -0.0930656934306569,-0.409774436090226,"Here"
EndMacro
  
Function OO_ButtonProc(ctrlName) : ButtonControl
	String ctrlName
	StrSwitch (ctrlName) //////////////////////////////Spectra graph buttons
		case "reintiate":
			OO_InitialiseProgram()	
		break
		
		
			case "kinetics_Button": //saves "Number of Spectra" spectra at delay intervals of "delay time"
			OO_kinetics_button()
			break
			case "Read_Button":
			OO_Read()			
			break
		case "Zero_Background_Button":
			wave Spectrabkgd=root:OO:Data:Current:Spectrabkgd
			Spectrabkgd = 0
			Nvar MultiIntTimes = root:OO:GlobalVariables:MultiIntTimes
			if (MultiIntTimes == 1)
				wave SpectrabackgroundMulti =root:OO:Data:Current:SpectraBackgroundMulti
				SpectrabackgroundMulti = 0
			endif	
			break
		case "Zero_Background2_Button":
			wave Spectrabkgd_2=root:OO:Data:Current:Spectrabkgd_2
			Spectrabkgd_2 = 0
			Nvar MultiIntTimes = root:OO:GlobalVariables:MultiIntTimes
			if (MultiIntTimes == 1)
				wave SpectrabackgroundMulti_2 =root:OO:Data:Current:SpectraBackgroundMulti_2 		//Multiple wave background...
				SpectrabackgroundMulti_2 = 0
			endif		
			break
		case "Store_Background_Button":
			OO_Read()	
			//Changed this to take background from raw spectra rather than processed
			wave SpectraRaw=root:OO:Data:Current:SpectraRaw
			wave Spectrabkgd=root:OO:Data:Current:Spectrabkgd
			Duplicate/O SpectraRaw Spectrabkgd	
			Nvar MultiIntTimes = root:OO:GlobalVariables:MultiIntTimes
			if (MultiIntTimes == 1)
				wave SpectraRawMulti=root:OO:Data:Current:SpectraRawMulti				//do this for multiple 	
				wave SpectrabackgroundMulti=root:OO:Data:Current:SpectrabackgroundMulti
				Duplicate/O SpectraRawMulti SpectrabackgroundMulti
			endif
			break
		case "Store_Background2_Button":
			OO_Read()	
			//Changed this to take background from raw spectra rather than processed
			wave SpectraRaw_2=root:OO:Data:Current:SpectraRaw_2
			wave Spectrabkgd_2=root:OO:Data:Current:Spectrabkgd_2
			Duplicate/o SpectraRaw_2 Spectrabkgd_2	
			Nvar MultiIntTimes = root:OO:GlobalVariables:MultiIntTimes
			if (MultiIntTimes == 1)
				wave SpectraRawMulti_2=root:OO:Data:Current:SpectraRawMulti_2		//do this for multiple 	
				wave SpectrabackgroundMulti_2=root:OO:Data:Current:SpectrabackgroundMulti_2
				Duplicate/O SpectraRawMulti_2 SpectrabackgroundMulti_2
			endif
			break
		case "Store_Ref_Button":
			OO_Read()				
			wave Spectra = root:OO:Data:Current:Spectra
			wave Ref = root:OO:Data:Current:Ref
			Nvar Ref1Exists = root:OO:GlobalVariables:Ref1Exists
			Duplicate/O Spectra Ref
			Ref1Exists = 1		//sets ref exists variable to 1 		
			Nvar MultiIntTimes = root:OO:GlobalVariables:MultiIntTimes
			if (MultiIntTimes == 1)
				wave SpectraMulti=root:OO:Data:Current:SpectraMulti				//do this for multiple
				wave SpectraRefMulti=root:OO:Data:Current:SpectraRefMulti
				Duplicate/O SpectraMulti SpectraRefMulti			
			endif
			break
		case "Store_Ref2_Button":
			OO_Read()	
			wave Spectra_2=root:OO:Data:Current:Spectra_2
			wave Ref_2=root:OO:Data:Current:Ref_2
			Nvar Ref2Exists=root:OO:GlobalVariables:Ref2Exists
			Duplicate/O Spectra_2 Ref_2
			Ref2Exists = 1		//sets ref exists variable to 1
			Nvar MultiIntTimes = root:OO:GlobalVariables:MultiIntTimes
			if (MultiIntTimes == 1)
				wave SpectraMulti_2=root:OO:Data:Current:SpectraMulti_2			//do this for multiple 	
				wave SpectraRefMulti_2=root:OO:Data:Current:SpectraRefMulti_2
				Duplicate/O SpectraMulti_2 SpectraRefMulti_2
			endif
			break
		case "Zero_Ref_Button":
			Nvar Ref1Exists=root:OO:GlobalVariables:Ref1Exists
			Ref1Exists = 0		//sets ref exists variable to 1
			wave Ref=root:OO:Data:Current:Ref
			Ref=0
			Nvar MultiIntTimes = root:OO:GlobalVariables:MultiIntTimes
			if (MultiIntTimes == 1)
				wave RefMulti=root:OO:Data:Current:SpectraRefMulti			//MultipleRefbits
				RefMulti=0
			endif
			break
		case "Zero_Ref2_Button":
			Nvar Ref2Exists=root:OO:GlobalVariables:Ref2Exists
			Ref2Exists = 0		//sets ref exists variable to 1
			wave Ref_2=root:OO:Data:Current:Ref_2
			Ref_2=0
			Nvar MultiIntTimes = root:OO:GlobalVariables:MultiIntTimes
			if (MultiIntTimes == 1)
				wave RefMulti_2=root:OO:Data:Current:SpectraRefMulti_2			//MultipleRefbits
				RefMulti_2=0
			endif
			break
		case "Set_Ref_Button":
			Nvar refIndex=root:OO:GlobalVariables:RefIndex
			if (RefIndex > 0)			//is reference spectrum available
				String newRefPath = "root:OO:Data:Scan"+num2str(refIndex)+":Spectra"
				wave Spectra = $newRefPath
				wave Ref = root:OO:Data:Current:Ref
				Nvar Ref1Exists = root:OO:GlobalVariables:Ref1Exists
				Duplicate/O Spectra Ref
				Ref1Exists = 1		//sets ref exists variable to 1 	
			endif
			break
		case "Save_Spectra_Button":  	
			OO_SaveSpectra()
			break
		case "save_data_folders":
			SetDataFolder root:OO:Data:	
			SaveData/I/T/R 									
			break
		case "Save_data_folders_txt":
			ExportTxt()		
			break			
		case "AutoIntTimesButton":
			Nvar NumSpectrometers= root:OO:GlobalVariables:NumSpectrometers //keeps track if you're dealing with one or two spectrometers.
//JJB			OO_AutoIntTime()
			//Print "I I did got here!"
			Print NumSpectrometers 
			if (NumSpectrometers==2)
				//Print "And I even got here!"
				//OO_AutoIntTime_2() ///To AutoIntTimes for second spectrometer
			endif
			break
		case "TECGetT":
			Print "TEC temperature = ",OOIgor_ReadTECooler(0)		
			break
		default:
			Print "ERROR!"; Print ctrlname
			break
	Endswitch 
	Return 0
End

Function OO_PopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	String savDF= GetDataFolder(1)
	SetDataFolder root:OO:GlobalVariables:					//Then create globalvariables folder
	Nvar NumSpectrometers, Swapped; Svar Spectrometer_2
			
	StrSwitch (ctrlName)
		case "Multiple_Spectrometers_popup":           	//pass button name
			NumSpectrometers=popNum
			if (NumSpectrometers==1)					//1 spectrometer
				modifycontrol Int__SetVariable_2 disable=1	
				modifycontrol Ymin2_SetVariable disable=1
				modifycontrol Ymax2_SetVariable disable=1
				modifycontrol Zero_Background2_Button disable=1
				modifycontrol store_Background2_Button disable = 1
				modifycontrol Zero_Ref2_Button disable = 1
				modifycontrol store_Ref2_Button disable=1
				TitleBox title1 disable=1
				RemoveFromGraph/Z/W=OO_LivespectraGraph Spectra_2			//remove spectra 2 if present
				ModifyGraph/W = OO_LiveSpectraGraph mirror=2
				SetDataFolder root:OO:Data:Current	
				KillWaves/Z Spectra_2, Spectrabkgd_2, SpectrabkgdTemp_2, wl_wave_2, Ref_2, RefTemp_2, SpectraRaw_2 //Referenc wave= eg mirror reflectivity	
				OO_Config(0)
				OO_Read() // jth
				OO_AutoScaleY()
				Spectrometer_2 = ""
			elseif (NumSpectrometers==2)				//append second spectrometer
				modifycontrol Int__SetVariable_2 disable=0
				modifycontrol Ymin2_SetVariable disable=0
				modifycontrol Ymax2_SetVariable disable=0
				modifycontrol Zero_Background2_Button disable=0
				modifycontrol store_Background2_Button disable = 0
				modifycontrol Zero_Ref2_Button disable = 0
				modifycontrol store_Ref2_Button disable=0
				TitleBox title1 disable=0
				Swapped = 0							// change back from swapped state
				SetDataFolder root:OO:Data:Current:
				Make/O/N=1024 Spectra_2,wl_wave_2
				wave Spectra_2=root:OO:Data:Current:Spectra_2
				wave wl_wave_2=root:OO:Data:Current:wl_wave_2
				ModifyGraph/W = OO_LiveSpectraGraph mirror(left)=0
				AppendToGraph/R/W = OO_LiveSpectraGraph Spectra_2 vs wl_wave_2	//append if not present	
				ModifyGraph/W = OO_LiveSpectraGraph rgb(Spectra_2)=(0,0,52224) 	//make in blue
				OO_Config(1)
				OO_Config(0)
				OO_Read() // jth
				OO_AutoScaleY()
			endif
			break
		default:
			Print "ERROR!"; Print ctrlname; Print popnum; print popstr
			break
	Endswitch
	SetDataFolder savDF
	Return 0
End


//////////////////////////////  Multiple integration times code: ///////////////////////////////////////////

Function OO_UseMultiInt()
	Nvar MultiIntTimes= root:OO:GlobalVariables:MultiIntTimes	//variable that defines whether you're in single int mode or not
	Nvar IntT =root:OO:GlobalVariables:IntT						//Integration time that was being used in single int time mode
	Nvar IntT_2 =root:OO:GlobalVariables:IntT_2					// Same for second spectrometer
	MultiIntTimes = 1											//Switch to mult int time mode
	String savDF= GetDataFolder(1)
	SetDataFolder root:OO:GlobalVariables:	
	Svar Spectrometer; Nvar NumSpectrometers	
	
	SetDataFolder root:OO:Data:Current:
	if (Exists("MultiIntIntervals")!=1)
	  Make/N=(10,4) MultiIntIntervals=0
	  Wave MultiIntIntervals, wl_wave
	  MultiIntIntervals[0][0] = wavemin(wl_wave) 	///set to minimum wl
	  MultiIntIntervals[0][1] = wavemax(wl_wave) 	//set to maximum wl
	  MultiIntIntervals[0][2] = IntT
	  MultiIntIntervals[0][3] = 0
	  Edit MultiIntIntervals
//	Make/O/N=(10,4) MultiIntIntervals= {{200,300,500,600,0,0,0,0,0,0},{300,500,600,800,0,0,0,0,0,0}, {40,20,25,40,0,0,0,0,0,0},{0,0,0,0,0,0,0,0,0,0}}
	  Make/O/N=(10) DoneInterval = 0
	  Variable npt = numpnts(wl_wave)	
	  Make/O/N=(npt,10) SpectraRawMulti, SpectraBackgroundMulti, SpectraRefMulti, SpectraMulti
	endif
	if(NumSpectrometers==2)
		if (Exists("MultiIntIntervals_2")!=1)
	 		Make/N=(10,4) MultiIntIntervals_2=0
			Wave MultiIntIntervals_2, wl_wave_2
			MultiIntIntervals_2[0][0] = wavemin(wl_wave_2) 	///set to minimum wl
			MultiIntIntervals_2[0][1] = wavemax(wl_wave_2) 	//set to maximum wl
			MultiIntIntervals_2[0][2] = IntT_2
			MultiIntIntervals_2[0][3] =0
			Edit MultiIntIntervals_2
			Variable npt2 = numpnts(wl_wave_2)	
//		Make/O/N=(10,4) MultiIntIntervals_2= {{200,300,500,600,0,0,0,0,0,0},{300,500,600,800,0,0,0,0,0,0}, {40,20,25,40,0,0,0,0,0,0},{0,0,0,0,0,0,0,0,0,0}}
			Make/O/N=(10) DoneInterval_2 =0
			Make/O/N=(npt2,10) SpectraRawMulti_2, SpectraBackgroundMulti_2, SpectraRefMulti_2, SpectraMulti_2
		endif
	endif	
	SetDataFolder savDF
end 

Function OO_read_SpectrometerMulti(snum)
	Variable snum
	Variable mintnum   
	Nvar numberint,averagedspec  
	String savDF= GetDataFolder(1)
	SetDataFolder root:OO:GlobalVariables			
	Nvar IntT,Ref1exists, Logged; Svar Spectrometer
	SetDataFolder root:OO:Data:Current
	if (OO_snum(snum)==0)				
		Wave Spectra,SpectraRaw,Spectrabkgd,Ref,refcurve, wl_wave
		Wave MultiIntIntervals, DoneInterval, SpectraRawMulti, SpectraBackgroundMulti, SpectraRefMulti, SpectraMulti		///Multiple integration times spectra waves
	else
		Wave MultiIntIntervals=MultiIntIntervals_2, DoneInterval=DoneInterval_2, SpectraRawMulti=SpectraRawMulti_2, SpectraBackgroundMulti=SpectraBackgroundMulti_2, SpectraRefMulti=SpectraRefMulti_2, SpectraMulti=SpectraMulti_2		///Multiple integration times spectra waves
		if (OO_snum(0)==1)		// if inverting so that second spectrometer acting as primary
			Wave Spectra,SpectraRaw,Spectrabkgd,Ref,refcurve, wl_wave
		else
			Wave Spectra=Spectra_2,SpectraRaw=SpectraRaw_2,Spectrabkgd=Spectrabkgd_2,Ref=Ref_2, wl_wave=wl_wave_2
		endif
	endif
	Variable ii=0,jj, intTmax
	DoneInterval=MultiIntIntervals[p][2]; intTmax = WaveMax(DoneInterval)	// finds longest integration time
	DoneInterval=0
	do												// Looping over intervals
		if (DoneInterval[ii]==0) 							// also if the interval has not already been done
			OOIgor_SetIntTime(OO_snum(snum), MultiIntIntervals[ii][2]*1000)
			
			OOIgor_Read(OO_snum(snum),SpectraRaw)
	              duplicate/O spectraraw spectrarawtemp					//temporary wave for multiple integrations
			
			for (mintnum=1;mintnum<numberint;mintnum+=1)		 
			   OOIgor_Read(OO_snum(snum), SpectraRaw)			//Take spectra
			   spectrarawtemp+=spectraraw
	                endfor
	
	spectraraw=spectrarawtemp
	if (averagedspec==1)								//averages if requested
		spectraraw/=numberint
	endif
			
			
			if (stringmatch(Spectrometer,"USB*")==1)
	 			SpectraRaw[0,1]=Nan					//first two points from USB2000 spectrometer are NaN
	 		endif
//			Print ii , MultiIntIntervals[ii][2]
			SpectraRawMulti[][ii] = SpectraRaw[p]		// assign the Spectra taken for the the appropriate interval i in multiwave
// Apply references and background 
			if (Ref1exists==0)							// does a reference exist?
				SpectraMulti[][ii] = (SpectraRawMulti[p][ii] - SpectraBackgroundMulti[p][ii]) 	//if no just subtract appropriate background
	 			SpectraMulti[][ii]/=MultiIntIntervals[ii][2]/intTmax		//remove to not normalize by int time cf 100ms
	 		else
	 			SpectraMulti[][ii] = (SpectraRawMulti[p][ii] - SpectraBackgroundMulti[p][ii])/(SpectraRefMulti[p][ii])				// if so take background and  reference (ref is corrected for backgroun!)
	 			SpectraMulti[][ii]/=MultiIntIntervals[ii][2]/intTmax		//remove to not normalize by int time
	 		endif			
			DoneInterval[ii]=1							// This interval has been done
			jj=0
			do										// check if other intervals have same integration time
				if (MultiIntIntervals[ii][2]==MultiIntIntervals[jj][2])		//Also mark has done any other intervals with same integration time as this....
					DoneInterval[jj]=1
					MultiIntIntervals[jj][3] = ii		//Mark the interval whose settings are used...
				endif
				jj += 1
			while (MultiIntIntervals[jj][0]!=0)			// if  available intervals wavelength is zero (There must be one zero)
		endif	
		ii += 1
	while(MultiIntIntervals[ii][0]!=0)				// stop if  available intervals wavelength is zero (There must be one zero)

//	After taking all spectra the "collapsed version" according to the intervals should be saved to the usual "single time" spectra.
	ii=0 										// index for intervals
	Variable jmin, jmax						// jmin (jmax) = low (high) index for wavelength of interval
	FindLevel/Q wl_wave, MultiIntIntervals[0][0]	// find initial jmin
	jmin = V_LevelX
	Spectra[,jmin-1] =NaN						// outside intervals set to NaN
//	spectraraw[,jmin-1] = NaN; spectrabkgd[,jmin-1] =NaN; ref[,jmin-1] =NaN
	jmax=jmin+1
	do										// for each interval need to assign appropriate wavelenght range spectra
		FindLevel/Q wl_wave,MultiIntIntervals[ii][1]	// find jmax for this interval
		jmax = V_LevelX
		Spectraraw[jmin,jmax] = SpectraRawMulti[p][MultiIntIntervals[ii][3]]
		Spectra[jmin,jmax] = SpectraMulti[p][MultiIntIntervals[ii][3]]
		Spectrabkgd[jmin,jmax] =SpectraBackgroundMulti[p][MultiIntIntervals[ii][3]]
		Ref[jmin,jmax] = SpectraRefMulti[p][MultiIntIntervals[ii][3]]
		jmin=jmax+1
		ii += 1
	while (MultiIntIntervals[ii][0]!=0)				// until reach last interval
	Spectra[jmax,] =NaN						// outside intervals set to NaN
	//spectraraw[jmax,] = NaN; spectrabkgd[jmax, ] =NaN; ref[jmax,] =NaN
	SetDataFolder savDF
	Return 0
End


//
//function OO_AutoIntTime()
//	//Chooses the intervals and integration times automatically
//	String savDF= GetDataFolder(1)
//	
//	////Variables
//	Variable maxleftintervals = 2 			//max number of  divisions on the low wavelenght side
//	Variable maxrightintervals = 2			//max number of divisions on the high wavelength side
//	
//	Variable maxcounts =3900					//stores the top counts of the spectra
//	Variable threshold =0.20				// fraction of maxcounts that sets level for increase   					
//	Variable threshold_level = maxcounts*threshold // actual level
//	Variable ininterval = 1  						//flag to check if we are still in the interval we should be
//	
//	//Waves
//	SetDataFolder  root:OO:Data:Current
//	Wave SpectraRaw,Spectrabkgd
//	Wave MultiIntIntervals
//	Wave wl_wave
//	Duplicate/O SpectraRaw SpectraTemp
//	Duplicate/O MultiIntIntervals MultiIntIntervalsTemp
//	wave SpectrabackgroundMulti =root:OO:Data:Current:SpectraBackgroundMulti
//	wave SpectraRawMulti=root:OO:Data:Current:SpectraRawMulti
//	///Main rountine
//	Print "Auto Integration times routine"
//	
//	
//	//Take background with current settings
//	Spectrabkgd=0
//	SpectrabackgroundMulti =0
//	//WARN USER ABOUT BACKGROUND /AUTO SWITHC SHUTTER HERE
//	Print  "Goint to take background, please cover."
////	Shutter_Close(1)
//	Sleep/S 2
//		
//	OO_read()
//			
//	Duplicate/o SpectraRaw Spectrabkgd	
//	Duplicate/o SpectraRawMulti SpectrabackgroundMulti
//		
//	///Read NEW SPECTRA
//	//WARN USER ABOUT NORMAL READING /AUTO SHUTTER HERE
//	Print  "Goint to take normal spectra, please remove cover."
////	Shutter_Open(1)
//	Sleep/S 2
//		
//	
//	//Take spectra with current settings
//	OO_read()
//	
//	//Take maximum counts of usual spectra minus background 
//	SpectraTemp = SpectraRaw-Spectrabkgd
//	maxcounts= wavemax(SpectraTemp)
//	threshold_level = maxcounts*threshold
//	//Print maxcounts, threshold_level
//	
//	
//	//Detect saturation
//	//COULD AUTOMATE THIS BUT DECIDED THAT PEOPLE SHOULD THINK AT LEAST A BIT...
//	If (maxcounts>= 3900) 
//		Print "Saturation! Please check initial integration time." 
//		///Abort // might be annyoing if people don't get about centre... so removing
//	endif 	
//	
//	//Left side adjusments
//	Variable jmin, jmax
//	Variable jmin_wl, jmax_wl
//	Variable i,j
//	Variable pass
//	pass=0
//	
//	do	//Main loopb
//		pass=pass+1
//		Print "Left hand side pass number ", pass
//		jmin_wl= MultiIntIntervals[0][0]	//always work with left most interval
//		jmax_wl= MultiIntIntervals[0][1]
//	
//		//Print jmin_wl, jmax_wl
//		Duplicate/O MultiIntIntervals MultiIntIntervalsTemp
//		j=0
//		
//		do
//		//check if current point is higher than threshold
//			//Print wl_wave[j], jmax_wl
//			if (wl_wave[j]>= jmax_wl)
//				Print "No change needed"
//				
//				//NEED FLAG
//				ininterval=0
//				//Abort ///FOR NOW CHANGE TO FLAG AND OUT OF LOOP
//			endif
//	
//			if (SpectraTemp[j]>=threshold_level)
//				//if so cut set that as high end of new intervall
//				Print "Updating intervals"
//				
//				///Push intervals up		
//				MultiIntIntervals[1,][] = MultiIntIntervalsTemp[p-1][q]
//				MultiIntIntervals[0][1] = wl_wave[j]
//				MultiIntIntervals[1][0] = wl_wave[j]
//				MultiIntIntervals[0][2] =  MultiIntIntervals[0][2]/threshold
//				break
//			endif
//			j=j+1
//		while(ininterval==1)
//		
//		///ZERO BACKGROUND
//		Spectrabkgd=0
//		SpectrabackgroundMulti =0
//		///TAKE BACKGROND WITH NEW SETTINGS
//		
//		//WARN USER ABOUT BACKGROUND /AUTO SWITHC SHUTTER HERE
//		Print  "Goint to take background, please cover."
////		Shutter_Close(1)
//		Sleep/S 5
//		
//
//		OO_read()
//			
//		Duplicate/o SpectraRaw Spectrabkgd	
//		Duplicate/o SpectraRawMulti SpectrabackgroundMulti
//		
//		///Read NEW SPECTRA
//		//WARN USER ABOUT NORMAL READING /AUTO SHUTTER HERE
//		Print  "Goint to take normal spectra, please remove cover."
////		Shutter_Open(1)
//		Sleep/S 5
//		
//		OO_read()
//		SpectraTemp = SpectraRaw-Spectrabkgd
//		
//	while (pass<maxleftintervals)
//	
//	
//	
//	//Right side adjustments
//	///ERrr do the same for right side?
//		Variable lastinterval 	// keeps track of number of intervals.
//		
//		Print "Adjusting right side of spectra now" 
//		//find right most interval
//		lastinterval=-1
//		do
//			lastinterval+=1
//		while (MultiIntIntervals[lastinterval][0]!=0)
//		lastinterval-=1
//		
//		Print "Last Interval", lastinterval
//		
//		pass=0
//		do	//Main loop
//			pass=pass+1
//			Print "Right hand side pass number ", pass
//			
//			jmin_wl= MultiIntIntervals[lastinterval][0]	//always work with right most interval
//			jmax_wl= MultiIntIntervals[lastinterval][1]
//			
//			//Print jmin_wl, jmax_wl
//			Duplicate/O MultiIntIntervals MultiIntIntervalsTemp
//			
//			//STAR FROM LAST POINT
//			j=DimSize(root:OO:Data:Current:wl_wave, 0 )-1
//			do
//			//check if current point is higher than threshold
//				//Print wl_wave[j], jmin_wl
//				if (wl_wave[j]<= jmin_wl)
//					Print "No change needed"
//					//NEED FLAG
//					ininterval = 0
//					//Abort ///FOR NOW CHANGE TO FLAG AND OUT OF LOOP
//				endif
//	
//				if (SpectraTemp[j]>=threshold_level)
//					//if so cut set that as high end of new intervall
//					Print "Updating intervals"
//				
//					///Add interval to the end		
//					lastinterval=lastinterval+1
//					MultiIntIntervals[lastinterval][1] = MultiIntIntervalsTemp[lastinterval-1][1]
//					MultiIntIntervals[lastinterval][0] = wl_wave[j]
//					MultiIntIntervals[lastinterval-1][1] = wl_wave[j]
//					MultiIntIntervals[lastinterval][2] =  MultiIntIntervals[lastinterval-1][2]/threshold
//					break
//				endif
//				j=j-1
//			while(1)
//		
//			///ZERO BACKGROUND
//			Spectrabkgd=0
//			SpectrabackgroundMulti =0
//			///TAKE BACKGROND WITH NEW SETTINGS
//		
//			//WARN USER ABOUT BACKGROUND /AUTO SWITHC SHUTTER HERE
//			Print  "Goint to take background, please cover."
////			Shutter_Close(1)
//			Sleep/S 5
//		
//			OO_read()
//			
//			Duplicate/o SpectraRaw Spectrabkgd	
//			Duplicate/o SpectraRawMulti SpectrabackgroundMulti
//		
//			///Read NEW SPECTRA
//			//WARN USER ABOUT NORMAL READING /AUTO SHUTTER HERE
//			Print  "Goint to take normal spectra, please remove cover."
////			Shutter_Open(1)
//			Sleep/S 5
//		
//			OO_read()
//			SpectraTemp = SpectraRaw-Spectrabkgd
//		
//		while (pass<maxrightintervals)	
//	
//	
//	
//	SetDataFolder savDF
//end
//
//function OO_AutoIntTime_2()
//	//AGAIN THIS IS A HORRIBLE DUPLICATION OF CODE - FOLLOWING EXISTING SCHEME, BUT SHOULD CHANGE 
//	//IN FUTURE
//	
//	Print "Auto picking times for second spectrometer"
//	
//	//Chooses the intervals and integration times automatically for second spectrometer
//	
//	String savDF= GetDataFolder(1)
//	
//	////Variables
//	Variable maxleftintervals_2 = 2 			//max number of  divisions on the low wavelenght side
//	Variable maxrightintervals_2 = 2			//max number of divisions on the high wavelength side
//	
//	Variable maxcounts_2 =3900					//stores the top counts of the spectra
//	Variable threshold_2 =0.20				// fraction of maxcounts that sets level for increase   					
//	Variable threshold_level_2 = maxcounts_2*threshold_2 // actual level
//	
//	Variable ininterval = 1  						//flag to check if we are still in the interval we should be
//	
//	//Waves
//	SetDataFolder  root:OO:Data:Current
//	Wave SpectraRaw_2,Spectrabkgd_2
//	Wave MultiIntIntervals_2
//	Wave wl_wave_2
//	Duplicate/O SpectraRaw_2 SpectraTemp_2
//	Duplicate/O MultiIntIntervals_2 MultiIntIntervalsTemp_2
//	wave SpectrabackgroundMulti_2 =root:OO:Data:Current:SpectraBackgroundMulti_2
//	wave SpectraRawMulti_2=root:OO:Data:Current:SpectraRawMulti_2
//	///Main rountine
//	Print "Auto Integration times routine"
//	
//	
//	//Take background with current settings
//	Spectrabkgd_2=0
//	SpectrabackgroundMulti_2 =0
//	//WARN USER ABOUT BACKGROUND /AUTO SWITHC SHUTTER HERE
//	Print  "Goint to take background, please cover."
////	Shutter_Close(1)
//	Sleep/S 5
//		
//	OO_read() //ANOYINGLY THIS NOW DOES THAT FOR NUMBER ONE AND TWO SPECTROMETER...
//			
//	Duplicate/o SpectraRaw_2 Spectrabkgd_2	
//	Duplicate/o SpectraRawMulti_2 SpectrabackgroundMulti_2
//		
//	///Read NEW SPECTRA
//	//WARN USER ABOUT NORMAL READING /AUTO SHUTTER HERE
//	Print  "Goint to take normal spectra, please remove cover."
////	Shutter_Open(1)
//	Sleep/S 5
//		
//	
//	//Take spectra with current settings
//	OO_read()
//	
//	//Take maximum counts of usual spectra minus background 
//	SpectraTemp_2 = SpectraRaw_2-Spectrabkgd_2
//	maxcounts_2= wavemax(SpectraTemp_2)
//	threshold_level_2 = maxcounts_2*threshold_2
//	Print "MAX COUNTS and LEVEL"
//	Print maxcounts_2, threshold_level_2
//	
//	
//	//Detect saturation
//	//COULD AUTOMATE THIS BUT DECIDED THAT PEOPLE SHOULD THINK AT LEAST A BIT...
//	If (maxcounts_2>= 3900) 
//		Print "Saturation! Please check initial integration time." 
//		///Abort // might be annyoing if people don't get about centre... so removing
//	endif 	
//	
//	//Left side adjusments
//	Variable jmin, jmax
//	Variable jmin_wl, jmax_wl
//	Variable i,j
//	Variable pass
//	pass=0
//	
//	do	//Main loopb
//		pass=pass+1
//		Print "Left hand side pass number ", pass
//		jmin_wl=  MultiIntIntervals_2[0][0]	//always work with left most interval
//		jmax_wl= MultiIntIntervals_2[0][1]
//	
//		//Print jmin_wl, jmax_wl
//		Duplicate/O MultiIntIntervals_2 MultiIntIntervalsTemp_2
//		j=0
//		
//		do
//		//check if current point is higher than threshold
//			//Print wl_wave[j], jmax_wl
//			if (wl_wave_2[j]>= jmax_wl)
//				Print "No change needed"
//				
//				//NEED FLAG
//				ininterval=0
//				//Abort ///FOR NOW CHANGE TO FLAG AND OUT OF LOOP
//			endif
//	
//			if (SpectraTemp_2[j]>=threshold_level_2)
//				//if so cut set that as high end of new intervall
//				Print "Updating intervals"
//				
//				///Push intervals up		
//				MultiIntIntervals_2[1,][] = MultiIntIntervalsTemp_2[p-1][q]
//				MultiIntIntervals_2[0][1] = wl_wave_2[j]
//				MultiIntIntervals_2[1][0] = wl_wave_2[j]
//				MultiIntIntervals_2[0][2] =  MultiIntIntervals_2[0][2]/threshold_2
//				break
//			endif
//			j=j+1
//		while(ininterval==1)
//		
//		///ZERO BACKGROUND
//		Spectrabkgd_2=0
//		SpectrabackgroundMulti_2 =0
//		///TAKE BACKGROND WITH NEW SETTINGS
//		
//		//WARN USER ABOUT BACKGROUND /AUTO SWITHC SHUTTER HERE
//		Print  "Goint to take background, please cover."
////		Shutter_Close(1)
//		Sleep/S 5
//		
//		OO_read()
//			
//		Duplicate/o SpectraRaw_2 Spectrabkgd_2	
//		Duplicate/o SpectraRawMulti_2 SpectrabackgroundMulti_2
//		
//		///Read NEW SPECTRA
//		//WARN USER ABOUT NORMAL READING /AUTO SHUTTER HERE
//		Print  "Goint to take normal spectra, please remove cover."
////		Shutter_Open(1)
//		Sleep/S 5
//		
//		OO_read()
//		SpectraTemp_2 = SpectraRaw_2-Spectrabkgd_2
//		
//	while (pass<maxleftintervals_2)
//	
//	
//	
//	//Right side adjustments
//	///ERrr do the same for right side?
//		Variable lastinterval_2 	// keeps track of number of intervals.
//		
//		Print "Adjusting right side of spectra now" 
//		//find right most interval
//		lastinterval_2=-1
//		do
//			lastinterval_2+=1
//		while (MultiIntIntervals_2[lastinterval_2][0]!=0)
//		lastinterval_2-=1
//		
//		//Print "Last Interval", lastinterval_2
//		
//		pass=0
//		do	//Main loop
//			pass=pass+1
//			Print "Right hand side pass number ", pass
//			
//			jmin_wl= MultiIntIntervals_2[lastinterval_2][0]	//always work with right most interval
//			jmax_wl= MultiIntIntervals_2[lastinterval_2][1]
//			
//			//Print jmin_wl, jmax_wl
//			Duplicate/O MultiIntIntervals_2 MultiIntIntervalsTemp_2
//			
//			//STAR FROM LAST POINT
//			j=DimSize(root:OO:Data:Current:wl_wave_2, 0 )-1
//			do
//			//check if current point is higher than threshold
//				//Print wl_wave_2[j], jmin_wl
//				if (wl_wave_2[j]<= jmin_wl)
//					Print "No change needed"
//					//NEED FLAG
//					ininterval = 0
//					//Abort ///FOR NOW CHANGE TO FLAG AND OUT OF LOOP
//				endif
//	
//				if (SpectraTemp_2[j]>=threshold_level_2)
//					//if so cut set that as high end of new intervall
//					Print "Updating intervals"
//				
//					///Add interval to the end		
//					lastinterval_2=lastinterval_2+1
//					MultiIntIntervals_2[lastinterval_2][1] = MultiIntIntervalsTemp_2[lastinterval_2-1][1]
//					MultiIntIntervals_2[lastinterval_2][0] = wl_wave_2[j]
//					MultiIntIntervals_2[lastinterval_2-1][1] = wl_wave_2[j]
//					MultiIntIntervals_2[lastinterval_2][2] =  MultiIntIntervals_2[lastinterval_2-1][2]/threshold_2
//					break
//				endif
//				j=j-1
//			while(1)
//		
//			///ZERO BACKGROUND
//			Spectrabkgd_2=0
//			SpectrabackgroundMulti_2 =0
//			///TAKE BACKGROND WITH NEW SETTINGS
//		
//			//WARN USER ABOUT BACKGROUND /AUTO SWITHC SHUTTER HERE
//			Print  "Goint to take background, please cover."
////			Shutter_Close(1)
//			Sleep/S 5
//		
//			OO_read()
//			
//			Duplicate/o SpectraRaw_2 Spectrabkgd_2	
//			Duplicate/o SpectraRawMulti_2 SpectrabackgroundMulti_2
//		
//			///Read NEW SPECTRA
//			//WARN USER ABOUT NORMAL READING /AUTO SHUTTER HERE
//			Print  "Goint to take normal spectra, please remove cover."
////			Shutter_Open(1)
//			Sleep/S 5
//		
//			OO_read()
//			SpectraTemp_2 = SpectraRaw_2-Spectrabkgd_2
//		
//		while (pass<maxrightintervals_2)	
//	
//	
//	
//	SetDataFolder savDF
//end

Function Make_Absorbance(input, type)
	Wave input
	Variable type // if type == -1 then delete any existing absorbance wave, else
	String dfSav = GetDataFolder(1)
	SetDataFolder GetWavesDataFolder(input,1)
	
	if (type==-1)
		if(WaveExists($(NameOfWave(input) + "_Absorbance"))==1)
			KillWaves $(NameOfWave(input) + "_Absorbance")
		endif
	else
		Duplicate/O input, $(NameOfWave(input) + "_Absorbance")
		Wave/z Absorbance= $(NameOfWave(input) + "_Absorbance")
		Absorbance = -log(1/input)
	endif
	
	SetDataFolder dfSav
End

Function ExportTxt()
	Variable numDF=CountObjects("root:OO:Data", 4 ) -1	//number of scans
	variable ii,jj,items
	String CurrDF,list,Namepth,Name,ScnDF,fPth,sPth
	Nvar NumSpectrometers=root:OO:GlobalVariables:NumSpectrometers
	if 	(NumSpectrometers==1)
		list = "wl_wave;Spectra"	//list of waves you want to export
	elseif (NumSpectrometers==2)
		list = "wl_wave;Spectra;wl_wave_2;Spectra_2"
	endif
	items =ItemsInList(list)

	NewPath/O/C Path
	PathInfo Path
	fPth=S_path

	for (ii=1;ii<=numDF;ii+=1)
		ScnDF="root:OO:Data:Scan"+num2str(ii)
		SVAR Desc=$(ScnDF+":Description")
		sPth = fPth +num2str(ii)+"-"+Desc
		NewPath/O/C Path, sPth
		For (jj=0;jj<items;jj+=1)
			Name = Stringfromlist(jj,list)
			Namepth = Name + ".txt"
			Print Namepth
			Save/O/J/P=Path $(CurrDF+":"+Name) as Namepth
		Endfor
		KillPath Path
	Endfor
End