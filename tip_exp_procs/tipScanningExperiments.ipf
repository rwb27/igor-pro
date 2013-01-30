#pragma rtGlobals=1		// Use modern global access method.

function scanGo()
	// Run this function when the Scan Go! button is pushed
	// Linear scan master function
	
	// =========================================================================	
	// Pre-scan set-up =============================================================	
	
	if(!(isSaveFolderPathUnique()))			// Check that saveFolderPath is unique
		abort "Specify unique save folder path!!!"
	endif
	
	setupLatestScanFolder()				// Set up latest scan folder
	storeSpectraInformation()				// Make copies of wl_wave, Spectrabkgd, Ref
	
	openOscComms()					// Open Tektronix oscilloscope communications

	NVAR N = root:gVariables:tekOscilloscope:numberOfPoints		// Set number of oscilloscope points to be measured
	N=500
	
	oscStartUp()							// initialize Tektronix oscilloscope
	DSOsetUpForQC()					// initialize Agilent oscilloscope
	
	// PIXIS Setup // ===
	nvar t_range = root:gVariables:agilentOscilloscope:timeRange
	variable trange = t_range * 1e6
	variable shiftrate = 9.2
	variable exp_time = (trange / 256) - shiftrate
	readyPIXIS(exp_time)
	// ==============
	
	smuOutputState(1)					// Turn SMU output on
	
	NVAR scanAppendMode= root:gVariables:tipScanParameters:scanAppendMode		// Scan append mode (0 == new data, 1 == append to last scan)
	
	if(!scanAppendMode)					// If not appending
	
		make/o/n=0 tipCurrent				// Wave for tip-tip current measurement
		make/o/n=0 tipVoltage			// Wave for tip-tip voltage measurement
		make/o/n=0 tipConductance		// Wave for tip-tip conductance measurement
		make/o/n=0 xPSD				// Wave for PSD X-output (mean)
		make/o/n=0 xPSD_stdev			// Wave for PSD X-output (stdev)
		make/o/n=0 yPSD				// Wave for PSD Y-output (mean)
		make/o/n=0 yPSD_stdev			// Wave for PSD Y-output (stdev)
		make/o/n=0 PZdisplacement		// Wave for PSD displacement
		make/o/n=0 timeStamp			// Wave for timeStamping
		make/o/n=0 smuCurrentRange		// Wave for smu current range
		make/o/n=0 liveSpectrum			// Wave to hold live spectrum
		make/o/n=(1044,2) spectra2D		// 2D wave to hold spectra image data
		spectra2D=nan
		
		logScanSettings()					// Log scan settings
		spectraImagePlot()				// Create image plot of spectral data
		execute "tipScanDataPanel()"		// Create tipScanDataPanel for data monitoring
		PZactuator_currPos()				// Update PZ positions from controller
		
	elseif(scanAppendMode)		// If appending, declare waves
		wave tipCurrent, tipVoltage, tipConductance, xPSD, xPSD_stdev, yPSD, yPSD_stdev, PZdisplacement, timeStamp, smuCurrentRange, liveSpectrum, spectra2D
	endif
	
	// Set scales
	setscale/P x, 0,1, tipCurrent, tipVoltage, tipConductance, xPSD, xPSD_stdev, yPSD, yPSD_stdev, PZdisplacement, timeStamp, smuCurrentRange
	
	// =========================================================================	
	// Main Scan loop	 =============================================================
	
	NVAR scanStep = root:gVariables:tipScanParameters:scanStep			// Scan step size
	NVAR scanLength = root:gVariables:tipScanParameters:scanLength		// Scan length
	NVAR direction = root:gVariables:tipScanParameters:scanDirection		// Get scanning direction (-1 for approach, 1 for retract)
	NVAR pos = root:gVariables:PZactuators:posA							// Get PZ initial position
	NVAR currentRange = root:gVariables:keithley2635A:smuCurrentRange		// SMU currentrange
	NVAR q = root:gVariables:tipScanParameters:scanCounter				// Scan counter (global variable for monitoring)
	NVAR currentSetpoint = root:gVariables:tipScanParameters:currentSetpoint	// Scan counter (global variable for monitoring)
	NVAR instr = root:gVariables:agilentOscilloscope:instrDSO				// Agilent DSO VISA address

	variable/C measurementTemp											// I, V measurement intermediate variable
	string spectrumName													// Name of latest spectrum
	string qcTraceName													// Name of latest QC electronics trace
	string qcGtraceName
	string qcForceName													// Name of latest QC force trace
	string qcSpecName													// Name of latest QC kinetics spectra
	variable currentSetpointFlag = 0										// Flag indicating surrent setpoint is reached
	
	// Set approach/retract conditional settings
	if(direction == 1)				
		VISAwrite instr, ":TRIGger:SLOPe NEG"							// if retracting, set to negative slope
	elseif(direction == -1)
		VISAwrite instr, ":TRIGger:SLOPe POS"							// if approaching, set to positive slope
		smuSetCurrentRange(1e-8)									// Set SMU current range to 1e-8 
	endif
	
	variable index
	if(scanAppendMode)													// If appending, set index to previous final scanCounter value
		index = q													
	else
		index = 0														// If not appending, set index to zero
	endif
	
	q = 0																// Set counter to zero
		
	do				
		if(scanStep*q>scanLength)										// Check for exit
			break
		endif
		
		if(currentSetpointFlag!=1)											// If current setpoint has not been reached
			pos = pos + direction*scanStep								// Increment position variable
			// movePI("A",pos)											// Move PZ to new position
			moveRelPI("A",direction*scanStep)								// Move PZ to new position
		endif
		
		// Redimension waves
		redimension/n=(index+1) tipCurrent, tipVoltage, tipConductance, xPSD, xPSD_stdev, yPSD, yPSD_stdev, PZdisplacement, timeStamp, smuCurrentRange	
		
		spectrumName = "root:latestScan:spectra:spectrum_" + num2str(index)  // Update spectrum name
		OO_read()														// Measure spectrum
		duplicate/o root:OO:Data:Current:Spectra, $spectrumName			// Copy measured spectrum to :Spectra folder
		duplicate/o $spectrumName, liveSpectrum							// Copy to live spectrum for monitoring

		duplicate/o spectra2D, spectra2Dtemp								// Make copy of spectra2D
		concatenate/o {spectra2Dtemp, liveSpectrum}, spectra2D				// Append latest spectrum to the spectra2D wave

		measurementTemp = smuMeasureIV()								// Take I, V measurement
		measurementTemp = smuRangeCheck(measurementTemp)			// SMU range check
		tipCurrent[index] = imag(measurementTemp)							// Store current		
		tipVoltage[index] = real(measurementTemp)							// Store voltage
		tipConductance[index] = tipCurrent[index]/tipVoltage[index]/7.7480917e-5 // Calculate conductance
		smuCurrentRange[index] = currentRange							// Store smu current range
		
		xPSD[index] = PSDmeasurement(1,index)							// Measure PSD signal from channel 1
		yPSD[index] = PSDmeasurement(2,index)							// Measure PSD signal from channel 2
			
		timeStamp[index] = ticks/60										// Time stamp (in ~s)
		PZdisplacement[index] = pos										// PZ displacement
		
		if(checktriggerDSO())												// Check for Agilent DSO trigger
			qcTraceName = "root:latestScan:qcElectronics:qcTrace_"+num2str(index)  	// Update qcTrace name									
			importdataDSO("1",qcTraceName)										// Download wave from oscilloscope and store in folder
			qcGTraceName = "root:latestScan:qcElectronics:qcGTrace_"+num2str(index)
			duplicate $qcTraceName, $qcGTraceName
			// Scaling
			wave Gtrace = $qcGTraceName
			nvar gain = root:gVariables:tipScanParameters:transimpedanceGain
			Gtrace /= (gain * tipVoltage[index] * 7.7480917e-5)
			//
			qcForceName = "root:latestScan:qcElectronics:qcForce_"+num2str(index)  	// Update qcForce name
			importdataDSO("2",qcForceName)
			readPIXIS()
			qcSpecName = "root:latestScan:qcElectronics:qcSpec_"+num2str(index)
			duplicate root:PIXIS_256E:current:image, $qcSpecName
			readyPIXIS(exp_time)
			//VISAwrite instr, ":SINGle"												// Reset DSO for single acquisition.
			print "Triggered at " + num2str(index)
			break
		endif 

		doUpdate														// Update graphs

		q = q+1															// Increment counters for next loop
		index = index+1

		if(GetKeyState(0) & 32)											// Check for user abort (escape key)
			string abortString = "Scan aborted at step" + num2str(index)
			print abortString												// Print abort string to window
			string/g root:latestScan:scanLog:abortString = abortString			// Copy abort string to scan log
			break														// Exit loop
		endif
		
