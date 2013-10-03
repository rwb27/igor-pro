#pragma rtGlobals=1		// Use modern global access method.

//BWTekIgor_Config()
//BWTekIgor_SetIntTime(100)
//BWTekIgor_Close()
//BWTekIgor_Read(bw1)


//Menu "BWTeK Spectrometer Panel"
	   "Open Panel" , /Q, mRunBWTeKPanel()
End

Macro mRunBWTeKPanel()
	SetDataFolder root:
	DoWindow /K winBWTeKPanel
	killdatafolder/Z root:								// Comment out if tBWTeK dangerous
	String/G sPanelName = "winBWTeKPanel"
	fBWTeKSetup()
	winBWTeKPanel()
end

/////////////////////////////////////////////////// Setup Igor Runtime Environment

Function fBWTeKSetup()									// Runtime Environment
	SetDataFolder root:								// BWTeK folder structure
	NewDataFolder/O/S root:BWTeK						// Hosts all the variables
	NewDataFolder/O/S root:BWTeK:Data					// Hosts all the graph folders
	NewDataFolder/O/S root:BWTeK:Data:Current			// Hosts all the current graphs

	SetDataFolder root:BWTeK:Data:Current				// Create a set of empty graphs
	Make/O/N=2048 Spectra, SpectraBkgd, wl_wave, Ref, SpectraRaw

	SetDataFolder root:BWTeK:
	String/G sBWTeKSpectrometer = ""					// Spectrometer name
	String/G sBWTeKSample = ""							// Sample name
	String/G sBWTeKScanDesc =""						// Scan description
	String/G sBWTeKOneNotePath = ""					// Path to OneNote
	String/G sBWTeKMultiIntTime = "0:10;1:100;2:1000;"		// Mulitple integration times
	Variable/G vBWTeKNextIndex=1 						// Save scan number, might go over original data
	Variable/G vBWTeKIntTime = 10						// Integration time
	Variable/G vBWTeKScanTime=1						// Delay time between spectra
	Variable/G vBWTeKNumSpectra=1 						// Number of spectra to be recorded
	Variable/G vBWTeKYmin = 0
	Variable/G vBWTeKYmax =4000
	Variable/G vBWTeKXmin = 360
	Variable/G vBWTeKXmax =1000
	Variable/G vBWTeKAveragedOver = 1					// Number of spectra averaged
	Variable/G vBWTeKTECtemp = -10
End

/////////////////////////////////////////////////// Get configurations off spectrometer
	
Function fBWTeKConfig()
	Variable BWTeKnpnts
	SetDataFolder  root:BWTeK:Data:Current

	BWTeKnpnts = BWTekIgor_Config()						// Get correct dimension of spectra
	Make/O/N=(BWTeKnpnts) Spectra, Spectrabkgd=0, wl_wave, Ref = 1, SpectraRaw
	  	
  	Wave wl_wave_calibrate = wl_wave
	BWCalib()							 					// Calibration from spectrometer
	
//	execute "root:BWTeK:sBWTeKSpectrometer = BWTeKIgor_GetUSBSerialNumber(0)"		// sometimes on the first call this gets garbled, not sure why, fine if call again, JJB
//	execute "root:BWTeK:sBWTeKSpectrometer = BWTeKIgor_GetUSBSerialNumber(0)"

	Svar sBWTeKSpectrometer = root:BWTeK:sBWTeKSpectrometer
	sBWTeKSpectrometer = "USB00"							// Removes jargon at the end of the string
	
	Nvar vBWTeKIntTime=root:BWTeK:vBWTeKIntTime
	BWTeKIgor_SetIntTime(vBWTeKIntTime)					// Set integration time - WHY HERE?

	if (cmpstr(sBWTeKSpectrometer,"")==0)						// Check if spectrometer is connected
		print "connect spectrometer !"
		abort
	endif
	
	fBWTeKRead()
	fBWTeKAutoScaleY()									// To see graph
	fBWTeKAutoScaleX()
End

Function BWCalib()
Wave wl_wave
Variable A0,A1,A2,A3
 A0 = 174.79794094828
 A1 = 0.549888391045897
 A2 = -4.92130645934896E-5
 A3 = -4.22027164536737E-9
