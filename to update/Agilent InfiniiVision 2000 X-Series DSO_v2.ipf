// Agilent InfiniiVision 2000 X-Series Oscilloscopes
// Programmed by Alan Sanders, as2180@cam.ac.uk, 10/04/12
// ver2 modified by MH for use in tipExperiment
// -- Look out for for incorrect global variable structures 


#pragma rtGlobals=1		// Use modern global access method.

// Connect to PC via USB Device port.
function openDSO()
	variable session, instr, status
	string resourceName = "USB0::0x0957::0x1799::MY51330673::0::INSTR"	// DSOX2012A
	status = viOpenDefaultRM(session)
	status = viOpen(session,resourceName,0,0,instr)
	variable/g root:gVariables:agilentOscilloscope:sessionDSO = session
	variable/g root:gVariables:agilentOscilloscope:instrDSO = instr
	
//	string dirpath = "root:'DSO Settings'"
//	if (!datafolderexists(dirpath))
//		newdatafolder $dirpath
//	endif
end

function closeDSO()
	nvar session = root:gVariables:agilentOscilloscope:sessionDSO
	viClear(session)
	viClose(session)
end

function cmdDSO(cmd)
	string cmd
	nvar instr = root:gVariables:agilentOscilloscope:instrDSO
	VISAwrite instr, cmd
end

function/s readbufferDSO()
	string buffer
	nvar instr = root:gVariables:agilentOscilloscope:instrDSO
	VISAread instr, buffer
	return buffer
end

function queryDSO(cmd)
	string cmd
	nvar instr = root:gVariables:agilentOscilloscope:instrDSO
	VISAwrite instr, cmd
	variable response
	VISAread instr, response
	return response
end

function/s squeryDSO(cmd)
	string cmd
	nvar instr = root:gVariables:agilentOscilloscope:instrDSO
	VISAwrite instr, cmd
	string response
	VISAread/t="\n" instr, response
	return response
end

function resetDSO()
	openDSO()
	nvar instr = root:gVariables:agilentOscilloscope:instrDSO
	VISAwrite instr, "*RST"
	closeDSO()
end

//Basic Program Flow: Initialise - Capture - Analyse

function initialiseDSO()									// General Setup Procedure
	nvar instr = root:instrDSO	
	
	//General Setup
	VISAwrite instr, "*RST"								// Reset
	VISAwrite instr, ":AUToscale"							// Autoscale for initial settings
	VISAwrite instr, ":RUN"
	
	// Timebase Setup
	VISAwrite instr, ":TIMebase:RANGe 5E-4"				// Time base to 50 us/div.
	VISAwrite instr, ":TIMebase:DELay 0"					// Time delay to zero.
	VISAwrite instr, ":TIMebase:REFerence CENTer"			// Display ref. at center.

	// Channel 1 Voltage Setup
	VISAwrite instr, ":CHANnel1:PROBe 10"				// Probe attenuation to 10:1.
	VISAwrite instr, ":CHANnel1:RANGe 1.6"				// Vertical range 1.6 V full scale, 2 V/div.
	VISAwrite instr, ":CHANnel1:OFFSet -0.4"				// Center of screen offset to -0.4.
	VISAwrite instr, ":CHANnel1:COUPling DC"				// Coupling to DC.

	// Trigger Setup
	VISAwrite instr, ":TRIGger:SWEep NORMal"				// Normal triggering.
	VISAwrite instr, ":TRIGger:LEVel -0.4"					// Trigger level to -0.4.
	VISAwrite instr, ":TRIGger:SLOPe POSitive"				// Trigger on pos. slope.
	
	// Acquisition Setup
	VISAwrite instr, ":ACQuire:TYPE NORMal"				// Normal acquisition.
	
	// Data Storage
	if(!datafolderexists("root:'DSO Settings'"))
		newdatafolder root:'DSO Settings'
	endif
	variable/G root:'DSO Settings':secdiv
	variable/G root:'DSO Settings':horpos
	variable/G root:'DSO Settings':vertpos
	variable/G root:'DSO Settings':voltdiv
	variable/G root:'DSO Settings':trig
	
	VISAwrite instr, ":STOP"
	print squeryDSO("*OPC?")
end

function setupgeneralDSO(mode, clear)
	string mode
	variable clear
	nvar instr = root:instrDSO
	VISAwrite instr, ":STOP"
	print squeryDSO("*OPC?")
	if (!stringmatch(mode,"RUN") && !stringmatch(mode,"SINGle") && !stringmatch(mode,"STOP"))
		print "Invalid Mode (RUN | SINGle | STOP)"
	endif
	VISAwrite instr, ":"+mode
	if (clear == 1)
		VISAwrite instr, "*CLS"
	endif