//		if(tipCurrent[index]>currentSetpoint && currentSetpointFlag!=1)			// Check for tip current greater than the current setpoint (and currentSetpointFlag being 0)
//			currentSetpointFlag=1											// Set flag to 1
//			print "Entered quantum regime! at " + num2str(q)
//		endif															// Infinite loop now entered, exited by user abort (escape key)
		
	while(1) 																// Exit is via break
	
	if (!checktriggerDSO())													// If not triggered
		cmdDSO(":TRIGger:FORCe")										// Force trigger to correctly reset DSO and PIXIS
	endif
	
	q = index
	
	if(!scanAppendMode)													// If not appending, set index to previous final scanCounter value
		deletePoints/M=1 0,2, spectra2D									// Remove first two columns of spectra2D (added to start to prevent errors)
	endif
	
	killWaves  spectra2Dtemp												// Kill spectra2Dtemp 
	
	ShowInfo/W=tipScanDataPanel											// Add cursors to graphs
	
	setDataFolder root:													// Return to root directory
	backUpLatestScan()													// Copy latest scan data folders to specified folder path	
	
	closeOscComms()													// Close Tektronix oscilloscope communications
	closeDSO()															// Close Agilent oscilloscope communications
	
	saveExperiment														// Save experiment

end


// ======================================================================================
// Sub-routines ============================================================================

function/c smuRangeCheck(measurementTemp)

	variable/c measurementTemp // Last I,V measurement
	
	NVAR currentRange = root:gVariables:keithley2635A:smuCurrentRange		// SMU currentrange
	
	// Current out-of-range control statement
	if(imag(measurementTemp)>1e12)
		currentRange = currentRange*10				// If current overload, increase current range tenfold
		smuSetCurrentRange(currentRange)
		sleep/s 0.2
		measurementTemp = smuMeasureIV()			// Take new I, V measurement
		sleep/s 0.2
		measurementTemp = smuRangeCheck(measurementTemp)		// Check if new measurement is out of range
		return measurementTemp						// Return properly scaled measurement
	endif
	
