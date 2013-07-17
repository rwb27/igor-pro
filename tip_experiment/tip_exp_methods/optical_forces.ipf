#pragma moduleName = optical_forces
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "pi_pi733_3cd_stage"
#include "tektronix_tds1001b"
#include "princeton_instruments_pixis_256e_ccd"
//#include "oo spectrometer v4.2"
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
		//oo_read()
		
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

static function display_data(df)
	dfref df
	variable i				// needed lots later on
	// load waves
	wave/sdfr=df displacement, afm_amplitude, afm_phase, oafm_amplitude, oafm_phase, afm_dc_amplitude
	wave/sdfr=df wavelength, spec2d, wavelength_t, spec2d_t
	
	// smooth waves
	newdatafolder/o df:analysis
	dfref df2 = df:analysis
	duplicate/o oafm_amplitude, df2:oafm_amplitude_mod
	duplicate/o oafm_phase, df2:oafm_phase_mod
	duplicate/o afm_amplitude, df2:afm_amplitude_mod
	duplicate/o afm_phase, df2:afm_phase_mod
	duplicate/o afm_dc_amplitude, df2:afm_dc_amplitude_mod
	duplicate/o displacement, df2:displacement_mod
	wave/sdfr=df2 oafm_amplitude_mod, oafm_phase_mod, afm_amplitude_mod, afm_phase_mod, afm_dc_amplitude_mod
	smooth 2, oafm_amplitude_mod, oafm_phase_mod, afm_amplitude_mod, afm_phase_mod, afm_dc_amplitude_mod
	
	// scale displacement
	wave/sdfr=df2 displacement_mod
	variable init = displacement_mod[0]
	displacement_mod -= init
	duplicate/o displacement_mod, df2:displacement_mod_ax
	wave/sdfr=df2 displacement_mod_ax
	i = numpnts(displacement_mod_ax)
	redimension/n=(i+1) displacement_mod_ax
	displacement_mod_ax[i] = 2*displacement_mod_ax[i-1] - displacement_mod_ax[i-2]
	
	average_data(df)
	
	// modify spectra
	duplicate/o spec2d, df2:spec2d_mod
	duplicate/o spec2d_t, df2:spec2d_t_mod
	duplicate/o wavelength, df2:wavelength_ax
	duplicate/o wavelength_t, df2:wavelength_t_ax
	wave/sdfr=df2 spec2d_mod, spec2d_t_mod, wavelength_ax, wavelength_t_ax
	matrixtranspose spec2d_mod
	matrixtranspose spec2d_t_mod
	i = numpnts(wavelength_ax)
	redimension/n=(i+1) wavelength_ax
	wavelength_ax[i] = 2*wavelength_ax[i-1] - wavelength_ax[i-2]
	i = numpnts(wavelength_t_ax)
	redimension/n=(i+1) wavelength_t_ax
	wavelength_t_ax[i] = 2*wavelength_t_ax[i-1] - wavelength_t_ax[i-2]
	
	// display data
	dowindow/k optical_force_data
	display/n=optical_force_data oafm_amplitude_mod vs displacement_mod
	appendtograph/r oafm_phase_mod vs displacement_mod
	appendtograph/l=l1 afm_amplitude_mod vs displacement_mod
	appendtograph/r=r1 afm_phase_mod vs displacement_mod
	appendtograph/l=l2 afm_dc_amplitude_mod vs displacement_mod
	appendimage/l=l3 spec2d_mod vs {displacement_mod_ax,wavelength_ax}
	appendimage/l=l4 spec2d_t_mod vs {displacement_mod_ax,wavelength_t_ax}
	// change line colours
	modifygraph rgb(oafm_amplitude_mod)=(65280,0,0), rgb(oafm_phase_mod)=(0,0,65280)
	modifygraph rgb(afm_amplitude_mod)=(65280,0,0), rgb(afm_phase_mod)=(0,0,65280)
	modifygraph axisenab(l2)={0.41,0.6}, axisenab(l1)={0.61,0.8}, axisenab(left)={0.81,1}
	modifygraph axisenab(r1)={0.61,0.8}, axisenab(right)={0.81,1}
	modifygraph axisenab(l3)={0.21,0.4}, axisenab(l4)={0,0.2}
	modifygraph height={aspect, 1}
	ModifyGraph minor=1,fSize=10,lblPosMode=1,lblPos=48,btLen=4,stLen=2,freePos=0
	// modify spectra display
	ModifyImage spec2d_mod ctab= {*,*,Geo,0}
	ModifyImage spec2d_mod ctabAutoscale=1,lookup= $""
	ModifyImage spec2d_t_mod ctab= {*,*,Geo,0}
	ModifyImage spec2d_t_mod ctabAutoscale=1,lookup= $""
	SetAxis l3 4.5e-07,8.5e-07
	SetAxis l4 4.5e-07,8.5e-07
	// autoscale axes
	SetAxis/A=2 left
	SetAxis/A=2 l1
	SetAxis/A=2 l2
	SetAxis/A=2 right
	SetAxis/A=2 r1
end

static function average_data(df)
	dfref df
	dfref df2 = df:analysis
	wave/sdfr=df2 displacement_mod, oafm_amplitude_mod, oafm_phase_mod, afm_amplitude_mod, afm_phase_mod, afm_dc_amplitude_mod
	// average data
	make/free/n=0 new_displacement, instances
	make/free/n=0 new_oafm_amp, new_oafm_phase, new_afm_amp, new_afm_phase, new_afm_dc
	variable i = numpnts(displacement_mod)
	variable j, k
	for (i = 0; i < numpnts(displacement_mod); i += 1)
		// compare value i with elements j in new_displacement
		for (j = 0; j < numpnts(new_displacement); j += 1)
			// if wave[i] is found in wave[j] then do no append but increment instance
			if (displacement_mod[i] == new_displacement[j])
				instances[j] += 1
				new_oafm_amp[j] += oafm_amplitude_mod[i]
				new_oafm_phase[j] += oafm_phase_mod[i]
				new_afm_amp[j] += afm_amplitude_mod[i]
				new_afm_phase[j] += afm_phase_mod[i]
				new_afm_dc[j] += afm_dc_amplitude_mod[i]
			endif
		endfor
		// else if wave[i] is not found in wave[j] append to wave and set instance to 1
		k = numpnts(new_displacement)
		redimension/n=(k+1) new_displacement, instances
		new_displacement[k] = displacement_mod[i]
		instances[k] = 1
		redimension/n=(k+1) new_oafm_amp, new_oafm_phase, new_afm_amp, new_afm_phase, new_afm_dc
		new_oafm_amp[k] = oafm_amplitude_mod[i]
		new_oafm_phase[k] = oafm_phase_mod[i]
		new_afm_amp[k] = afm_amplitude_mod[i]
		new_afm_phase[k] = afm_phase_mod[i]
		new_afm_dc[k] = afm_dc_amplitude_mod[i]
	endfor
	new_oafm_amp /= instances
	new_oafm_phase /= instances
	new_afm_amp /= instances
	new_afm_phase /= instances
	new_afm_dc /= instances
	duplicate/o new_displacement, displacement_mod
	duplicate/o new_oafm_amp, oafm_amplitude_mod
	duplicate/o new_oafm_phase, oafm_phase_mod
	duplicate/o new_afm_amp, afm_amplitude_mod
	duplicate/o new_afm_phase, afm_phase_mod
	duplicate/o new_afm_dc,afm_dc_amplitude_mod
end