wl_wave[] = A0 + A1*p + A2*p^2 + A3*p^3
End

/////////////////////////////////////////////////// Read spectrometer signal

Function fBWTeKRead()
	Svar sBWTeKSpectrometer =  root:BWTeK:sBWTeKSpectrometer
	Nvar vBWTeKAveragedOver =  root:BWTeK:vBWTeKAveragedOver, vBWTeKIntTime =  root:BWTeK:vBWTeKIntTime
	SetDataFolder root:BWTeK:Data:Current
	Wave Spectra,SpectraRaw,Spectrabkgd,Ref
	duplicate/O SpectraRaw, SpectraAveraged
	SpectraAveraged = 0
	
	if (Ref[0] == 0 && Ref[1] == 0)
		Ref += 1										// Turn zero into 1 to avoid infinite results
	endif
	BWTeKIgor_SetIntTime(vBWTeKIntTime)				// Set integration time
	variable i = 0
	do
		BWTeKIgor_Read(SpectraRaw)
		
		SpectraAveraged += SpectraRaw[p]
		i += 1
	while (i < vBWTeKAveragedOver)
	SpectraAveraged /= vBWTeKAveragedOver
	SpectraRaw = SpectraAveraged
	
 	Spectra = (SpectraRaw - Spectrabkgd)/(Ref)			// Adjust spectrum

	if (stringmatch(sBWTeKSpectrometer,"USB*")==1)		// First two points from USB2000 spectrometer are NaN
	 	Spectra[0,1]=NaN
	endif 
	Spectra[] = (Spectra[p]<inf ? Spectra[p] : NaN)
	Spectra[] = (Spectra[p]>-inf ? Spectra[p] : NaN)

	
	killwaves SpectraAveraged
	return 0											// Essential for live view
End

/////////////////////////////////////////////////// Graph display

Function fBWTeKAutoScaleY()								// Scale y-axis in accordance with the height of the graph
	svar sPanelName = root:sPanelName
	Execute "SetActiveSubwindow " + sPanelName + "#winBWTeKLiveSpectraGraph"
	WaveStats/Q root:BWTeK:Data:Current:Spectra
	SetAxis left V_min,V_max
	DoUpdate
End 

Function fBWTeKAutoScaleX()								// Scale x-axis in accordance with the range of the graph
	svar sPanelName = root:sPanelName
	Execute "SetActiveSubwindow " + sPanelName + "#winBWTeKLiveSpectraGraph"
	WaveStats/Q root:BWTeK:Data:Current:wl_wave
	SetAxis bottom V_min,V_max
	DoUpdate
End

/////////////////////////////////////////////////// Button functions

Function fBWTeKStartButton(theTag)
	String theTag		
	If ( cmpstr(theTag,"bBWTeKLive")==0 )					// Checks the state of the button
		Button $theTag,rename=StopButton,title="Stop"
		SetBackground fBWTeKRead()
		CtrlBackground period=10,dialogsOK=1,noBurst=1,start
	Else
		Button $theTag,rename=bBWTeKLive,title="Live"
		CtrlBackground stop
	Endif
End

Function fBWTeKSaveSpectrum()												
      	String savDF= GetDataFolder(1)
     	SetDataFolder root:BWTeK:
	Nvar vBWTeKNextIndex, vBWTeKAveragedOver, vBWTeKIntTime, vBWTeKAveraged
	Svar sBWTeKSpectrometer, sBWTeKScanDesc, sBWTeKOneNotePath, sBWTeKSample
	String foldername="Scan"+ num2str(vBWTeKNextIndex)
	
	SetDataFolder root:BWTeK:Data:Current	//Change to right folder
	string sBWTeKInfoByKey = ""
	sBWTeKInfoByKey += "Sample:" + sBWTeKSample + ";"
	sBWTeKInfoByKey += "Scan:" + num2str(vBWTeKNextIndex) + ";"
	sBWTeKInfoByKey += "Description:" + sBWTeKScanDesc + ";"
	sBWTeKInfoByKey += "IntTime:" + num2str(vBWTeKIntTime) + ";"
	sBWTeKInfoByKey += "NumSpecAveragedOver:" + num2str(vBWTeKAveragedOver) + ";"