//	// If not out-of-range, make sure in optimal current range
//	if(imag(measurementTemp) < 9e-9)
//		currentRange = 10e-9
//		smuSetCurrentRange(currentRange)
//		sleep/s 0.2
//		measurementTemp = smuMeasureIV()			// Take new I, V measurement
//		return measurementTemp
//	elseif(imag(measurementTemp) > 9e-9 && imag(measurementTemp) < 90e-9)
//		currentRange = 100e-9
//		smuSetCurrentRange(currentRange)
//		sleep/s 0.2
//		measurementTemp = smuMeasureIV()			// Take new I, V measurement
//		return measurementTemp
//	elseif(imag(measurementTemp) > 90e-9 && imag(measurementTemp) < 90e-6)
//		currentRange = 100e-6
//		smuSetCurrentRange(currentRange)
//		sleep/s 0.2
//		measurementTemp = smuMeasureIV()			// Take new I, V measurement
//		return measurementTemp
//	elseif(imag(measurementTemp) > 90e-6 && imag(measurementTemp) < 90e-3)
//		currentRange = 100e-3
//		smuSetCurrentRange(currentRange)
//		sleep/s 0.2
//		measurementTemp = smuMeasureIV()			// Take new I, V measurement
//		return measurementTemp
//
//	endif
		
	return measurementTemp
end


function PSDmeasurement(channel, q)

	variable channel		// Oscilloscope channel to measure
	variable q 			// Scan counter to name wave with

	string initFolder = getDataFolder(1)		// Get current folder to return to at end
	
	setDataFolder root:latestScan:PSDdata
	
	string wName = "channel"+num2str(channel)+"_"+num2str(q)

	oscGetWave(channel, wName)
	
	// Calculate mean value of measured wave
	wave w = $wName
	variable wMean = mean(w)
	
	setDataFolder $initFolder		// Return to initial folder
	
	// Read mean valueof specified channel from oscilloscope
//	variable wMean = tekRead_mean(channel)
	
	return wMean

end




function spectraImagePlot()			
	// Set-up window and waves for spectra image plot
	
	// Make wavelength image axis
	wave wavelength = root:latestScan:spectra:wavelength
	make/o/n=(numpnts(wavelength)) wavelengthImageAxis
	wavelengthImageAxis = 0.5*(wavelength[p+1]+wavelength[p])
	InsertPoints 0,1, wavelengthImageAxis								// Amend first point
	wavelengthImageAxis[0] = 2*wavelength[0]-wavelengthImageAxis[1]
	wavelengthImageAxis[numpnts(wavelengthImageAxis)-1] = 2*wavelength[numpnts(wavelength)-1] - wavelengthImageAxis[numpnts(wavelengthImageAxis)-2]	// Amend final point
	
//	// Plot 2D spectral image
//	doWindow /k spectraImage	
//	display/n=spectraImage			
//	appendImage spectra2D vs {wavelengthImageAxis,*}
//	setaxis bottom 500,1000
//	modifyImage spectra2D ctab= {*,*,Geo32,0}
//	modifyImage spectra2D ctabAutoscale=1,lookup= $""
//	modifyGraph fSize=16,standoff=0,mirror=1,tick=2
//	modifyGraph height={Aspect,2}
//	label bottom "Wavelength (nm)"
//	label left "Step Number"
//	
end


function isSaveFolderPathUnique()
	
	// Return 0 if and only if saveFolderPath exists and scan is not running in append mode
	
	SVAR saveFolderPath = root:gVariables:tipScanParameters:saveFolderPath
	NVAR scanAppendMode = root:gVariables:tipScanParameters:scanAppendMode

	if(dataFolderExists(saveFolderPath))
		if(!scanAppendMode)
			return 0
		endif
	endif
		return 1

end

function setupLatestScanFolder()
	
	// Make sure latestScan folder structure is set-up correctly
	// If not, set it up correctly
	
	string folderNameString
	
	folderNameString = "root:latestScan"
	if(!(dataFolderExists(folderNameString)))
		newDataFolder $folderNameString
	endif
	
	folderNameString = "root:latestScan:scanLog"
	if(!(dataFolderExists(folderNameString)))
		newDataFolder $folderNameString
	endif
	
	folderNameString = "root:latestScan:PSDdata"
	if(!(dataFolderExists(folderNameString)))
		newDataFolder $folderNameString
	endif
	
	folderNameString = "root:latestScan:spectra"
	if(!(dataFolderExists(folderNameString)))
		newDataFolder $folderNameString
	endif
	
	folderNameString = "root:latestScan:qcElectronics"
	if(!(dataFolderExists(folderNameString)))
		newDataFolder $folderNameString
	endif
		
	NVAR scanAppendMode = root:gVariables:tipScanParameters:scanAppendMode
	
	if(!scanAppendMode)		// If not appending data, delete waves from last scan
		setDataFolder "root:latestScan"
		killWaves/A/Z
		setDataFolder "root:latestScan:PSDdata"
		killWaves/A/Z
		setDataFolder "root:latestScan:spectra"
		killWaves/A/Z
		setDataFolder "root:latestScan:qcElectronics"
		killWaves/A/Z
	endif
	
	setDataFolder "root:latestScan"
	
end

function backUpLatestScan()
	// Copy latest scan folder contents to saveFolderPath
	SVAR saveFolderPath = root:gVariables:tipScanParameters:saveFolderPath	

	killDataFolder/Z saveFolderPath							// Remove existing scan data (only happens when appending)
	duplicateDataFolder root:latestScan, $saveFolderPath			// Duplicate latest scan to saveFolderPath

end

