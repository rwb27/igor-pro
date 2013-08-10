#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include <NIDAQmxWaveScanProcs>

function create_daq_waves(num_ch, scan_rate, sample_time)
	variable num_ch, scan_rate, sample_time
	variable sample_period = 1 / scan_rate
	variable sample_num = sample_time * scan_rate
	variable i
	for (i = 0; i < num_ch; i += 1)
		make/o/n=(sample_num) $("root:daq_"+num2str(i))
		wave/sdfr=root ch = $("daq_"+num2str(i))
		setscale/p x, 0, sample_period, "s", ch
	endfor
end

function measure_over_time()
	variable i
	create_daq_waves(5, 50e3, 0.1)
	newdatafolder/o root:daq
	dfref df = root:daq
	make/o/n=0 df:measurements
	wave/sdfr=df measurements
	wave/sdfr=root daq_1, daq_2, daq_3, daq_4, daq_5
	do
		DAQmx_Scan/dev="dev1" WAVES="daq_1, 1/diff; daq_2, 2/diff; daq_3, 3/diff; daq_4, 4/diff; daq_5, 5/diff;"
		i = numpnts(measurements)
		redimension/n=(i+1) measurements
		measurements[i] = mean(daq_1)
	while (i < 500)
end