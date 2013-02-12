#pragma rtGlobals=1		// Use modern global access method.

// Keithley 2635A routines written by mh654

function stabilityTest1()

	// Initialize SMU
	smuInitialize()
	
	// Set voltage output
	smuVoltageSet(100e-6)
	
	// Turn on output
	smuOutputState(1)
	
	// Take N voltage and/or current measurements with sampling interval delay
	variable N = 400, delay = 0.1
	
	make/o/n=0 voltages, currents	
	variable q = 0
	variable/C reading
	
	variable timerRef = startMStimer
	
	
	do
		redimension/n=(q+1) voltages, currents
		
		reading = smuMeasureIV() 
		voltages[q] = real(reading)
		currents[q] = imag(reading)
		
		//doUpdate
		//sleep/s delay
		
		q = q+1
	while(q<N)
	
	print stopMStimer(timerRef)/1e6
	
	// Turn off output
	smuOutputState(0)

end

function conductanceTest1(vStart, vEnd, vInterval)

	variable vStart, vEnd, vInterval

	// Initialize SMU
	smuInitialize()
	
	// Set voltage output
	smuVoltageSet(vStart)
	
	// Turn on output
	smuOutputState(1)
	
	// Sampling interval delay
	variable delay=2
	
	make/o/n=0 voltages, currents	
	variable q = 0, vSet
	variable/C reading
	
	do
		// Set voltage output
		vSet = vStart + vInterval*q
		smuVoltageSet(vSet)
	
		redimension/n=(q+1) voltages, currents
		//voltages[q] = smuMeasureVoltage()
		//currents[q] = smuMeasureCurrent()
		
		reading = smuMeasureIV() 
		voltages[q] = real(reading)
		currents[q] = imag(reading)
		
		doUpdate
		//sleep/s delay
		
		q = q+1
	while(vSet != vEnd)
	
	// Turn off output
	smuOutputState(1)

end


function smuInitialize()

	variable session, instr, status
	string resourceName="GPIB0::26::INSTR"
	string cmd
	
	// Open communicaton
	status=viOpenDefaultRM(session)
	status=viOpen(session,resourceName,0,0,instr)
	
	// Restore to default settings
	cmd = "smua.reset()"
	VISAwrite instr, cmd
	
	// Set current measure range to 1 nA
	cmd = "smua.measure.rangei = 10e-9"
	VISAwrite instr, cmd
	
	// Close communication
	status = viClose(session)

end

function smuSetCurrentRange(currentRange)
	// Set SMU current measurement range
	variable currentRange

	variable session, instr, status
	string resourceName="GPIB0::26::INSTR"
	string cmd
	
	// Open communicaton
	status=viOpenDefaultRM(session)
	status=viOpen(session,resourceName,0,0,instr)
	
	// Set current measure range to 1 nA
	cmd = "smua.measure.rangei = " + num2str(currentRange)
	VISAwrite instr, cmd
	
	// Close communication
	status = viClose(session)

end

function smuVoltageSet(voltage)

	variable voltage

	variable session, instr, status
	string resourceName="GPIB0::26::INSTR"
	string cmd
	
	// Open communicaton
	status=viOpenDefaultRM(session)
	status=viOpen(session,resourceName,0,0,instr)
	
	// Set to source voltage
	cmd = "smua.source.func=smua.OUTPUT_DCVOLTS"
	VISAwrite instr, cmd
	
	// Set to specified value
	cmd = "smua.source.levelv = " + num2str(voltage)
	VISAwrite instr, cmd

	// Close communication
	status = viClose(session)

end

function smuMeasureVoltage()

	variable session, instr, status, voltage
	string resourceName="GPIB0::26::INSTR"
	string cmd
	
	// Open communicaton
	status=viOpenDefaultRM(session)
	status=viOpen(session,resourceName,0,0,instr)
	
	// Measure voltage
	cmd = "print(smua.measure.v())"
	VISAwrite instr, cmd
	VISAread instr, voltage
	
	// Close communication
	status = viClose(session)
	
	return voltage

end

function/C smuMeasureIV()

	variable session, instr, status, voltage, current
	variable/C output
	string resourceName="GPIB0::26::INSTR"
	string cmd
	
	// Open communicaton
	status=viOpenDefaultRM(session)
	status=viOpen(session,resourceName,0,0,instr)
	
	// Measure voltage
	cmd = "iRead, vRead = smua.measure.iv()"
	VISAwrite instr, cmd
	
	cmd = "print(vRead)"
	VISAwrite instr, cmd	
	VISAread instr, voltage
	
	cmd = "print(iRead)"
	VISAwrite instr, cmd	
	VISAread instr, current
		
	// Close communication
	status = viClose(session)
	
	output = cmplx(voltage,current)
	
	return output

end

function smuReadBuffer()

	variable session, instr, status, voltage, current, output
	string resourceName="GPIB0::26::INSTR"
	string cmd
	
	// Open communicaton
	status=viOpenDefaultRM(session)
	status=viOpen(session,resourceName,0,0,instr)
	
	// Measure voltage

	cmd = "print(vRead)"
	VISAwrite instr, cmd	
	VISAread instr, voltage

	// Close communication
	status = viClose(session)
	
	output = voltage
	
	return output

