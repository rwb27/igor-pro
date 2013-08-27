#pragma moduleName = daq
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include <NIDAQmxWaveScanProcs>

function create_daq_waves(num_ch, scan_rate, sample_time)
	variable num_ch, scan_rate, sample_time
	variable dt = 1 / scan_rate
	variable sample_num = sample_time * scan_rate
	variable i
	for (i = 1; i <= num_ch; i += 1)
		make/o/n=(sample_num) $("root:daq_"+num2str(i))
		wave/sdfr=root: ch = $("daq_"+num2str(i))
		setscale/p x, 0, dt, "s", ch
	endfor
end

function measure_over_time()
	variable i
	create_daq_waves(5, 50e3, 0.1)
	newdatafolder/o root:daq
	dfref df = root:daq
	make/o/n=0 df:measurements
	wave/sdfr=df measurements
	wave/sdfr=root: daq_1, daq_2, daq_3, daq_4, daq_5
	do
		DAQmx_Scan/dev="dev1" WAVES="daq_1, 1/diff; daq_2, 2/diff; daq_3, 3/diff; daq_4, 4/diff; daq_5, 5/diff;"
		i = numpnts(measurements)
		redimension/n=(i+1) measurements
		measurements[i] = mean(daq_1)
	while (i < 500)
end

// NIDAQmx not required - can be separated out

function/c lockin(y, ref, [harmonic])
	wave y, ref
	variable harmonic
	if (paramIsDefault(harmonic))
		harmonic = 1
	endif
	
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