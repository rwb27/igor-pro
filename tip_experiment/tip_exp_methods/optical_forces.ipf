#pragma moduleName = optical_forces
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "machine_definitions"
#ifdef LAB_MACHINE

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
#endif

function clean_displacement(displacement, output_name, [stepsize])
	wave displacement
	string output_name
	variable stepsize
	if(paramisdefault(stepsize)) 
		stepsize = 1
	endif
	
	duplicate/o displacement, $output_name
	wave output = $output_name

	make/free/n=(numpnts(displacement) - 1) dz
	dz = displacement[p+1] - displacement[p]
	smooth 5, dz
	smooth /M=0 21, dz
	dz = sign(dz) * 10^round( max(-3, log(abs(dz / stepsize)))) * stepsize

	variable i=0
	for(i=1; i<numpnts(displacement); i+=1)
		output[i] = output[i-1] + dz[i-1]
	endfor
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
	wave/sdfr=df2 oafm_amplitude_mod, oafm_phase_mod, afm_amplitude_mod, afm_phase_mod, afm_dc_amplitude_mod
	//smooth 2, oafm_amplitude_mod, oafm_phase_mod, afm_amplitude_mod, afm_phase_mod, afm_dc_amplitude_mod
	
	clean_displacement(displacement, (getDataFolder(1, df2)+"displacement_mod")) //clean up displacement trace
	wave/sdfr=df2 displacement_mod
	variable init = displacement_mod[0]
	displacement_mod -= init
	duplicate/o displacement_mod, df2:displacement_mod_ax
	wave/sdfr=df2 displacement_mod_ax
	i = numpnts(displacement_mod_ax)
	redimension/n=(i+1) displacement_mod_ax
	displacement_mod_ax[i] = 2*displacement_mod_ax[i-1] - displacement_mod_ax[i-2]
	
	//average_data(df)
	
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
	
	//add position-binned data
	bin_data_folder(df2)
	appendtograph/r df2:oafm_phase_binned vs df2:bin_centres
	appendtograph/l df2:oafm_amplitude_binned vs df2:bin_centres
	appendtograph/r=r1 df2:afm_phase_binned vs df2:bin_centres
	appendtograph/l=l1 df2:afm_amplitude_binned vs df2:bin_centres
	appendtograph/l=l2 df2:afm_dc_binned vs df2:bin_centres
	// change line colours
	modifygraph rgb(oafm_amplitude_binned)=(65280,0,0), rgb(oafm_phase_binned)=(0,0,65280)
	modifygraph rgb(afm_amplitude_binned)=(65280,0,0), rgb(afm_phase_binned)=(0,0,65280)
	modifygraph lsize(oafm_amplitude_binned)=3
	modifygraph lsize(oafm_phase_binned)=3
	modifygraph lsize(afm_amplitude_binned)=3
	modifygraph lsize(afm_phase_binned)=3
	modifygraph lsize(afm_dc_binned)=3
end

function fit_snap_to_contact(df, contact_points)
	DFREF df
	wave contact_points
	
	wave afm = df:afm_dc_amplitude_mod, z = df:displacement_mod
	
	make/O/N=0 afm_snippets, z_snippets
	
	variable i
	for(i=0; i+1<numpnts(contact_points); i+=2)
		variable start = contact_points[i]
		variable stop = contact_points[i+1]
		variable position = numpnts(afm_snippets)
		
		redimension/N=(position + stop - start + 1) afm_snippets, z_snippets
		
		afm_snippets[position, position + stop - start] = afm[p - position + start]
		z_snippets[position, position + stop - start] = z[p - position + start]
	endfor
	
	CurveFit line, afm_snippets /X=z_snippets
	wave w_coef, w_sigma
	variable sensitivity = W_coef[1]*1000000
	variable ds = W_sigma[1]*1000000
	printf "AFM sensitivity is %f +/- %f V/m", sensitivity, ds
	return sensitivity
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