//	sBWTeKInfoByKey += "OneNotePath:" + sBWTeKOneNotePath + ";"
	sBWTeKInfoByKey += "Spectrometer:" + sBWTeKSpectrometer + ";"

	Note/K/NOCR root:BWTeK:Data:Current:Spectra, sBWTeKInfoByKey
	print note(root:BWTeK:Data:Current:Spectra)
	SetDataFolder root:BWTeK:Data:
	DuplicateDataFolder Current, $foldername			// Create scan folder
	SetDataFolder $foldername	
	
	SetDataFolder root:BWTeK:
	vBWTeKNextIndex+=1	
	SetDataFolder savDF
End

Function fBWTeKKineticsButton()	//reads and saves "Number of Spectra" spectra at delay intervals of "delay time"
			    Nvar vBWTeKScanTime=root:BWTeK:vBWTeKScanTime
			    Nvar vBWTeKNumSpectra=root:BWTeK:vBWTeKNumSpectra
			    Nvar vBWTeKIntTime=root:BWTeK:vBWTeKIntTime
			    variable i
			    string scan_num
			   	 if (vBWTeKIntTime>vBWTeKScanTime*1000) //check integration time is lower than delay time
			   	 print "Integration time larger than delay"
			   	 else
			   		 do	 
			    			    fBWTeKRead()
			    			    fBWTeKSaveSpectrum()
			    			    i=i+1
			    			    scan_num="spectrum"+num2istr(i)+" recorded"
			    			    Print scan_num
			    			    //Print "scan"$i 
			    			    pauseupdate; sleep/S vBWTeKScanTime 
			   		while (i<vBWTeKNumSpectra)
			   		print "kinetic measurement finished"
			   	Endif
End

Function fBWTeKMultipleBkgd()
svar sTimes = root:BWTeK:sBWTeKMultiIntTime
variable i = 0
Variable BWTeKnpnts
Nvar vBWTeKIntTime = root:BWTeK:vBWTeKIntTime
SetDataFolder  root:BWTeK:Data:Current
	wave SpectraRaw
	BWTeKnpnts = BWTeKIgor_Config()						// Get correct dimension of spectra
		Make/O/N=(BWTeKnpnts,ItemsInList(sTimes)) MultiSpectrabkgd=0

		do
			vBWTeKIntTime = str2num(StringByKey(num2str(i), sTimes))
			fBWTeKRead()
			MultiSpectrabkgd[][i] = SpectraRaw[p]
			i += 1
		while (i < ItemsInList(sTimes))
end

Function fBWTeKMultipleRef()
svar sTimes = root:BWTeK:sBWTeKMultiIntTime
variable i = 0
Variable BWTeKnpnts
Nvar vBWTeKIntTime = root:BWTeK:vBWTeKIntTime
SetDataFolder  root:BWTeK:Data:Current
	wave SpectraRaw, MultiSpectrabkgd
		BWTeKnpnts = BWTeKIgor_Config()						// Get correct dimension of spectra
		Make/O/N=(BWTeKnpnts,ItemsInList(sTimes)) MultiRef=1

		do
			vBWTeKIntTime = str2num(StringByKey(num2str(i), sTimes))
			fBWTeKRead()
			MultiRef[][i] = SpectraRaw[p] - MultiSpectrabkgd[p][i]
			MultiRef[0][i] = 1
			MultiRef[1][i] = 1
			i += 1
		while (i < ItemsInList(sTimes))
end