end

Function setuptimebaseDSO(mode, range, scale, delay, ref)				// Timebase Setup
	variable range, scale, delay
	string mode, ref
	nvar instr = root:instrDSO
	if (!stringmatch(mode,"MAIN") && !stringmatch(mode,"WINDow") && !stringmatch(mode,"XY") && !stringmatch(mode,"ROLL"))
		print "Invalid Timebase Mode (MAIN, WINDow, XY, ROLL)"
		return 0
	endif
	VISAwrite instr, ":TIMebase:MODE " + mode
	string/g root:'DSO Settings':Mode = mode
	if (stringmatch(mode, "WINDow"))
		//setupwindowTimebaseDSO()
	endif
	if (range != 0)
		VISAwrite instr, ":TIMebase:RANGe " + num2str(range)
		variable/g root:'DSO Settings':Trange = range
		variable/g root:'DSO Settings':Tscale = 0
	endif
	if (scale != 0)
		VISAwrite instr, ":TIMebase:SCALe " + num2str(scale)
		variable/g root:'DSO Settings':Tscale = scale
		variable/g root:'DSO Settings':Trange = 0
	endif
	if (!stringmatch(ref,"LEFT") && !stringmatch(ref,"CENTer") && !stringmatch(ref,"RIGHt"))
		print "Invalid Timebase Reference (LEFT, CENTer, RIGHt)"
		return 0
	endif
	VISAwrite instr, ":TIMebase:REFerence " + ref
	string/g root:'DSO Settings':Reference = ref
	VISAwrite instr, ":TIMebase:DELay " + num2str(delay)
	variable/g root:'DSO Settings':Delay = delay
	// Collect Current Numerical Settings
	if(!datafolderexists("root:'DSO Settings'"))
		newdatafolder root:'DSO Settings'
	endif
end

function setupwindowtimebaseDSO(pos, range, scale)
	variable pos, range, scale
	nvar instr = root:instrDSO
	VISAwrite instr, ":TIMebase:WINDow:POSition " + num2str(pos)
	VISAwrite instr, ":TIMebase:WINDow:RANGe " + num2str(range)
	VISAwrite instr, ":TIMebase:WINDow:SCALe " + num2str(scale)
end

function setupchannelDSO(ch, range, scale, offset, coupling, unit, chlabel, probe)		// Channel Voltage Setup
	variable range, scale, offset, probe
	string ch, coupling, unit, chlabel
	nvar instr = root:instrDSO
	if (!stringmatch(ch, "1") && !stringmatch(ch, "2"))
		print "Invalid Channel Number (1, 2)"
		return 0
	endif
	if (probe != 0)
		VISAwrite instr, ":CHANnel"+ch+":PROBe " + num2str(probe)
		variable/g $("root:'DSO Settings':V"+ch+"probe") = probe
	endif
	if (range != 0)
		VISAwrite instr, ":CHANnel"+ch+":RANGe " + num2str(range)			// 8 mv to 40 V range
		variable/g $("root:'DSO Settings':V"+ch+"range") = range
	endif
	if (scale != 0)
		VISAwrite instr, ":CHANnel"+ch+":SCALe " + num2str(scale)		// Volts/div
		variable/g $("root:'DSO Settings':V"+ch+"scale") = scale
	endif
	VISAwrite instr, ":CHANnel"+ch+":OFFSet " + num2str(offset)
	variable/g $("root:'DSO Settings':V"+ch+"offset") = offset
	if (!stringmatch(coupling, "AC") && !stringmatch(coupling, "DC"))
		print "Invalid Channel Coupling (AC, DC)"
		return 0
	endif
	VISAwrite instr, ":CHANnel"+ch+":COUPling "+coupling
	string/g $("root:'DSO Settings':V"+ch+"coupling") = coupling
	if (stringmatch(unit, "V"))
		VISAwrite instr, ":CHANnel"+ch+":UNITs VOLT"
		string/g $("root:'DSO Settings':V"+ch+"unit") = unit
	elseif (stringmatch(unit, "A"))
		VISAwrite instr, ":CHANnel"+ch+":UNITs AMPere"
		string/g $("root:'DSO Settings':V"+ch+"unit") = unit
	else
		print "Invalid Channel Unit (V, A)"
	endif
	if (!stringmatch(chlabel, ""))
		VISAwrite instr, ":CHANnel"+ch+":LABel "+chlabel
		string/g $("root:'DSO Settings':V"+ch+"label") = chlabel
	endif
	VISAwrite instr, ":CHANnel"+ch+":DISPlay 1"