function bin_in_x(xwave, ywave, bins, output_ywave)
	//bin the X coordinate, and average the Y coordinate over the bins
	wave xwave, ywave, bins, output_ywave
	redimension/N=(numpnts(bins)-1) output_ywave
	make/free/N=(numpnts(bins)-1) frequency
	output_ywave=0
	
	variable i
	for(i=0; i<numpnts(xwave); i+=1)
		findlevel /EDGE=1 /P/Q bins, xwave[i]
		if(V_flag==0 && V_LevelX<numpnts(frequency))
			frequency[floor(V_LevelX)]+=1
			output_ywave[floor(V_LevelX)]+=ywave[i]
		endif
	endfor
	output_ywave /= frequency
end

function optimise_bins(xwave, bins, bin_centres)
	wave xwave, bins, bin_centres
	redimension /N=(numpnts(bins) - 1) bin_centres
	make /free/N=(numpnts(bins) - 1) frequency
	bin_centres=0
	
	variable i
	for(i=0; i<numpnts(xwave); i+=1)
		findlevel /EDGE=1 /P/Q bins, xwave[i]
		if(V_flag==0 && V_LevelX<numpnts(frequency))
			frequency[floor(V_LevelX)]+=1
			bin_centres[floor(V_LevelX)]+=xwave[i]
		endif
	endfor
	bin_centres /= frequency
	
	do
		findvalue /V=0 frequency
		if(V_value >= 0)
			//remove empty bins
			deletepoints V_value, 1, frequency, bin_centres
			deletepoints max(V_value + 1, numpnts(bins) - 2), 1, bins
		endif
	while(V_value >= 0 && numpnts(bin_centres) > 1)
end

function bin_data_folder(df)
	DFREF df
	DFREF currentdf = getdatafolderDFR()
	SetDataFolder df
	
	wave displacement_mod, afm_dc_amplitude_mod, afm_amplitude_mod, afm_phase_mod, oafm_amplitude_mod, oafm_phase_mod
	
	make /o /n=(ceil(wavemax(displacement_mod)*1000) - floor(wavemin(displacement_mod) * 1000) + 1) bins
	bins = wavemin(displacement_mod)  - 0.0005 + p*0.001 //bins are 1nm
	make /o/n=(numpnts(bins)-1) bin_centres, afm_dc_binned, afm_amplitude_binned, afm_phase_binned, oafm_amplitude_binned, oafm_phase_binned
	
	optimise_bins(displacement_mod, bins, bin_centres)
	bin_in_x(displacement_mod, afm_dc_amplitude_mod, bins, afm_dc_binned)
	bin_in_x(displacement_mod, afm_amplitude_mod, bins, afm_amplitude_binned)
	bin_in_x(displacement_mod, afm_phase_mod, bins, afm_phase_binned)
	bin_in_x(displacement_mod, oafm_amplitude_mod, bins, oafm_amplitude_binned)
	bin_in_x(displacement_mod, oafm_phase_mod, bins, oafm_phase_binned)
	
	SetDataFolder currentdf
end

function amplitude_vs_frequency(df, wave_name_pattern, frequencies, amplitudes)
	dfref df
	string wave_name_pattern //waves we'll compare
	wave frequencies, amplitudes
	
	
	variable i
	for(i=0; i<numpnts(frequencies); i+=1)
		string currentwavename
		sprintf currentwavename, wave_name_pattern, frequencies[i]
		wave orig_signal = df:$currentwavename
		duplicate/free orig_signal signal
		
		smooth 5, signal
		amplitudes[i] = wavemax(signal) - wavemin(signal)
	endfor
end

function/wave extract_drift_from_spikes(data, drift)
	wave data
	wave drift
	make/free/n=(numpnts(data)-1) differentialVariance
	differentialVariance = (data[p+1] - data[p])
	smooth /b=2 5, differentialVariance              //remove noise
	differentialVariance = differentialVariance^2
	smooth /b=2 10, differentialVariance             //average differential variance
	variable threshold = statsMedian(differentialVariance) * 2 //at a guess, this is a sensible measure of whether or not a given point is a spike...
	redimension/n=(numpnts(data)) drift
	drift = differentialVariance[min(p, numpnts(differentialVariance)-1)] < threshold ? data[p] : NaN
	smooth /b=2 5, drift
	return drift
end

function calculate_pos(afm, z, pos, sensitivity)
	wave afm, z, pos
	variable sensitivity
	
	pos = z - afm/sensitivity
end
	
	