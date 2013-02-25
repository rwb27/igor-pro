#pragma ModuleName = tip_exp
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "data_handling"
#include "pi_pi733_3cd_stage"
#include "keithley_2635a_smu"
#include "agilent_dsox2000_series_dso"
#include "tektronix_tds1001b"

static constant g0 = 7.7480917e-5
static strconstant gv_folder = "root:global_variables:tip_experiments"

static function initialise()
	data#check_gvpath(gv_folder)
	if (!exists($(gv_folder + ":append_mode")))
		string gv_path
		// experiment parameters
		variable/g $(gv_folder + ":append_mode") = 0
		variable/g $(gv_folder + ":scan_step") = 1e-3			// 1 nm steps
		variable/g $(gv_folder + ":scan_size") = 5			// 5 um max
		variable/g $(gv_folder + ":scan_direction") = -1		// approaching
		variable/g $(gv_folder + ":current_set_point") = 1		// 1 A stopping point
		// smu parameters
		gv_path = smu#gv_path()
		data#check_gvpath(gv_path)
		variable/g $(gv_path + ":voltage") = 0.1
		variable/g $(gv_path + ":current_range") = 1e-8
		// dso parameters
		gv_path = dso#gv_path()
		data#check_gvpath(gv_path)
		// pi_stage parameters
		gv_path = pi_stage#gv_path()
		data#check_gvpath(gv_path)
		variable/g $(gv_path + ":vel_a") = 10
		// tek parameters
		gv_path = tek#gv_path()
		data#check_gvpath(gv_path)
	endif
end

function/s setup_scan_folder()
	nvar append_mode = $(gv_folder + ":append_mode")
	svar prev_scan_folder = root:data:current_scan_folder
	string scan_folder
	if (append_mode)
		scan_folder = prev_scan_folder
	else
		string data_folder = data#check_data_folder()
		scan_folder = data#new_data_folder(data_folder + ":tip_exp_")
		data#check_folder(scan_folder + ":spectra")
		data#check_folder(scan_folder + ":time_resolved_data")
		string/g root:data:current_scan_folder = scan_folder
	endif
	return scan_folder
end

function initialise_scan()
	nvar append_mode = $(gv_folder + ":append_mode")
	wave wl_wave = root:oo:data:current:wl_wave
	if (!append_mode)									// if not appending
		// create data storage waves
		variable/g $(scan_folder + ":step") = 0
		make/o/n=0 $(scan_folder + ":displacement")
		make/o/n=0 $(scan_folder + ":current"), $(scan_folder + ":voltage")
		make/o/n=0 $(scan_folder + ":conductance"), $(scan_folder + ":current_range")
		make/o/n=0 $(scan_folder + ":psd_x"), $(scan_folder + ":psd_y")
		make/o/n=0 $(scan_folder + ":psd_x_stdev"), $(scan_folder + ":psd_y_stdev")
		make/o/n=0 $(scan_folder + ":timestamp")
		make/o/n=0 $(scan_folder + ":spec")
		make/o/n=(numpnts(wl_wave), 0) $(scan_folder + ":spec2d")
		setscale d, 0, 0, "A", $(scan_folder + ":current"), $(scan_folder + ":current_range")
		setscale d, 0, 0, "V", $(scan_folder + ":voltage")
		setscale d, 0, 0, "G\B0\M", $(scan_folder + ":conductance")
		setscale d, 0, 0, "V", $(scan_folder + ":psd_x"), $(scan_folder + ":psd_y")
		setscale d, 0, 0, "V", $(scan_folder + ":psd_x_stdev"), $(scan_folder + ":psd_y_stdev")
	else
		// do something if required
	endif
	return i
end

function setup_time_res_spec(direction)
	variable direction
	// agilent dsox2000 series dso
	// Set approach/retract conditional settings
	if(direction == 1)				
		dso#set_trigger(":TRIGger:SLOPe NEG")			// if retracting, set to negative slope
	elseif(direction == -1)
		dso#set_trigger(":TRIGger:SLOPe POS"	)		// if approaching, set to positive slope
		smu#set_current_range(1e-8)					// Set SMU current range to 1e-8 
	endif
	// pixis 256e ccd
	nvar t_range = root:gVariables:agilentOscilloscope:timeRange
	variable trange = t_range * 1e6
	variable shiftrate = 9.2
	variable exp_time = (trange / 256) - shiftrate
	readyPIXIS(exp_time)
end

function log_scan_parameters()
end

function setup_display()
	// Make wavelength image axis
	wave wavelength = root:latestScan:spectra:wavelength
	make/o/n=(numpnts(wavelength)) wavelengthImageAxis
	wavelengthImageAxis = 0.5*(wavelength[p+1]+wavelength[p])
	InsertPoints 0,1, wavelengthImageAxis								// Amend first point
	wavelengthImageAxis[0] = 2*wavelength[0]-wavelengthImageAxis[1]
	wavelengthImageAxis[numpnts(wavelengthImageAxis)-1] = 2*wavelength[numpnts(wavelength)-1] - wavelengthImageAxis[numpnts(wavelengthImageAxis)-2]	// Amend final point
	