end

function setuptriggerDSO(sweep, mode, source, level, slope, rejectnoise, filter)				// Trigger Setup
	variable level
	string sweep, mode, source, slope, rejectnoise, filter
	nvar instr = root:instrDSO
	// Sweep Settings
	if (!stringmatch(sweep, "NORMal") && !stringmatch(sweep, "AUTO"))
		print "Invalid Trigger Sweep (NORMal, AUTO)"
		return 0
	endif
	VISAwrite instr, ":TRIGger:SWEep "+sweep
	// Trigger Mode
	if (!stringmatch(mode, "EDGE") && !stringmatch(mode, "GLITch") && !stringmatch(mode, "PATTern") && !stringmatch(mode, "TV"))
		print "Invalid Trigger Mode (EDGE, GLITch, PATTern, TV)"
		return 0
	endif
	VISAwrite instr, ":TRIGger:MODE "+mode
	// Trigger Source
	if (!stringmatch(source, "CHANnel*") && !stringmatch(source, "EXTernal") && !stringmatch(source, "LINE") && !stringmatch(source, "WGEN"))
		print "Invalid Trigger Source (CHANnel<n> | EXTernal | LINE | WGEN)"
		return 0
	endif
	VISAwrite instr, ":TRIGger:SOURce "+source
	// Trigger Level
	VISAwrite instr, ":TRIGger:LEVel " + num2str(level)
	// Slope Settings
	if (!stringmatch(slope, "POSitive") && !stringmatch(slope, "NEGative") && !stringmatch(slope, "EITHer") && !stringmatch(slope, "ALTernate"))
		print "Invalid Trigger Slope (POSitive, NEGative, EITHer, ALTernate)"
		return 0
	endif
	VISAwrite instr, ":TRIGger:SLOPe "+slope
	// Noise Rejection
	if (!stringmatch(rejectnoise, "0") && !stringmatch(rejectnoise, "1"))
		print "Invalid Trigger Noise Rejection (1, 0)"
		return 0
	endif
	VISAwrite instr, ":TRIGger:NREJect "+rejectnoise
	// High Pass Filter
	if (!stringmatch(filter,"0") && !stringmatch(filter,"1"))
		print "Invalid Trigger Filter (1, 0)"
		return 0
	endif
	VISAwrite instr, ":TRIGger:HFReject "+filter
end

function setupacquireDSO(type)
	string type
	nvar instr = root:instrDSO
	// Setup Acquire Type
	if (stringmatch(type, "NORM"))
		VISAwrite instr, ":ACQuire:TYPE NORMal"
		VISAwrite instr, ":ACQuire:COMPlete 100"
	elseif (stringmatch(type, "AVER"))
		VISAwrite instr, ":ACQuire:TYPE AVERage"
		VISAwrite instr, ":ACQuire:COMPlete 100"
		VISAwrite instr, ":ACQuire:COUNt 8"
	elseif (stringmatch(type, "HRES"))
		VISAwrite instr, ":ACQuire:TYPE HRESolution"
		VISAwrite instr, ":ACQuire:COMPlete 100"
	elseif (stringmatch(type, "PEAK"))
		VISAwrite instr, ":ACQuire:TYPE PEAK"
		VISAwrite instr, ":ACQuire:COMPlete 100"
	else
		print "Invalid Acqusition Type (NORM, AVER, HRES, PEAK)"
		return 0
	endif
end

function captureallDSO()
	nvar instr = root:instrDSO
	// Capture Data
	VISAwrite instr, ":DIGitize"
end

Function captureDSO(ch)
	string ch
	nvar instr = root:gVariables:agilentOscilloscope:instrDSO
	// Capture Data
	if (!stringmatch(ch, "1") && !stringmatch(ch, "2"))
		print "Invalid Channel Number (1, 2)"
		return 0
	endif
	VISAwrite instr, ":DIGitize CHANnel"+ch
end

function importdataDSO(ch, wName)
	string ch, wName
	nvar instr = root:gVariables:agilentOscilloscope:instrDSO
	variable points = queryDSO(":ACQuire:POINts?")
	make/o/n=(points+10) $wName
	wave w = $wName
	w = 0
	VISAwrite instr, ":WAVeform:SOURce CHANnel"+ch
	VISAwrite instr, ":WAVeform:FORMat BYTE"
	VISAwrite instr, "WAVeform:UNSigned 0"
	VISAwrite instr, ":WAVeform:POINts "+num2str(points)
	VISAwrite instr, ":WAVeform:DATA?"
	VISAReadBinaryWave/TYPE=(0x08)/B instr, w
	DeletePoints 0, 10, w
	// Scale Data