Function fBWTeKMultipleInt()
svar sTimes = root:BWTeK:sBWTeKMultiIntTime
variable i = 0
Variable BWTeKnpnts
Nvar vBWTeKIntTime = root:BWTeK:vBWTeKIntTime
SetDataFolder root:BWTeK:Data:Current:
	wave Spectraraw, MultiRef, MultiSpectrabkgd
	
		BWTeKnpnts = BWTeKIgor_Config()						// Get correct dimension of spectra
		Make/O/N=(BWTeKnpnts,ItemsInList(sTimes)) MultiSpectra = 0, MultiSpectraRaw = 0, MultiSpectrabkgd, MultiRef
		do
			vBWTeKIntTime = str2num(StringByKey(num2str(i), sTimes))
			fBWTeKRead()
			MultiSpectraRaw[][i] = SpectraRaw[p]
			MultiSpectra[][i] = SpectraRaw[p] - MultiSpectrabkgd[p][i] 
			if (MultiRef[0][i] == 1 && MultiRef[1][i] == 1)
				MultiSpectra[][i] /= MultiRef[p][i]
			endif			
			i += 1
		while (i < ItemsInList(sTimes))
end

/////////////////////////////////////////////////// Panel Control
  
Function fbBWTeK(ctrlName) : ButtonControl
	String ctrlName
	SetDataFolder root:
	svar sPanelName
	execute "SetActiveSubwindow " + sPanelName + "#winBWTeKLiveSpectraGraph"
	StrSwitch (ctrlName) //////////////////////////////Spectra graph buttons
		case "bBWTeKStart":
			fBWTeKConfig()
			break
		case "bBWTeKRead":
			fBWTeKRead()			
			break
		case "bBWTeKZeroBkgd":
			wave Spectrabkgd = root:BWTeK:Data:Current:Spectrabkgd
			Spectrabkgd = 0
			fBWTeKRead()
			fBWTeKAutoScaleY()
			break
		case "bBWTeKStoreBkgd":
			fBWTeKRead()
			wave SpectraRaw = root:BWTeK:Data:Current:SpectraRaw, Spectrabkgd = root:BWTeK:Data:Current:Spectrabkgd
			Duplicate/O SpectraRaw SpectraBkgd
			fBWTeKRead()
			fBWTeKAutoScaleY()
			break
		case "bBWTeKZeroRef":
			wave Ref = root:BWTeK:Data:Current:Ref
			Ref = 0
			fBWTeKRead()
			fBWTeKAutoScaley()
			break
		case "bBWTeKStoreRef":
			fBWTeKRead()
			wave Spectra = root:BWTeK:Data:Current:Spectra, Ref = root:BWTeK:Data:Current:Ref
			Duplicate/O Spectra Ref
			fBWTeKRead()	
			fBWTeKAutoScaleY()
			break
		case "bBWTeKZBWTeKmIn":
			fBWTeKAutoScaleY()
			fBWTeKAutoScaleX()
			break
		case "bBWTeKZBWTeKm0to2":
			SetAxis left 0,2
			fBWTeKAutoScaleX()
			break
		case "bBWTeKZBWTeKmOut":
			nvar vBWTeKYmin = root:BWTeK:vBWTeKYmin,vBWTeKYmax = root:BWTeK:vBWTeKYmax
			SetAxis left vBWTeKYmin,vBWTeKYmax
			fBWTeKAutoScaleX()
			break
		case "bBWTeKSaveSpectra":  	
			fBWTeKSaveSpectrum()
			break
		case "bBWTeKSaveDataFolders":
			SetDataFolder root:BWTeK:Data:	
			SaveData/I/T/R 									
			break
		case "bBWTeKSetSample":
			print "New Sample"
			break
		case "bBWTeKMultipleIntTime":
			fBWTeKMultipleInt()
			break
		case "bBWTeKMultipleBkgd":
			fBWTeKMultipleBkgd()
			break
		case "bBWTeKMultipleRef":
			fBWTeKMultipleRef()
			break
		case "bBWTeKMultipleRemove":
			SetDataFolder root:BWTeK:Data:Current:
			KillWaves/Z MultiSpectra, MultiSpectraRaw, MultiSpectrabkgd, MultiRef
			break
		case "bBWTeKMultipleSpecShow":
			NewImage root:BWTeK:Data:Current:MultiSpectra
			ModifyImage MultiSpectra ctab= {*,*,Rainbow,0}
			break
		default:
			Print "ERROR!"; Print ctrlname
			break
	Endswitch 
	Return 0
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Window winBWTeKPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(700,50,1210,500) as "BWTeK Spectrometer Panel"

	Button bBWTeKStart,pos={10,10},size={120,20},	proc=fbBWTeK,title="Start Spectrometer"
	SetVariable svBWTeKSampDesc,pos={200,10},size={300,20},title="Sample Name",value= root:BWTeK:sBWTeKSample

	SetDataFolder root:BWTeK:Data:Current:
	Display/W=(10,35,500,335)/HOST=#  Spectrabkgd vs wl_wave
	AppendToGraph Ref vs wl_wave
	AppendToGraph Spectra vs wl_wave
	ModifyGraph frameStyle=1
	ModifyGraph rgb(Spectrabkgd)=(48896,65280,48896),rgb(Ref)=(48896,49152,65280)
	SetAxis left 125,143
	SetAxis bottom 350,950
	Legend/C/N=text0/J/X=-6.00/Y=-5.00 "\\s(Spectra) Spectra\r\\s(Spectrabkgd) Bkgd\r\\s(Ref) Ref"
	RenameWindow #,winBWTeKLiveSpectraGraph
	SetActiveSubwindow ##

	Button bBWTeKLive,pos={10,340},size={50,20},proc=fBWTeKStartButton,title="Live",labelBack=(65280,0,0),fColor=(65280,21760,0)
	Button bBWTeKRead,pos={60,340},size={50,20},proc=fbBWTeK,title="Read"
	SetVariable svBWTeKInt,pos={10,360},size={100,20},limits={3,inf,1},value= root:BWTeK:vBWTeKIntTime, title = "IntT (ms)"
	SetVariable svBWTeKAveraged,pos={10,380},size={100,20},title="# of scans",limits={1,inf,1},value= root:BWTeK:vBWTeKAveragedOver

	Button bBWTeKZeroBkgd,pos={120,340},size={80,20},proc=fbBWTeK,title="Empty Bkgd"
	Button bBWTeKZeroRef,pos={200,340},size={80,20},proc=fbBWTeK,title="Empty Ref"
	Button bBWTeKStoreBkgd,pos={120,360},size={80,20},proc=fbBWTeK,title="Store Bkgd"
	Button bBWTeKStoreRef,pos={200,360},size={80,20},proc=fbBWTeK,title="Store Ref"
	
	SetVariable svBWTeKMultiIntTime,pos={300,340},size={100,20},value= root:BWTeK:sBWTeKMultiIntTime, title = " "
	Button bBWTeKMultipleBkgd,pos={300,360},size={50,20},proc=fbBWTeK,title="Bkgd"
	Button bBWTeKMultipleRef,pos={350,360},size={50,20},proc=fbBWTeK,title="Ref"
	Button bBWTeKMultipleIntTime,pos={300,380},size={100,20},proc=fbBWTeK,title="Scan Multiwaves"
	Button bBWTeKMultipleRemove,pos={300,400},size={100,20},proc=fbBWTeK,title="Kill Multiwaves"
	Button bBWTeKMultipleSpecShow,pos={300,420},size={100,20},proc=fbBWTeK,title="Show Multiwaves"
	
	Button bBWTeKZBWTeKmIn,pos={420,340},size={40,20},proc=fbBWTeK,title="Zoom"
	Button bBWTeKZBWTeKm0to2,pos={460,340},size={40,20},proc=fbBWTeK,title="0 to 2"
	Button bBWTeKZBWTeKmOut,pos={420,360},size={80,20},proc=fbBWTeK,title="Zoom Out"

	SetVariable svScanDesc,pos={10,400},size={270,20},title="Scan Desc",value= root:BWTeK:sBWTeKScanDesc
	Button bBWTeKSaveSpectra,pos={10,420},size={80,20},proc=fbBWTeK,title="Save Spectra"
	SetVariable svBWTeKNumSpectra,pos={100,420},size={80,20},title="Spec #",limits={1,inf,1},value= root:BWTeK:vBWTeKNextIndex
	Button bBWTeKSaveDataFolders,pos={180,420},size={100,20},proc=fbBWTeK,title="Save folders",labelBack=(65280,0,0),fColor=(65280,21760,0)
EndMacro