end

function tip_scan()			// tip experiment master function
	// initialise data storage
	initialise()
	string scan_folder = setup_scan_folder()
	
	// open communications and initialise instruments
	smu#open_comms(); smu#initialise()
	dso#open_comms(); dso#initialise()
	tek#open_comms(); tek#initialise()
	pi_stage#open_comms(); pi_stage#initialise()
	
	// load all necessary variables / scan parameters
	string gv_path
		// experiment
	nvar append_mode $(gv_folder + ":append_mode")
	nvar scan_step = $(gv_folder + ":scan_step")
	nvar scan_size = $(gv_folder + ":scan_size")
	nvar scan_direction = $(gv_folder + ":scan_direction")
	nvar current_set_point = $(gv_folder + ":current_set_point")
	variable scan_step_d = scan_direction * scan_step
		// smu
	gv_path = smu#gv_path()
	nvar voltage = $(gv_path + ":voltage"), current_range = $(gv_path + ":current_range")
		// spectrometer
		// pixis
		// agilent
	gv_path = dso#gv_path()
		// tektronix
	gv_path = tek#gv_path()
		// pi_stage
	gv_path = pi_stage#gv_path()
	
	// log scan settings
	log_scan_parameters()
	
	// prepare data storage
	initialise_scan()
	wave displacement = $(scan_folder + ":displacement")
	wave current = $(scan_folder + ":current")
	wave voltage = $(scan_folder + ":voltage")
	wave conductance = $(scan_folder + ":conductance")
	wave current_range = $(scan_folder + ":current_range")
	wave psd_x = $(scan_folder + ":psd_x")
	wave psd_y = $(scan_folder + ":psd_y")
	wave psd_x_stdev = $(scan_folder + ":psd_x_stdev")
	wave psd_y_stdev = $(scan_folder + ":psd_y_stdev")
	wave timestamp = $(scan_folder + ":timestamp")
	wave spec = $(scan_folder + ":spec")
	wave spec2d = $(scan_folder + ":spec2d")
	
	// display experiment
	setup_display()
	
	// prepare initial instrument configurations
	setup_time_res_spec()
	pi_stage#get_pos()
		// smu
	smu#set_voltage(voltage)
	smu#set_current_range(current_range)
	smu#output(1)
	
	// do experiment
	nvar i = $(scan_folder + ":step")
	variable condition = 0
	variable set_point_reached = 0
	variable/c smu_data, force_x, force_y
	variable current_pos
	do
		// check for experiment breaks
		if (scan_step * step > scan_size)		// end at scan limit
			break
		elseif (getkeystate(0) & 32)			// manual escape (esc)
			print "scan aborted at step " + num2str(i)
			break
		endif
		
		// prepare measurement waves
		redimension/n=(i+1) displacement, voltage, current, conductance, current_range
		redimension/n=(i+1) psd_x, psd_y, psd_x_stdev, psd_y_stdev, timestamp
		redimension/n=(dimsize(spec2d, 0), i+1) spec2d
		
		// move to position
		if (!set_point_reached)
			pi_stage#move_rel("a", scan_step_d)
		endif
		
		// perform measurement checks
		current_range[i] = smu#check_current_range()
		
		// take measurements
		current_pos = pi_stage#get_pos_ch("a")
		smu_data = smu#measure_iv()
		force_x = tek#wave_stats("1")
		force_y = tek#wave_stats("2")
		oo_read()
		
		// store pz measurements
		displacement[i] = current_pos
		timestamp[i] = ticks/60
		// store smu measurements
		voltage[i] = real(smu_data)
		current[i] = imag(smu_data)
		conductance[i] = (current[i] / voltage[i]) / g0
		// store force measurements
		psd_x[i] = real(force_x)
		psd_x_stdev[i] = imag(force_x)
		psd_y[i] = real(force_y)
		psd_y_stdev[i] = imag(force_y)
		// store spectra
		duplicate/o root:oo:data:current:spectra, $(scan_folder + ":spectra:spec_" + num2str(i))
		wave spec = $(scan_folder + ":spectra:spec_" + num2str(i))
		spec2d[][i] = spec[p]
		
		// perform end-loop checks
		if (dso#check_trigger(0))						// check for dso trigger
			// get time-resolved measurements
			
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
		if (imag(smu_data) >= current_set_point)		// prevents movement once current limit reached
			set_point_reached = 1
		end
		
		doupdate
		i += 1
	while (condition)
	
	// clear all instruments
	dso#check_trigger(1)
	// close communications
	smu#close_comms()
	dso#close_comms()
	tek#close_comms()
	pi_stage#close_comms()
	
	
	// save data analysis
	
	// save exit point
	saveexperiment
end