end

function smuMeasureVoltage2()

	variable session, instr, status, voltage
	string resourceName="GPIB0::26::INSTR"
	string cmd
	
	// Open communicaton
	status=viOpenDefaultRM(session)
	status=viOpen(session,resourceName,0,0,instr)
	
	// Measure voltage
	VISAread instr, voltage
		
	// Close communication
	status = viClose(session)
	
	return voltage

end

function smuMeasureCurrent()

	variable session, instr, status, current
	string resourceName="GPIB0::26::INSTR"
	string cmd
	
	// Open communicaton
	status=viOpenDefaultRM(session)
	status=viOpen(session,resourceName,0,0,instr)
	
	// Measure voltage
	cmd = "print(smua.measure.i())"
	VISAwrite instr, cmd
	VISAread instr, current
	
	// Close communication
	status = viClose(session)
	
	return current

end

function smuMeasureResistance()

	variable session, instr, status, current
	string resourceName="GPIB0::26::INSTR"
	string cmd
	
	// Open communicaton
	status=viOpenDefaultRM(session)
	status=viOpen(session,resourceName,0,0,instr)
	
	// Measure voltage
	cmd = "print(smua.measure.r())"
	VISAwrite instr, cmd
	VISAread instr, current
	
	// Close communication
	status = viClose(session)
	
	return current

end

function smuOutputState(state)
	// Turns output on (state == 1) or off (state ==0)
	variable state

	variable session, instr, status
	string resourceName="GPIB0::26::INSTR"
	string cmd
	
	// Open communicaton
	status=viOpenDefaultRM(session)
	status=viOpen(session,resourceName,0,0,instr)
	
	// Set to output
	if (state == 0 || state == 1)
		cmd = "smua.source.output="+num2str(state)
		VISAwrite instr, cmd
	else
		print "Incorrect state variable"
	endif

	// Close communication
	status = viClose(session)

end

function/S smuGetError()

	variable session, instr, status
	string resourceName="GPIB0::26::INSTR"
	string cmd, errorMessage, error, message
	
	// Open communicaton
	status=viOpenDefaultRM(session)
	status=viOpen(session,resourceName,0,0,instr)
	
	// Measure voltage
	cmd = "errorCode, message = errorqueue.next()"
	VISAwrite instr, cmd
	
	cmd = "print(errorCode)"
	VISAwrite instr, cmd
	VISAread instr, error
	
	cmd = "print(message)"
	VISAwrite instr, cmd
	VISAread instr, message

	// Close communication
	status = viClose(session)
	
	errorMessage = error + ": " + message
	return errorMessage
	
end

////////////////////////////////////////////
// Bandwidth test

function smuBandwidthTest(currentRange,N)
	
	// Take N measurements in currentRange setting and time them
	
	variable currentRange, N
	smuSetCurrentRange(currentRange)
	
	
	
	// Call extra measurement to clear buffer
	smuMeasureIV()
	 
	variable q = 0, qMax = N, timerReference
	make/o/n=(qMax) measurementTime, measurementCurrent, measurementVoltage
	variable/C measurementTemp	// Temporary variable to hold measured value
	
	do
		// Start timer
		timerReference = startMStimer		
		
		// Take measurement
		//measurementCurrent[q] = smuMeasureCurrent()
		measurementTemp = smuMeasureIV()	
		
		// Stop timer
		measurementTime[q] = stopMStimer(timerReference)
		
		// Convert measurement
		measurementTime[q] = measurementTime[q]/1e6
		measurementVoltage[q] = real(measurementTemp)
		measurementCurrent[q] = imag(measurementTemp)
		
		doUpdate
		q=q+1
	while(q<qMax)

end



//////////////////////////////////////////////////////////////
// Control Panel


Function ButtonProc_24(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			// Turn output on
			smuOutputState(1)
			break
	endswitch

	return 0
End

Function ButtonProc_25(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			// Turn output on
			smuOutputState(0)
			break
	endswitch

	return 0
End

Function ButtonProc_26(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			// Measure SMU voltage
			NVAR voltage = root:gVariables:keithley2635A:smuVoltage
			voltage = smuMeasureVoltage()
			
			break
	endswitch

	return 0
End

Function ButtonProc_27(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			// Measure SMU voltage
			NVAR current = root:gVariables:keithley2635A:smuCurrent
			current = smuMeasureCurrent()
			
			break
	endswitch

	return 0
End

Function ButtonProc_28(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			// Measure SMU voltage
			NVAR current = root:gVariables:keithley2635A:smuCurrent
			NVAR voltage = root:gVariables:keithley2635A:smuVoltage

			variable/C measurement = smuMeasureIV()
			voltage = real(measurement)
			current = imag(measurement)
		
			break
	endswitch

	return 0
End

Function ButtonProc_29(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			// Set SMU voltage
			NVAR voltage = root:gVariables:keithley2635A:smuVoltageOutput
			smuVoltageSet(voltage)
		
			break
	endswitch

	return 0
End

Function ButtonProc_30(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			// Set SMU voltage
			NVAR currentRange = root:gVariables:keithley2635A:smuCurrentRange
			smuSetCurrentRange(currentRange)
		
			break
	endswitch

	return 0
End