function storeSpectraInformation()
	// Make copies of wl_wave, Spectrabkgd, Ref and store in :spectra folder
	string initPath = getDataFolder(1)		// Current folder, to return to at end
	
	setDataFolder root:latestScan:spectra
	
	duplicate/o root:OO:Data:Current:wl_wave, wavelength			// Copy wavelength
	duplicate/o root:OO:Data:Current:Spectrabkgd, spectraBkgd		// Copy background spectrum	
	duplicate/o root:OO:Data:Current:Ref, spectraRef				// Copy reference spectrum	
	
	setDataFolder $initPath
end

function logScanSettings()

	// Copy important variables to scanLog folder for safe-keeping

	string initPath = getDataFolder(1)		// Current folder, to return to at end

	setDataFolder root:latestScan:scanLog
		
	// Scan parameters
	SVAR globalStrTemp = root:gVariables:tipScanParameters:scanNotes
	string/g scanNotes = globalStrTemp
	NVAR globalTemp = root:gVariables:tipScanParameters:scanLength
	variable/g scanLength = globalTemp
	NVAR globalTemp = root:gVariables:tipScanParameters:scanStep
	variable/g scanStep = globalTemp
	NVAR globalTemp = root:gVariables:tipScanParameters:currentSetpoint
	variable/g currentSetpoint = globalTemp
	
	// PZ parameters
	NVAR globalTemp = root:gVariables:PZactuators:posA
	variable/g PZposA = globalTemp
	NVAR globalTemp = root:gVariables:PZactuators:posB
	variable/g PZposB = globalTemp
	NVAR globalTemp = root:gVariables:PZactuators:posC
	variable/g PZposC = globalTemp
	NVAR globalTemp = root:gVariables:PZactuators:velA
	variable/g PZvelA = globalTemp
	NVAR globalTemp = root:gVariables:PZactuators:dcoA
	variable/g PZdcoA = globalTemp
	NVAR globalTemp = root:gVariables:PZactuators:dcoB
	variable/g PZdcoB = globalTemp
	NVAR globalTemp = root:gVariables:PZactuators:dcoC
	variable/g PZdcoC = globalTemp
	
	
	// Keithley SMU settings
	NVAR globalTemp = root:gVariables:keithley2635A:smuVoltageOutput
	variable/g smuVoltageOutput = globalTemp
//	NVAR globalTemp = root:gVariables:keithley2635A:smuCurrentRange
//	variable/g smuCurrentRange = globalTemp
		
	// Oscilloscope settings
//	NVAR globalTemp = root:gVariables:tekOscilloscope:voltAxis
//	variable/g voltAxis = globalTemp	
//	NVAR globalTemp = root:gVariables:tekOscilloscope:timeAxis
//	variable/g timeAxis = globalTemp
//	NVAR globalTemp = root:gVariables:tekOscilloscope:numberOfPoints
//	variable/g numberOfPoints = globalTemp
	
	// QC and DSO settings
	NVAR globalTemp = root:gVariables:tipScanParameters:transimpedanceGain
	variable/g transimpedanceGain = globalTemp
	NVAR globalTemp = root:gVariables:agilentOscilloscope:triggerLevel
	variable/g DSOtriggerLevel = globalTemp
	
	// CUBE and modulation settings
	NVAR globalTemp = root:gVariables:CUBEcontrol:Cube_State
	variable/g Cube_state = globalTemp
	NVAR globalTemp = root:gVariables:CUBEcontrol:Cube_EXT
	variable/g Cube_EXT = globalTemp
	NVAR globalTemp = root:gVariables:CUBEcontrol:Cube_power
	variable/g Cube_power = globalTemp		
	
	NVAR globalTemp = root:gVariables:Agilent33220A:Agilent33220A_freq
	variable/g Agilent33220A_freq = globalTemp
	NVAR globalTemp = root:gVariables:Agilent33220A:Agilent33220A_Vmin
	variable/g Agilent33220A_Vmin = globalTemp
	NVAR globalTemp = root:gVariables:Agilent33220A:Agilent33220A_Vmax
	variable/g Agilent33220A_Vmax = globalTemp
	SVAR globalStrTemp = root:gVariables:Agilent33220A:Agilent33220A_shape
	string/g Agilent33220A_shape = globalStrTemp	

	
	// Other parameters
	string/g timeStamp = date() + " " + time()
	NVAR globalTemp = root:totalpower				// Fianium power
	variable/g fianiumPower = globalTemp

	setDataFolder $initPath

end


// Functions to replot old scans

function plotConductanceForce(folderName)
	// Display both conductance and PSD signal from the specified datafolder
	string folderName
	setDatafolder folderName

	display tipConductance vs PZdisplacement
	appendtograph/r yPSD, xPSD vs PZdisplacement
	
	label bottom "PZ Displacement (nm)"
	label left "Conductance (/G\\B0\\M)"
	label right "PSD (V)"
	ModifyGraph muloffset(tipConductance)={0,12906.4}
	ModifyGraph mode=4,marker=8,msize=1.5
	
	ModifyGraph tick=2,fSize=16,standoff=0,mirror(bottom)=1
	ModifyGraph log(left)=1
	ModifyGraph width={Aspect,2}	
	ModifyGraph rgb(tipConductance)=(0,0,0),rgb(xPSD)=(0,12800,52224)
	
	// Add label, legend
	Legend/C/N=text0/J/F=0/A=MT/E "\\s(tipConductance) tipConductance \\s(yPSD) yPSD \\s(xPSD) xPSD"
	//string folderName=getDataFolder(1)
	TextBox/C/N=text1/F=0/A=MC getDataFolder(1)
	
	setDataFolder root:			// Return to root
