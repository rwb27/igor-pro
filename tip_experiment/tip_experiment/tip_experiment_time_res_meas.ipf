#pragma modulename = tip_exp_time_res
#pragma version = 6.31
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

static constant g0 = 7.7480917e-5
static strconstant gv_folder = "root:global_variables:tip_experiment"

static function measure_time_resolved(scan_folder, i)
	dfref scan_folder
	variable i
	
	// required declarations
	string qc_name, qcg_name, qcf_name, qcs_name
			
	// set wave names
	string scan_folder_str
 	dfref initial_folder = getdatafolderdfr()
 	setdatafolder scan_folder
 	scan_folder_str = getdatafolder(1)
	setdatafolder initial_folder
	
	qc_name = scan_folder_str + "time_resolved_data:qc_trace_"+num2str(i)
	qcg_name = scan_folder_str + "time_resolved_data:qcg_trace_"+num2str(i)
	qcf_name = scan_folder_str + "time_resolved_data:qc_force_"+num2str(i)
	qcs_name = scan_folder_str + "time_resolved_data:qc_spec_"+num2str(i)
			
	// time-resolved current measurement
	dso#import_data("1", "")
	duplicate/o root:agilent_dsox2012a_dso:ch1_trace, $qc_name
	// calculate time-resolved conductance
	duplicate $qc_name, $qcg_name
	wave g_trace = $qcg_name
	dfref amp_path = root:global_variables:amplifiers
	nvar/sdfr=amp_path gain = gain_dso
	dfref smu_path = $smu#gv_path()
	nvar/sdfr=smu_path v = :voltage
	g_trace /= (gain * v * g0)
	setscale d, 0, 0, "G\B0\M", g_trace
	
	// get time-resolved force measurement
	dso#import_data("2", "")
	duplicate/o root:agilent_dsox2012a_dso:ch2_trace, $qcf_name
			
	// get time-resolved spectra
	pixis#read()
	duplicate root:pixis_256e:current:image, $qcs_name
	
	// re-arm time-resolved measurements
	dfref pixis_path = $pixis#gv_path()
	nvar/sdfr=pixis_path exp_time
	pixis#ready(exp_time)
	dso#arm_trigger()
	
	return 0
end