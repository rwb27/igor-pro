#pragma rtGlobals=3		// Use modern global access method and strict wave access.


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

function find_periodic_part(y, dest, hpf, fidelity)
	wave y, dest
	variable hpf, fidelity
	make/free/C/N=(numpnts(y)) transformed
	fft /DEST=transformed y
	if(hpf>0)
		transformed[0, x2pnt(transformed, hpf)] = 0
	endif
	
	make/free/N=(numpnts(transformed)) psd
	psd=magsqr(transformed[p])
	variable total_power = sum(psd)
	variable i=0, accumulated_power=0
	sort/R psd, psd //sort PSD in decreasing order
	do
		accumulated_power += psd[i]
		i+=1
	while(accumulated_power < total_power * fidelity && i<numpnts(psd))
	//so, we need to take the i biggest components to encompass the specified amount of power in the signal
	variable threshold = psd[i-1] //the smallest component we're going to take
//	printf "threshold set at %.1e, %.0f Fourier components\r", threshold, i
	
	for(i=0; i<numpnts(transformed); i+=1)
		if(magsqr(transformed[i]) < threshold)
			transformed[i]=0
		endif
	endfor
	ifft /DEST=dest transformed
end

function x_modulo_one_period(y, xdest)
	wave y, xdest
	xdest = NaN
	
	make/free/n=(numpnts(y)-1) dy
	dy = y[p+1] - y[p]
	
	variable start = 0, stop = -1
	
	findlevel /edge=2/P/Q/R=[0, numpnts(dy)-1] dy, 0
	start = V_levelX
	do
		findlevel /edge=2/P/Q/R=[ceil(start+1), numpnts(dy)-1] dy, 0
		stop = V_levelX
	
		if(V_flag == 1)
			stop = numpnts(y) - 1.6
		endif
		
		xdest[ceil(start+0.5), ceil(stop+0.5)] = leftx(y) + deltax(y) * ( p - (start + 0.5 ))
		
		start = stop
	while(start < numpnts(y) - 2)
end

function bin_waveform(ywave, xwave, dx, binned_y)
	wave ywave
	wave xwave
	wave binned_y
	variable dx
	variable startx = wavemin(xwave)
	variable n = ceil((wavemax(xwave) - startx)/dx)
	redimension/n=(n) binned_y
	setscale /P x, startx, dx, binned_y
	
	duplicate/free binned_y, count
	binned_y=0
	count=0
	
	variable i, j
	for(i=0; i<numpnts(ywave); i+=1)
		j = x2pnt(binned_y, xwave[i])
		if(j<numpnts(binned_y) && j>=0)
			binned_y[j] += ywave[i]
			count[j] += 1
		endif
	endfor
	binned_y = binned_y/count
end

function extract_waveform(measurement, hpf, fidelity, dx)
	variable measurement
	variable hpf, fidelity, dx
	
	wave y=$("root:daq_data:force_y_"+num2str(measurement))
	wave ref=$("root:daq_data:photodiode_"+num2str(measurement))
	
	duplicate/o y waveform
	duplicate/o y waveform_s
	duplicate/o ref waveform_ref
	make/o/n=(numpnts(y)) px
	make/o waveform_binned
	
	find_periodic_part(y, waveform_s, hpf, fidelity)
	find_periodic_part(ref, waveform_ref, hpf, fidelity)
	x_modulo_one_period(waveform_ref, px)
	find_periodic_part(y, waveform, hpf, 1)
	bin_waveform(waveform, px, dx, waveform_binned)
end

function run_through_traces(first, last, increment)
	variable first, last, increment
	variable i=0
	for(i=first; i<last; i+=increment)
		extract_waveform(i, 10, 0.6, 2e-5)
		doupdate
		sleep/s 0.5
	endfor
end

function/C lockin(y, ref, [peakToPeak, hpf, fidelity])
	wave y, ref
	variable peakToPeak, hpf, fidelity
	hpf = paramIsDefault(hpf) ? 100 : hpf
	fidelity = paramIsDefault(fidelity) ? 0.5 : fidelity
	duplicate/free ref, smooth_ref
	
	find_periodic_part(ref, smooth_ref, hpf, fidelity)
	duplicate/free smooth_ref, dr		//take first derivative to get quadrature
	dr[0,numpnts(dr)-2] = smooth_ref[p+1] - smooth_ref[p]
	dr[numpnts(dr)-1] = dr[p-1]
	
	duplicate/free y, temp
	temp = y * smooth_ref
	variable y_dot_r = sum(temp)
	temp = y * dr
	variable y_dot_dr = sum(temp)
	temp = smooth_ref * smooth_ref
	variable r_dot_r = sum(temp)
	temp = dr * dr
	variable dr_dot_dr = sum(temp)
	
	return cmplx(y_dot_r / sqrt(r_dot_r), -y_dot_dr / sqrt(dr_dot_dr))
end

function/c soft_lockin_2(y, ref, [harmonic])
	wave y, ref
	variable harmonic
	harmonic = 2//paramIsDefault(harmonic) ? 1 : harmonic
	
	duplicate/free ref, smooth_ref
	smooth /b=2 2, smooth_ref //TODO: pick smoothing values nicely!
	variable mr = mean(smooth_ref)
	smooth_ref -= mr
	
	if(harmonic==2)
		smooth_ref = smooth_ref * smooth_ref
		mr = mean(smooth_ref)
		smooth_ref -= mr
	endif
	
	duplicate/free smooth_ref, dr		//take first derivative to get quadrature
	dr[0,numpnts(dr)-2] = smooth_ref[p+1] - smooth_ref[p]
	dr[numpnts(dr)-1] = dr[p-1]
	
	duplicate/free y, temp
	temp = y * smooth_ref
	variable y_dot_r = sum(temp)
	temp = y * dr
	variable y_dot_dr = sum(temp)
	temp = smooth_ref * smooth_ref
	variable r_dot_r = sum(temp)
	temp = dr * dr
	variable dr_dot_dr = sum(temp)
	
	return cmplx(y_dot_r / sqrt(r_dot_r), y_dot_dr / sqrt(dr_dot_dr))
end

function estimate_oafm()
	wave oafm_amplitude, oafm_phase
	duplicate/o oafm_amplitude, oafm_amplitude_estimated
	duplicate/o oafm_phase, oafm_phase_estimated
	
	variable i, n=numpnts(oafm_amplitude)
	for(i=0; i<n; i+=1)
		wave afm = $("root:daq_data:force_y_"+num2str(i))
		wave pd = $("root:daq_data:photodiode_"+num2str(i))
		variable/c l = lockin(afm, pd)
		oafm_amplitude_estimated[i] = (magsqr(l) )
		oafm_phase_estimated[i] = imag(r2polar(l))
	endfor
end
		


window waveform_viewer()
	display /k=1 waveform vs px
	appendtograph waveform_binned
	modifygraph mode(waveform)=2, rgb(waveform)=(65535, 40000,40000), lsize(waveform_binned)=2
	Label left "AFM Signal / V";DelayUpdate
	Label bottom "Time / s"
end

window oafm_plot()
	display/k=1 oafm_amplitude 
	append/r afm_dc_amplitude
	ModifyGraph axisEnab(left)={0.5,1},axisEnab(right)={0,0.5};DelayUpdate
	Label left "500Hz Lock-in";DelayUpdate
	Label bottom "Measurement Number";DelayUpdate
	Label right "AFM Displacement"
end