end

function ivScan()
	// Performs an I-V scan using the SMU and settings stored in global variables

	// Declare global variables
	NVAR vStart = root:gVariables:ivScanSettings:vStart
	NVAR vStop = root:gVariables:ivScanSettings:vEnd
	NVAR vStep = root:gVariables:ivScanSettings:vStep

	setUpivScanFolder()							// Create new ivScan folder to store data
	
	logivScanInfo()								// Log information

	NVAR vInit = root:gVariables:keithley2635A:smuVoltage	// Store initial voltage, to return to at end of scan
	
	smuVoltageSet(vStart)						// Set voltage output to starting value
	
	smuOutputState(1)							// Turn on output
	
	make/o/n=0 voltage, current, conductance		// Make voltage, current, and conductance waves
	
	display current vs voltage						// Plot I-V and G-V curve for live update
	//appendtograph/r conductance vs voltage			
	
	variable q = 0, vSet = vStart					// Declare loop counter and voltage variable
	variable/C measurementTemp					// Temporary variable to hold measurement
	
	do
		vSet = vSet + vStep										// Increment voltage
		smuVoltageSet(vSet)										// Set voltage output
	
		redimension/n=(q+1) voltage, current, conductance			// Redimension waves for next measurement
				
		measurementTemp = smuMeasureIV() 						// Take measurement
		measurementTemp = smuRangeCheck(measurementTemp)	// SMU range check
		
		voltage[q] = real(measurementTemp)						// Store voltage
		current[q] = imag(measurementTemp)						// Store current
		conductance[q] = current[q]/voltage[q]/7.748091e-5			// Calculate conductance (normalized to G0)
		
		doUpdate												// Update plot		
		q = q+1													// Increment loop counter
	while(vSet< vStop)
	
	smuVoltageSet(vInit)							// Reset voltage
	
	setDataFolder root:							// Return to root directory
	
end

function setUpivScanFolder()
	// Create unique folder to hold ivScan data
	string currDate = date()
	string day, monthYear
	
	day = "day"+currDate[0,1]
	monthYear = currDate[3,5]+currDate[7,10]

	string dirPath = "root:data:"+monthYear+":"+day+":ivScan"
	if(!dataFolderExists(dirPath))
		newDataFolder $dirPath
	endif	

	// Find unique scan number
	variable q = 1
	do
		dirPath = "root:data:"+monthYear+":"+day+":ivScan:"+"scan_"+num2str(q)
		if(!dataFolderExists(dirPath))
			newDataFolder/s $dirPath
			break
		endif		
		q = q+1
	while(1)

end

function logivScanInfo()
	
	// Scan parameters to store in scan folder
	SVAR globalStrTemp = root:gVariables:tipScanParameters:saveFolderPath
	string/g scanFolderPath = globalStrTemp
	
	NVAR globalTemp = root:gVariables:tipScanParameters:scanCounter
	variable/g scanCounter = globalTemp
	
	string/g timeStamp = date() + " " + time()
	

end

function forceConductancePlot()
	// Create plot to monitor current, PSD signal
	doWindow /k ForceConductance										
	display/N=ForceConductance tipConductance vs PZdisplacement
	appendtograph/r xPSD, yPSD vs PZdisplacement
	label left "Conductance (G0)";	label bottom "PZ displacement (um)"; label right "PSD Signal (V)"
	modifyGraph fSize=16,standoff=0,mirror(bottom)=1,tick=2,log(left)=1
	modifyGraph margin=0,width=340.157,height={Aspect,0.5}
	modifyGraph mode=4,marker=8,rgb(tipConductance)=(0,0,0),rgb(xPSD)=(0,15872,65280),rgb(yPSD)=(65280,0,0)
	modifyGraph muloffset(tipConductance)={0,12906.4}
	Legend/C/N=text0/A=MT/E
end

function liveSpectrumPlot()
	// Create plot to monitor spectra as they are taken
	doWindow /k liveSpectrum	
	display/N=liveSpectrum liveSpectrum vs :spectra:wavelength
	setaxis/a=2
	setaxis bottom 500,1000
	modifyGraph fSize=16,standoff=0,mirror=1,tick=2
end


//==================================================================
//==================================================================
//==================================================================


