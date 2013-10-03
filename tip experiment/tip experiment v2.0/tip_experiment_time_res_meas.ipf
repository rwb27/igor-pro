#pragma modulename = tip_exp_time_res
#pragma version = 6.31
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

static constant g0 = 7.7480917e-5
static strconstant gv_folder = "root:global_variables:tip_experiment"

static function temporal_measurements(sf, i)
	dfref sf
	variable i
	string sf_str = getdatafolder(1, sf)
	string qc_name = sf_str + "time_resolved_data:qc_trace_"+num2str(i)
	string qcg_name = sf_str + "time_resolved_data:qcg_trace_"+num2str(i)
	string qcf_name = sf_str + "time_resolved_data:qc_force_"+num2str(i)
	string qcs_name = sf_str + "time_resolved_data:qc_spec_"+num2str(i)
			
	// time-resolved current measurement
	dso#import_data("1", "")
	duplicate/o root:agilent_dsox2012a_dso:ch1_trace, $qc_name
	duplicate/o root:agilent_dsox2012a_dso:ch1_trace_time, $(qc_name+"_time")
	// calculate time-resolved conductance
	duplicate $qc_name, $qcg_name
	wave g_trace = $qcg_name
	nvar/sdfr=root:global_variables:amplifiers gain = gain_dso
	nvar/sdfr=$smu#gv_path() voltage
	g_trace /= (gain * voltage * g0)
	setscale d, 0, 0, "G\B0\M", g_trace
	
	// get time-resolved force measurement
	dso#import_data("2", "")
	duplicate/o root:agilent_dsox2012a_dso:ch2_trace, $qcf_name
	duplicate/o root:agilent_dsox2012a_dso:ch2_trace_time, $(qcf_name+"_time")
			
	// get time-resolved spectra
	pixis#read()
	duplicate root:pixis_256e:current:image, $qcs_name
	duplicate root:pixis_256e:current:wavelength, $(qcs_name + "_wavelength")
	duplicate root:pixis_256e:current:timing, $(qcs_name + "_time")
	
	// re-arm time-resolved measurements
	nvar/sdfr=$pixis#gv_path() exp_time
	pixis#ready(exp_time)
	dso#arm_trigger()
	
	return 0
end