#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function measure_over_time()
	newdatafolder/o root:measure_time
	dfref df = root:measure_time
	
	pi_stage#open_comms()
	lockin2#open_comms()
	lockin2#purge()
	variable time_constant = lockin2#get_time_constant()
	
	dfref spec_path = root:oo:globalvariables
	nvar/sdfr=spec_path numspectrometers
	wave/sdfr=df dtime
	if (!waveexists(dtime))
		make/d/o/n=0 df:dtime
		make/o/n=0 df:amplitude, df:phase
		// spectra data
		duplicate/o root:oo:data:current:wl_wave, df:wavelength
		wave wl_wave = df:wavelength
		wl_wave *= 1e-9
		setscale d, 0, 0, "m", wl_wave
		make/o/n=(numpnts(wl_wave), 1) df:spec2d
		// extra spectra data
		if (numspectrometers == 2)
			duplicate/o root:oo:data:current:wl_wave_2, df:wavelength_t
			wave wl_wave_t = df:wavelength_t
			wl_wave_t *= 1e-9
			setscale d, 0, 0, "m", wl_wave_t
			make/o/n=(numpnts(wl_wave_t), 1) df:spec2d_t
		endif
		lockin2#aphs()				// auto-phase lock-in amplifier
	endif
	wave/sdfr=df dtime, amplitude, phase, wavelength, wavelength_t, spec2d, spec2d_t
	setscale d, 0, 0, "dat", dtime
	setscale d, 0, 0, "V", amplitude
	setscale d, 0, 0, "°", phase
	
	dowindow/k feedback
	display/n=feedback amplitude vs dtime
	appendtograph/r phase vs dtime
	
	variable i, keys, j=0
	variable/c data
	nvar/sdfr=$pi_stage#gv_path() pos_a
	pi_stage#get_pos()
	variable pos_a0 = pos_a
	do
		keys = getkeystate(0)
		if (keys & 32)			// manual escape (esc)
			break
		endif
		
		if (j == 10)
			print "moving"
			j = 0
			pi_stage#move_rel("A", 1)
			pi_stage#get_pos()
			print pos_a, 1000*(pos_a-pos_a0)
		endif
		j += 1
		
		i = numpnts(amplitude)
		sleep/s time_constant*4
		data = lockin2#measure_rtheta()
		redimension/n=(i+1) dtime, amplitude, phase
		dtime[i] = datetime
		amplitude[i] = real(data)
		phase[i] = imag(data)		
		oo_read()
		// store spectra
		wave spec = root:oo:data:current:spectra
		redimension/n=(dimsize(spec2d, 0), i+1) spec2d
		spec2d[][i] = spec[p]
		if (numspectrometers == 2)
			wave spec = root:oo:data:current:spectra_2
			redimension/n=(dimsize(spec2d_t, 0), i+1) spec2d_t
			spec2d_t[][i] = spec[p]
		endif
		doupdate
		sleep/s 1
	while(1)
	
	pi_stage#close_comms()
	lockin2#close_comms()
end

function measure_amplitude()
	// open comms
	pi_stage#open_comms()
	tek#open_comms(); tek#initialise()
	lockin#open_comms()
	lockin#purge()
	lockin2#open_comms()
	lockin2#purge()
	variable time_constant = lockin2#get_time_constant()
	
	string pi_path = pi_stage#gv_path()
	pi_stage#get_pos()					// read dco on position	
	nvar/sdfr=$pi_path pos_a		// load read piezo positions
	
	wave step
	if (!waveexists(step))
		make/o/n=0 step, position, amplitude, phase, frequency, current, current_phase
		lockin#aphs()
		lockin2#aphs()				// auto-phase lock-in amplifier
	endif
	wave step, position, amplitude, phase, frequency, current, current_phase
	setscale d, 0, 0, "m", step
	setscale d, 0, 0, "m", position
	setscale d, 0, 0, "V", amplitude
	setscale d, 0, 0, "°", phase
	setscale d, 0, 0, "A", current
	setscale d, 0, 0, "°", current_phase
	setscale d, 0, 0, "Hz", frequency
	
	variable i, freq, keys
	variable/c data, current_data
	dowindow/k feedback
	display/n=feedback amplitude vs step
	appendtograph/r phase vs step
	appendtograph/l=l1 current vs step
	appendtograph/r=r1 current_phase vs step
	modifygraph rgb(amplitude)=(0,0,0), rgb(phase)=(60000,0,0)
	modifygraph rgb(current)=(0,0,0), rgb(current_phase)=(60000,0,0)
	ModifyGraph axisEnab(l1)={0,0.5}, axisenab(r1)={0,0.5}, axisenab(left)={0.5,1}, axisenab(right)={0.5,1}
	ModifyGraph freePos=0
	variable direction = -1
	do
		keys = getkeystate(0)
		if (keys & 32)			// manual escape (esc)
			break
		elseif (keys & 4)		// shift
			direction *= -1
			print "shift pressed"
			sleep/s 1
		endif
		i = numpnts(step)
		pi_stage#move_rel("a", direction*1e-3)
		sleep/s time_constant*4
		pi_stage#get_pos()
		current_data = lockin#measure_rtheta()
		data = lockin2#measure_rtheta()
		freq = tek#meas("2", "freq")
		redimension/n=(i+1) step, position, amplitude, phase, frequency, current, current_phase
		if (i >0)
			step[i] = step[i-1] + direction*1e-9
		else
			step[i] = 0
		endif
		position[i] = 1000*pos_a
		current[i] = real(current_data)/1e8
		current_phase[i] = imag(current_data)
		amplitude[i] = real(data)
		phase[i] = imag(data)
		frequency[i] = freq
		doupdate
	while (1)
	pi_stage#close_comms()
	tek#close_comms()
	lockin#close_comms()
	lockin2#close_comms()
end

function display_feedback()
	wave step, position, amplitude, phase, frequency, current, current_phase
	setscale d, 0, 0, "m", step
	setscale d, 0, 0, "m", position
	setscale d, 0, 0, "V", amplitude
	setscale d, 0, 0, "°", phase
	setscale d, 0, 0, "A", current
	setscale d, 0, 0, "°", current_phase
	setscale d, 0, 0, "Hz", frequency
	dowindow/k feedback
	display/n=feedback amplitude vs position
	appendtograph/r phase vs position
	appendtograph/l=l1 current vs position
	appendtograph/r=r1 current_phase vs position
	modifygraph rgb(amplitude)=(0,0,0), rgb(phase)=(60000,0,0)
	modifygraph rgb(current)=(0,0,0), rgb(current_phase)=(60000,0,0)
	ModifyGraph axisEnab(l1)={0,0.49}, axisenab(r1)={0,0.49}, axisenab(left)={0.51,1}, axisenab(right)={0.51,1}
	ModifyGraph freePos=0, lblPosMode=2
	label left "\\s(amplitude)amplitude (\\U)"
	label right "\\s(phase)phase (\\U)"
	label l1 "\\s(current)current (\\U)"
	label r1 "\\s(current_phase)current phase (\\U)"
	label bottom "step (\\U)"
end