Window tipScanDataPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	doWindow /k tipScanDataPanel
	NewPanel /N=tipScanDataPanel/W=(50,50,950,550)
	ShowTools/A
	ShowInfo/W=tipScanDataPanel
	SetDataFolder root:latestScan:
	
	// Spectral image
	Display/W=(0,0,0.4,1)/HOST=# 
	AppendImage spectra2D vs {wavelengthImageAxis,*}
	ModifyImage spectra2D ctab= {*,*,Geo32,0}
	ModifyImage spectra2D ctabAutoscale=1
	ModifyGraph tick=2
	ModifyGraph mirror=1
	ModifyGraph fSize=16
	ModifyGraph standoff=0
	ModifyGraph margin(top)=57
	Label left "Step Number"
	Label bottom "Wavelength (nm)"
	SetAxis bottom 500,1000
	
	cursor/P/I/H=1 A spectra2D 550,0
	
	RenameWindow #,spectraImage
	SetActiveSubwindow ##	
	
	// Conductance/force
	Display/W=(0.4,0,0.67,1)/HOST=#  tipCurrent
	AppendToGraph/R xPSD,yPSD
	ModifyGraph mode=4
	ModifyGraph marker=8
	ModifyGraph rgb(tipCurrent)=(0,0,0),rgb(xPSD)=(0,15872,65280),rgb(yPSD)=(65280,0,0)
	//ModifyGraph muloffset(tipCurrent)={0,12906.4}
	ModifyGraph log(left)=1
	ModifyGraph tick=2
	ModifyGraph mirror(bottom)=1
	ModifyGraph fSize=16
	ModifyGraph standoff=0
	Label left "\\K(0,0,0)tipCurrent (A)"
	Label right "PSD Signal (\\K(0,15872,65280)x \\K(65280,0,0) y\\K(65280,0,0))"
	//Legend/C/N=text0/J/X=-15/Y=5 "\\s(tipConductance) tipConductance\r\\s(xPSD) xPSD\r\\s(yPSD) yPSD"
	ModifyGraph swapXY=1
	
	Cursor/P A yPSD 0
	
	RenameWindow #,ForceConductance
	SetActiveSubwindow ##
	
	// Live spectrum
	Display/W=(0.67,0.5,1,1)/HOST=#  liveSpectrum vs :spectra:wavelength
	ModifyGraph tick=2
	ModifyGraph mirror=1
	ModifyGraph fSize=16
	ModifyGraph standoff=0
	Label left "Scattering"
	Label bottom "Wavelength (nm)"
	SetAxis/A=2 left
	SetAxis bottom 500,1000
	ModifyGraph lsize=2,rgb=(0,34816,52224)
	
	Cursor/P A liveSpectrum 550
	
	RenameWindow #,liveSpectrum
	SetActiveSubwindow ##
	
	// PZ displacement
	Display/W=(0.67,0,1,0.5)/HOST=#  PZdisplacement
	ModifyGraph tick=2
	ModifyGraph mirror=1
	ModifyGraph fSize=16
	ModifyGraph standoff=0
	Label left "PZ (nm)"
	Label bottom "Step Number"
	ModifyGraph muloffset={0,1000}
	ModifyGraph lsize=2,rgb=(0,0,0)
	ModifyGraph swapXY=1
	
	Cursor/P A PZdisplacement 0
	
	RenameWindow #,PZdisplacement
	SetActiveSubwindow ##

	
	//setDataFolder root:
	
EndMacro

