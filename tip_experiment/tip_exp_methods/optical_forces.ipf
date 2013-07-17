#pragma moduleName = optical_forces
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "pi_pi733_3cd_stage"
#include "tektronix_tds1001b"
#include "princeton_instruments_pixis_256e_ccd"
#include "oo spectrometer v4.2"
#include "srs_sr830_lockin_amplifier"
#include "srs_sr830_lockin_amplifier_2"

static function measure()
	// create data folder for storage
	newdatafolder/o root:optical_forces
	dfref df = root:optical_forces
	
	// open comms
	pi_stage#open_comms()
	tek#open_comms()
	lockin#open_comms()
	lockin#purge()
	lockin2#open_comms()
	lockin2#purge()
	
	// make waves for measurements
	dfref spec_path = root:oo:globalvariables
	nvar/sdfr=spec_path numspectrometers
	wave/sdfr=df displacement
	if (!waveexists(displacement))
		// make measurement waves
		make/o/n=0 df:displacement, df:afm_amplitude, df:afm_phase, df:oafm_amplitude, df:oafm_phase, df:afm_dc_amplitude
		setscale d, 0, 0, "m", df:displacement
		setscale d, 0, 0, "V", df:afm_amplitude, df:oafm_amplitude, df:afm_dc_amplitude
		setscale d, 0, 0, "°", df:afm_phase, df:oafm_phase
		lockin#aphs()
		lockin2#aphs()
		// make spectra waves
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
	endif
	waveclear displacement
	
	// load waves
	wave/sdfr=df displacement, afm_amplitude, afm_phase, oafm_amplitude, oafm_phase, afm_dc_amplitude
	wave/sdfr=df wavelength, spec2d, wavelength_t, spec2d_t
	
	// display data
	dowindow/k optical_force_data
	display/n=optical_force_data oafm_amplitude
	appendtograph/r oafm_phase
	appendtograph/l=l1 afm_amplitude
	appendtograph/r=r1 afm_phase
	appendtograph/l=l2 afm_dc_amplitude
	modifygraph axisenab(l2)={0,0.33}, axisenab(l1)={0.34,0.66}, axisenab(left)={0.67,1}
	modifygraph axisenab(r1)={0.34,0.66}, axisenab(right)={0.67,1}
	
	// setup measurements
	tek#get_waveform_params("1")
	tek#get_waveform_params("2")
	variable i, keys
	variable/c afm_data, oafm_data
	nvar/sdfr=$pi_stage#gv_path() pos_a
	pi_stage#get_pos()
	variable pos_a0 = pos_a
	variable direction = -1, step = 1e-3
	variable time_constant = lockin2#get_time_constant()
	
	// take measurements
	do
		// get loop key controls
		keys = getkeystate(0)
		if (keys & 32)			// manual escape (esc)
			break
		elseif (keys & 4)		// shift
			direction *= -1
			print "direction =", direction
		elseif (keys & 1)		//control
			step /= 10
			print "step = ", step * direction
		elseif (keys & 2)		//alt
			step *= 10
			print "step = ", step * direction
		endif
		
		// move tips
		pi_stage#move_rel("A", direction*step)
		sleep/s 0.25
		
		// make measurements
		sleep/s 4*time_constant
		pi_stage#get_pos()
		oafm_data = lockin#measure_rtheta()
		afm_data = lockin2#measure_rtheta()
		tek#import_data("1", "photodiode")
		tek#import_data("2", "afm")
		oo_read()
		
		// record measurements
		i = numpnts(oafm_amplitude)
		redimension/n=(i+1) displacement, afm_amplitude, afm_phase, oafm_amplitude, oafm_phase, afm_dc_amplitude
		//// store static measurements
		displacement[i] = pos_a
		oafm_amplitude[i] = real(oafm_data)
		oafm_phase[i] = imag(oafm_data)
		afm_amplitude[i] = real(afm_data)
		afm_phase[i] = imag(afm_data)
		//// store waveform analysis
		wave/sdfr=root:tektronix_tds1001b_dso afm
		afm_dc_amplitude[i] = mean(afm)
		//// store spectra
		wave spec = root:oo:data:current:spectra
		redimension/n=(dimsize(spec2d, 0), i+1) spec2d
		spec2d[][i] = spec[p]
		if (numspectrometers == 2)
			wave spec = root:oo:data:current:spectra_2
			redimension/n=(dimsize(spec2d_t, 0), i+1) spec2d_t
			spec2d_t[][i] = spec[p]
		endif
		
		// end sequence procedures
		doupdate
	while (1)
	
	// close comms
	pi_stage#close_comms()
	lockin#close_comms()
	lockin2#close_comms()
	tek#close_comms()
end