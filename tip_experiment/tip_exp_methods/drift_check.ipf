#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function log_afm_dc(afm1wave, afm2wave, afm3wave, afm4wave)
	wave afm1wave, afm2wave, afm3wave, afm4wave
	tek#open_comms()
	
	// setup measurements
	tek#get_waveform_params("1")
	tek#get_waveform_params("2")
	variable i, keys
	variable scan_rate = 1.0 / 50e3
	make/o/n=5000 root:force_y, root:force_x
	wave force_y, force_x
	setscale/p x, 0, scan_rate, "s", force_y, force_x
	
	display /k=1 afm1wave
	appendtograph/r afm2wave
	modifygraph rgb[1]=(0,0,65280)
	display /k=1 afm3wave
	appendtograph/r afm4wave
	modifygraph rgb[1]=(0,0,65280)
	
	// take measurements
	do
		// get loop key controls
		keys = getkeystate(0)
		if (keys & 32)			// manual escape (esc)
			break
		endif
		
		i=numpnts(afm1wave)
		redimension/n=(i+1) afm1wave, afm2wave, afm3wave, afm4wave
		
		//// store waveform analysis
		tek#import_data("1", "afm1")
		tek#import_data("2", "afm2")
		wave/sdfr=root:tektronix_tds1001b_dso afm1, afm2
		afm1wave[i] = mean(afm1)
		afm2wave[i] = mean(afm2)
		
		DAQmx_Scan/dev="dev1" WAVES="force_y, 1/diff; force_x, 2/diff;"
		afm3wave[i] = mean(force_y)
		afm4wave[i] = mean(force_x)
		
		DoUpdate
	while(1)
end

function log_afm_dc_DAQ(afm3wave, afm4wave)
	wave afm3wave, afm4wave
	
	// setup measurements
	variable i, keys
	variable scan_rate = 1.0 / 50e3
	make/o/n=5000 root:force_y, root:force_x
	wave force_y, force_x
	setscale/p x, 0, scan_rate, "s", force_y, force_x
	
	display /k=1 afm3wave
	appendtograph/r afm4wave
	modifygraph rgb[1]=(0,0,65280)
	
	// take measurements
	do
		// get loop key controls
		keys = getkeystate(0)
		if (keys & 32)			// manual escape (esc)
			break
		endif
		
		i=numpnts(afm3wave)
		redimension/n=(i+1) afm3wave, afm4wave
		
		DAQmx_Scan/dev="dev1" WAVES="force_y, 1/diff; force_x, 2/diff;"
		afm3wave[i] = mean(force_y)
		afm4wave[i] = mean(force_x)
		
		DoUpdate
		
		//Sleep/S/C=-1 10
	while(1)
end