Window TipScanningPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(680,106,1088,678)
	ShowTools/A
	SetDrawLayer UserBack
	SetDrawEnv fsize= 16,fstyle= 1
	DrawText 9,28,"Scan Settings"
	SetDrawEnv fsize= 14
	DrawText 14,50,"Keithley 2635A SMU"
	SetDrawEnv fsize= 14
	DrawText 230,50,"PZ Parameters"
	SetDrawEnv fsize= 14
	DrawText 14,189,"Quantum QC - Agilent DSO settings"
	SetDrawEnv fsize= 14
	DrawText 14,325,"Scan Archiving"
	SetDrawEnv fsize= 14
	DrawText 298,141,"Approach = -1"
	SetDrawEnv fsize= 14
	DrawText 318,168,"Retract = 1"
	SetDrawEnv fsize= 16,fstyle= 1
	DrawText 88,536,"Hold escape key to abort scan"
	SetDrawEnv fsize= 14
	DrawText 336,154,"Hold = 0"
	SetVariable setvar0,pos={40,57},size={121,20},bodyWidth=50,title="Voltage (V)"
	SetVariable setvar0,fSize=14
	SetVariable setvar0,limits={-1,1,0},value= root:gVariables:keithley2635A:smuVoltageOutput
	Button button0,pos={170,57},size={50,20},proc=ButtonProc_29,title="Set",fSize=14
	SetVariable setvar2,pos={2,81},size={160,20},bodyWidth=50,title="Current Range (A)"
	SetVariable setvar2,fSize=14
	SetVariable setvar2,limits={-1,1,0},value= root:gVariables:keithley2635A:smuCurrentRange
	Button button2,pos={170,82},size={50,20},proc=ButtonProc_30,title="Set",fSize=14
	Button button1,pos={161,108},size={60,50},proc=ButtonProc_24,title="Output\rOn"
	Button button1,fSize=14,fColor=(0,52224,0)
	Button button3,pos={83,108},size={60,50},proc=ButtonProc_25,title="Output\rOff"
	Button button3,fSize=14,fColor=(65280,0,0)
	SetVariable setvar1,pos={247,53},size={140,20},bodyWidth=50,title="Step Size (um)"
	SetVariable setvar1,fSize=14
	SetVariable setvar1,limits={-inf,inf,0},value= root:gVariables:tipScanParameters:scanStep
	SetVariable setvar3,pos={230,78},size={157,20},bodyWidth=50,title="Scan Length (um)"
	SetVariable setvar3,fSize=14
	SetVariable setvar3,limits={-inf,inf,0},value= root:gVariables:tipScanParameters:scanLength
	SetVariable setvar4,pos={19,361},size={373,20},bodyWidth=300,title="Folder Path"
	SetVariable setvar4,fSize=14
	SetVariable setvar4,value= root:gVariables:tipScanParameters:saveFolderPath
	Button button5,pos={6,108},size={60,50},title="Initialize",fSize=14
	Button button5,fColor=(0,52224,52224)
	CheckBox check2,pos={19,336},size={170,16},proc=CheckProc,title="Append to Previous Scan"
	CheckBox check2,fSize=14,value= 1
	SetVariable setvar5,pos={19,389},size={374,20},bodyWidth=300,title="Scan Notes"
	SetVariable setvar5,fSize=14,value= root:gVariables:tipScanParameters:scanNotes
	SetVariable setvar6,pos={35,196},size={115,20},bodyWidth=50,title="Ch1 Gmax"
	SetVariable setvar6,fSize=14
	SetVariable setvar6,limits={-inf,inf,0},value= root:gVariables:agilentOscilloscope:G1max
	SetVariable setvar7,pos={163,244},size={147,20},bodyWidth=50,title="Time Range (s)"
	SetVariable setvar7,fSize=14
	SetVariable setvar7,limits={-inf,inf,0},value= root:gVariables:agilentOscilloscope:timeRange
	Button button7,pos={316,196},size={80,25},proc=ButtonProc_34,title="SetUp"
	Button button7,fSize=14,fColor=(0,52224,52224)
	Button button9,pos={14,422},size={379,91},proc=ButtonProc_33,title="Scan Go!"
	Button button9,fSize=20,fColor=(0,52224,0)
	ValDisplay valdisp0,pos={242,307},size={146,48},bodyWidth=75,title="\\JRScan\rCounter"
	ValDisplay valdisp0,fSize=20,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp0,value= #"root:gVariables:tipScanParameters:scanCounter"
	SetVariable setvar9,pos={247,103},size={141,20},bodyWidth=50,title="Scan Direction"
	SetVariable setvar9,fSize=14
	SetVariable setvar9,limits={-1,1,1},value= root:gVariables:tipScanParameters:scanDirection
	SetVariable setvar8,pos={196,196},size={114,20},bodyWidth=50,title="Ch2 Vmax"
	SetVariable setvar8,fSize=14
	SetVariable setvar8,limits={-inf,inf,0},value= root:gVariables:agilentOscilloscope:volt2max
	SetVariable setvar10,pos={39,220},size={111,20},bodyWidth=50,title="Ch1 Gmin"
	SetVariable setvar10,fSize=14
	SetVariable setvar10,limits={-inf,inf,0},value= root:gVariables:agilentOscilloscope:G1min
	SetVariable setvar11,pos={200,220},size={110,20},bodyWidth=50,title="Ch2 Vmin"
	SetVariable setvar11,fSize=14
	SetVariable setvar11,limits={-inf,inf,0},value= root:gVariables:agilentOscilloscope:volt2min
	SetVariable setvar12,pos={10,244},size={140,20},bodyWidth=50,title="Time Offset (s)"
	SetVariable setvar12,fSize=14
	SetVariable setvar12,limits={-inf,inf,0},value= root:gVariables:agilentOscilloscope:timeOffset
	SetVariable setvar13,pos={153,267},size={157,22},bodyWidth=50,title="Trigger level (G\\B0\\M)"
	SetVariable setvar13,fSize=14
	SetVariable setvar13,limits={-inf,inf,0},value= root:gVariables:agilentOscilloscope:triggerLevel
	SetVariable setvar14,pos={5,269},size={145,20},bodyWidth=50,title="Transimp. Gain"
	SetVariable setvar14,fSize=14
	SetVariable setvar14,limits={-inf,inf,0},value= root:gVariables:tipScanParameters:transimpedanceGain
	Button button8,pos={316,222},size={80,40},proc=ButtonProc_38,title="Set\rParameters"
	Button button8,fSize=14,fColor=(47872,47872,47872)
	Button button4,pos={316,264},size={80,25},proc=ButtonProc_39,title="Single"
	Button button4,fSize=14,fColor=(47872,47872,47872)
EndMacro