//	if(!datafolderexists("root:'DSO Settings'"))
//		newdatafolder root:'DSO Settings'
//	endif
	variable y_or, y_inc, y_ref, x_or, x_inc
	y_or = queryDSO("WAVeform:YORigin?")
	y_inc = queryDSO("WAVeform:YINCrement?")
	y_ref = queryDSO("WAVeform:YREFerence?")
	x_or = queryDSO("WAVeform:XORigin?")
	x_inc = queryDSO("WAVeform:XINCrement?")
//	variable/g root:'DSO Settings':Yor=y_or
//	variable/g root:'DSO Settings':Yinc=y_inc
//	variable/g root:'DSO Settings':Yref=y_ref
//	variable/g root:'DSO Settings':Xor=x_or
//	variable/g root:'DSO Settings':Xinc=x_inc
	w = y_or + (y_inc * (w - y_ref))
	setscale d, 0, 0, "V", w
	setscale/p x, x_or, x_inc, "s", w
end

function definemeasurementDSO()
	string df = "root:'DSO Settings'"
	if (!datafolderexists(df))
		newdatafolder $df
	endif
	df += ":"
	variable/g $(df+"Trange") = 0
	variable/g $(df+"Tscale") = 10e-6
	variable/g $(df+"Delay") = 0
	variable/g $(df+"V1range") = 0
	variable/g $(df+"V1scale") = 10e-3
	variable/g $(df+"V1offset") = 0
	variable/g $(df+"TrigLevel") = 0
	string/g $(df+"TrigSlope") = "POSitive"
	string/g $(df+"AcqType") = "NORM"
	string/g $(df+"DelayRef") = "CENTer"
	string/g $(df+"Ch1Unit") = "A"
end

function setupDSO(Nch)
	variable Nch
	string df = "root:'DSO Settings':"
	cmdDSO(":STOP")
	print squeryDSO("*OPC?")
	setupgeneralDSO("RUN",1)
	// Time Base
	nvar Trange = $(df+"Trange"), Tscale = $(df+"Tscale"), Delay = $(df+"Delay")
	svar DelayRef = $(df+"DelayRef")
	setuptimebaseDSO("MAIN", Trange, Tscale, Delay, DelayRef)
	// Channel 1
	nvar V1range = $(df+"V1range"), V1scale = $(df+"V1scale"), V1offset = $(df+"V1offset")
	svar Ch1Unit = $(df+"Ch1Unit")
	setupchannelDSO("1", V1range, V1scale, V1offset, "DC", Ch1Unit, "", 1.0)
	// Channel 2
	if (Nch == 2)
		nvar V2range = $(df+"V2range"), V2scale = $(df+"V2scale"), V2offset = $(df+"V2offset")
		svar Ch2Unit = $(df+"Ch2Unit")
		setupchannelDSO("2", V2range, V2scale, V2offset, "DC", Ch2Unit, "", 10.0)
	endif
	// Trigger
	nvar TrigLevel = $(df+"TrigLevel")
	svar TrigSlope = $(df+"TrigSlope")
	setuptriggerDSO("NORMal", "EDGE", "CHANnel1", TrigLevel, TrigSlope, "0", "0")
	svar AcqType = $(df+"AcqType")
	setupacquireDSO(AcqType)
	//setupgeneralDSO("SINGle",0)
end

//Function CheckForTriggerDSO()
//	Variable TrigStat
//	Do
//		TrigStat=QueryDSO(":TER?")
//		if (TrigStat==0)
//			Print "Triggered"
//			Break
//		elseif (TrigStat==1)
//			Print "Not Triggered"
//			Break
//		endif
//		Sleep/S 1
//	While (TrigStat!=1 && TrigStat!=0)
//End

function checktriggerDSO()
	if ((queryDSO(":OPERegister:CONDition?") & 8) == 0)//((trigstat & 0x00000008) == 0)
		return 1
	else
		return 0
	endif
end

//Function TestDSO()
//	OpenDSO()
//	//ResetDSO()
//	DefineMeasurementDSO()
//	SetupDSO(1)
//	CaptureDSO("1")
//	//PauseForUser Pause
//	CheckForTriggerDSO()
//	print "Importing Data"
//	ImportDataDSO("1","current")
//	print "Import Complete"
//	CloseDSO()
//End
//
//Function TestDSO2()
//	OpenDSO()
//	//CaptureDSO("1")
//	//sleep/T 1
//	ImportDataDSO("1","current")
//	CloseDSO()
//End

