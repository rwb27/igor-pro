#pragma rtGlobals=1		// Use modern global access method.

// Functions to communicate with the SR830 lock-in amplifier


// Read XY output from Lock-in
function/c SR830_XY()
	
	variable/C data
	variable data1, data2

	data1 = str2num(cmdSR830_1("OUTP?1\r"))
	data2 = str2num(cmdSR830_1("OUTP?2\r"))
	
	data = cmplx(data1, data2)
	return data
end

// Read R,theta output from Lock-in
function/c SR830_Rtheta()
	
	variable/C data
	variable data1, data2

	data1 = str2num(cmdSR830_1("OUTP?3\r"))
	data2 = str2num(cmdSR830_1("OUTP?4\r"))
	
	data = cmplx(data1, data2)
	return data
end

// Test communication with SR830

function SR830_test()

	variable status, instr, session
	
	string resourceName = "GPIB0::6::INSTR", buffer

	status = viOpenDefaultRM(session)	
	status = viOpen(session, resourceName, 0, 0, instr) 
	
	VISAwrite instr, "*IDN?\r"
	
	VISAread instr, buffer
	print buffer
	
	status = viClose(instr)
	status = viClose(session)

end

// Write/Read to SR830
function/S cmdSR830_1(cmd)		// sends a cmd string to SR830 and gets back return string

	string cmd
	
	// Open communication to instrument
	variable status, instr, session
	string resourceName = "GPIB0::6::INSTR"

	status = viOpenDefaultRM(session)	
	status = viOpen(session, resourceName, 0, 0, instr) 
	
	// Write and read commands
	string buffer = "" 			// String to hold instrument response
	if (strlen(cmd)>0)				// only write if string is not empty
 		VISAWrite instr, cmd
	endif
	VISARead instr, buffer		// Read response

	// Close communications
	status = viClose(instr)
	status = viClose(session)
	
	return(buffer)				// Return response
	
end

function purgeSR830_1()
	// Purge SR830 return buffer

	// Open communication to instrument
	variable status, instr, session
	string resourceName = "GPIB0::6::INSTR"

	status = viOpenDefaultRM(session)	
	status = viOpen(session, resourceName, 0, 0, instr) 	 
	
	variable retCnt = 0
	string buffer = ""
	do
		VISAread instr, buffer
		retCnt = strlen(buffer)
		print buffer
	while(retCnt > 0)
	// Close communications
	status = viClose(instr)
	status = viClose(session)
end