Function ButtonProc_32(ba) : ButtonControl

	// Set number of points to measure at oscilloscope

	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_33(ba) : ButtonControl

	// Run scan

	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			scanGo()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function ButtonProc_35(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// Set oscilloscope time scale
//				NVAR timescale = root:gVariables:tekOscilloscope:timeAxis
//				string cmd = "HOR:MAI:SCA " + num2str(timeScale)
//				tekCmd(cmd)
//				
//				tekSetup()			// Update scaling factors
			// click code here
			break
	endswitch

	return 0
End

Function ButtonProc_36(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// Set oscilloscope vert scale
//				NVAR voltAxis = root:gVariables:tekOscilloscope:voltAxis
//				string cmd 
//				cmd = "CH1:SCA " + num2str(voltAxis)
//				tekCmd(cmd)
//				cmd = "CH2:SCA " + num2str(voltAxis)
//				tekCmd(cmd)
//				
//				tekSetup()			// Update scaling factors
			// click code here
			break
	endswitch

	return 0
End

Function ButtonProc_37(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
//			// Set oscilloscope number of points to measure
//			
//			// Set Channel 1  
//			string cmd="DAT:SOU CH1"
//			tekCmd(cmd)
//			// Set number of points to read 
//			NVAR N = root:gVariables:tekOscilloscope:numberOfPoints
//			cmd = "DAT:STAR 1"				
//			tekCmd(cmd)
//			cmd = "DAT:STOP " + num2str(N)	
//			tekCmd(cmd)
//			
//			// Set Channel 2
//			cmd="DAT:SOU CH2"
//			tekCmd(cmd)
//			// Set number of points to read 
//			NVAR N = root:gVariables:tekOscilloscope:numberOfPoints
//			cmd = "DAT:STAR 1"				
//			tekCmd(cmd)
//			cmd = "DAT:STOP " + num2str(N)	
//			tekCmd(cmd)
//		
//			// click code here
			break
	endswitch

	return 0
End


Function CheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			controlInfo check2
			if(V_Value == 0)	// If control is deselected, set scanAppendMode to zero
				NVAR scanAppendMode = root:gVariables:tipScanParameters:scanAppendMode
				scanAppendMode = 0
				break
			endif		
			if(V_Value == 1)	// If control is selected, set scanAppendMode to zero
				NVAR scanAppendMode = root:gVariables:tipScanParameters:scanAppendMode
				scanAppendMode = 1
				break
			endif

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_31(ba) : ButtonControl
	// Run I-V Scan
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			ivScan()				// Execute I-V scan with SMU
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_34(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// Oscilloscope set-up
			DSOsetUp()
			break
	endswitch

	return 0
End

Function ButtonProc_38(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DSOsetParameters()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


function DSOsetUp()

	closeDSO()		// Close comms
	openDSO()		// Open comms
	
	// Sets Agilent state to specified 
//
	NVAR instr = root:gVariables:agilentOscilloscope:instrDSO
		
	//General Setup
	VISAwrite instr, "*RST"									// Reset
	//VISAwrite instr, ":AUToscale"								// Autoscale for initial settings
	VISAwrite instr, ":RUN"
	

//	// Channel 1 Voltage Setup
	VISAwrite instr, ":CHANnel1:PROBe 1"						// Probe attenuation to 1:1.
	
	// Channel 2 Voltage Setup
	VISAwrite instr, ":CHANnel2:DISP 1"						// Turn channel on
	VISAwrite instr, ":CHANnel2:PROBe 1"						// Probe attenuation to 1:1.

	// Trigger Setup
	VISAwrite instr, ":TRIGger:SWEep AUTO"					// Set normal triggering.
	VISAwrite instr, ":TRIGger:LEVel "+num2str(1)				// Set trigger level
	
	// Acquisition Setup
	VISAwrite instr, ":ACQuire:TYPE NORMal"					// Normal acquisition.
	

end

function DSOsetParameters()

	closeDSO()		// Close comms
	openDSO()		// Open comms
	
	// Sets Agilent state to specified 
//
	NVAR instr = root:gVariables:agilentOscilloscope:instrDSO
	NVAR timeRange = root:gVariables:agilentOscilloscope:timeRange
	NVAR timeOffset = root:gVariables:agilentOscilloscope:timeOffset
	NVAR G1max = root:gVariables:agilentOscilloscope:G1max
	NVAR G1min = root:gVariables:agilentOscilloscope:G1min
	NVAR volt2max = root:gVariables:agilentOscilloscope:volt2max
	NVAR volt2min = root:gVariables:agilentOscilloscope:volt2min
	NVAR voltLevel = root:gVariables:agilentOscilloscope:triggerLevel
	NVAR triggerLevel = root:gVariables:agilentOscilloscope:triggerLevel
	
	// Convert trigger level from G0s to volts
	NVAR voltage = root:gVariables:keithley2635A:smuVoltageOutput						// SMU output voltage
	NVAR transimpedanceGain = root:gVariables:tipScanParameters:transimpedanceGain	// Transimpedance gain
	variable triggerInVolts = transimpedanceGain*triggerLevel*7.74809e-5*voltage
			
	// Convert Vmax from G0s to volts
	variable volt1max = transimpedanceGain*G1max*7.74809e-5*voltage
	
	// Convert Vmin from G0s to volts
	variable volt1min = transimpedanceGain*G1min*7.74809e-5*voltage
	
			
	//General Setup
	VISAwrite instr, ":RUN"

	// Timebase Setup
	VISAwrite instr, ":TIMebase:RANGe "+num2str(timeRange)	// Set time range
	VISAwrite instr, ":TIMebase:DELay "+num2str(timeOffset)		// Set time delay
	VISAwrite instr, ":TIMebase:REFerence CENT"				// Display ref. at center.

	// Channel 1 Voltage Setup
	VISAwrite instr, ":CHANnel1:PROBe 1"						// Probe attenuation to 1:1.	
	VISAwrite instr, ":CHANnel1:RANGe "+num2str(volt1max-volt1min)	// Vertical range 
	VISAwrite instr, ":CHANnel1:OFFSet "+num2str(0.5*(volt1max+volt1min))	// Vertical offset
	
	// Channel 2 Voltage Setup
	VISAwrite instr, ":CHANnel2:DISP 1"						// Turn channel on
	VISAwrite instr, ":CHANnel2:PROBe 1"						// Probe attenuation to 1:1.
	VISAwrite instr, ":CHANnel2:RANGe "+num2str(volt2max-volt2min)	// Vertical range 
	VISAwrite instr, ":CHANnel2:OFFSet "+num2str(0.5*(volt2max+volt2min))	// Vertical offset

	// Trigger Setup
	VISAwrite instr, ":TRIGger:SWEep AUTO"					// Set normal triggering.
	VISAwrite instr, ":TRIGger:LEVel "+num2str(triggerInVolts)		// Set trigger level
	
	// Acquisition Setup
	VISAwrite instr, ":ACQuire:TYPE NORMal"					// Normal acquisition.
	

end

function DSOsetUpForQC()

	closeDSO()		// Close comms
	openDSO()		// Open comms
	
	DSOsetParameters()	// Sets Agilent state to specified parameters
	
	NVAR instr = root:gVariables:agilentOscilloscope:instrDSO
	VISAwrite instr, ":SINGle"									// Set for single acquisition.


end



Function ButtonProc_39(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here

			NVAR instr = root:gVariables:agilentOscilloscope:instrDSO
			VISAwrite instr, ":SINGle"						// Set single trigger
			VISAwrite instr, ":TRIGger:SLOPe EITHer"										
						
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
