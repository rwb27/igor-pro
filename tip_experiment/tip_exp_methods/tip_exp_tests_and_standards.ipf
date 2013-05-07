#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "tip_exp_noise_testing"
#include "hp33120a_sig_gen"

function standard_electronic_testing()
	make/t/o/n=(0,2) test_data
	wave/t ts = test_data
	variable i = 0
	redimension/n=(dimsize(ts,0)+1,2) ts; i+=1
	ts[i][0] = "# Noise Testing #"
	variable x

	// OPEN CIRCUIT TESTING
	print "open circuit testing..."
	redimension/n=(dimsize(ts,0)+1,2) ts; i+=1
	ts[i][0] = "## Open Circuit Noise Testing ##"
	
	// AC NOISE TESTING
	// prompt for correct circuit configuration
	prompt x, "click continue"
	doprompt "Switch to a.c. lockin measurement: ", x
	if (V_Flag)
		return -1								// User canceled
	endif
	redimension/n=(dimsize(ts,0)+1,2) ts; i+=1
	ts[i][0] = "### A.C. Alignment Circuit Testing ###"
	i = run_ac_testing(ts, i)
	
	// DC NOISE TESTING
	// prompt to switch circuits
	prompt x, "click continue"
	doprompt "Switch to d.c. measurement circuit", x
	if (V_Flag)
		return -1								// User canceled
	endif
	redimension/n=(dimsize(ts,0)+1,2) ts; i+=1
	ts[i][0] = "### D.C. Measurement Circuit Testing ###"
	i = run_dc_testing(ts, i)
	
	// DC AMP TESTING
	// prompt to switch circuits
	prompt x, "click continue"
	doprompt "Switch to d.c. amplifier measurement circuit"
	if (V_Flag)
		return -1								// User canceled
	endif
	redimension/n=(dimsize(ts,0)+1,2) ts; i+=1
	ts[i][0] = "### D.C. Amplified Measurement Circuit Testing ###"
	i = run_dc_amp_testing(ts, i)
	
	// CLOSED CIRCUIT TESTING
	print "closed circuit testing..."
	redimension/n=(dimsize(ts,0)+1,2) ts; i+=1
	ts[i][0] = "## Open Circuit Noise Testing ##"
	
	// AC ALIGNMENT TESTING
	// alignment test - capacitor
	redimension/n=(dimsize(ts,0)+1,2) ts; i+=1
	ts[i][0] = "### A.C. Alignment Circuit Testing ###"
	i = run_ac_testing(ts, i)
	
	// DC MEASUREMENT TESTING
	// prompt to switch circuits
	prompt x, "click continue"
	doprompt "Switch to d.c. measurement circuit", x
	if (V_Flag)
		return -1								// User canceled
	endif
	// measurement test - 100M resistor									//
	redimension/n=(dimsize(ts,0)+1,2) ts; i+=1								//
	ts[i][0] = "### D.C. Measurement Circuit Testing ###"						//
	i = run_dc_testing(ts, i)
	
	// DC AMP TESTING
	// prompt to switch circuits
	prompt x, "click continue"
	doprompt "Switch to d.c. amplifier measurement circuit"
	if (V_Flag)
		return -1								// User canceled
	endif
	// oscilloscope test - 13k resistor
	redimension/n=(dimsize(ts,0)+1,2) ts; i+=1
	ts[i][0] = "### D.C. Amplified Measurement Circuit Testing ###"
	i = run_dc_amp_testing(ts, i)
	
	// create report
	save/j ts as "C:\\users\\hera\\desktop\\tip_exp\\electronics_test_"+date()+".dat"
end

function run_ac_testing(ts, i)
	wave/t ts
	variable i
	print "testing a.c. circuitry..."
	// test 1: connect up the tips as in an experiment but apply no bias
	print "a.c. circuit test 1"
	redimension/n=(dimsize(ts,0)+1,2) ts; i+=1
	ts[i][0] = "**0 V bias**"
	wave ac_noise_results = ac_noise_test()								// do ac noise test
	redimension/n=(dimsize(ts,0)+6,2) ts; i+=1								// record results
	ts[i][0] = "V_avg"; ts[i][1] = num2str(ac_noise_results[0]); i+=1				//
	ts[i][0] = "V_sdev"; ts[i][1] = num2str(ac_noise_results[1]); i+=1			//
	ts[i][0] = "I_avg"; ts[i][1] = num2str(ac_noise_results[3]); i+=1				//
	ts[i][0] = "I_sdev"; ts[i][1] = num2str(ac_noise_results[4]); i+=1				//
	ts[i][0] = "DSO_avg"; ts[i][1] = num2str(ac_noise_results[6]); i+=1			//
	ts[i][0] = "DSO_sdev"; ts[i][1] = num2str(ac_noise_results[7]);				//
	print "test complete"													//
	// test 2: connect up the tips as in an experiment and apply a 12 V bias
	print "a.c. circuit test 2"
	redimension/n=(dimsize(ts,0)+1,2) ts; i+=1
	ts[i][0] = "**12 V bias**"
	sig_gen#open_comms()												// set voltage
	sig_gen#set_amplitude(12/20)											//
	sig_gen#close_comms()												//
	wave ac_noise_results = ac_noise_test()								// do ac noise test
	redimension/n=(dimsize(ts,0)+6,2) ts; i+=1								// record results
	ts[i][0] = "V_avg"; ts[i][1] = num2str(ac_noise_results[0]); i+=1				//
	ts[i][0] = "V_sdev"; ts[i][1] = num2str(ac_noise_results[1]); i+=1			//
	ts[i][0] = "I_avg"; ts[i][1] = num2str(ac_noise_results[3]); i+=1				//
	ts[i][0] = "I_sdev"; ts[i][1] = num2str(ac_noise_results[4]); i+=1				//
	ts[i][0] = "DSO_avg"; ts[i][1] = num2str(ac_noise_results[6]); i+=1			//
	ts[i][0] = "DSO_sdev"; ts[i][1] = num2str(ac_noise_results[7]);				//
	print "test complete"													//
	// analysis: calculate signal/noise ratio
	print "a.c. alignment testing complete"
	return i
end

function run_dc_testing(ts, i)
	wave/t ts
	variable i
	print "testing d.c. circuit..."
	// test 1: connect up the tips as in an experiment but apply no bias
	print "d.c. circuit test 1"
	redimension/n=(dimsize(ts,0)+1,2) ts; i+=1
	ts[i][0] = "**0 V bias**"												// record test header
	smu#open_comms()													//
	smu#output(0)														// set output off
	smu#close_comms()													//
	wave dc_noise_results = dc_noise_test()								// do dc noise test
	redimension/n=(dimsize(ts,0)+4,2) ts; i+=1								// record results
	ts[i][0] = "V_avg"; ts[i][1] = num2str(dc_noise_results[0]); i+=1				//
	ts[i][0] = "V_sdev"; ts[i][1] = num2str(dc_noise_results[1]); i+=1			//
	ts[i][0] = "I_avg"; ts[i][1] = num2str(dc_noise_results[3]); i+=1				//
	ts[i][0] = "I_sdev"; ts[i][1] = num2str(dc_noise_results[4])					//
	print "test complete"													//
	// test 2: connect up the tips as in an experiment and apply a 100 mV bias
	print "d.c. circuit test 2"
	redimension/n=(dimsize(ts,0)+1,2) ts; i+=1
	ts[i][0] = "**100 mV bias**"											// record test header
	smu#open_comms()													//
	smu#set_voltage(100e-3)												// set voltage
	smu#set_voltage_range(100e-3)										// set voltage range
	smu#output(1)														// set output on
	smu#close_comms()													//
	wave dc_noise_results = dc_noise_test()								// do dc noise test
	redimension/n=(dimsize(ts,0)+4,2) ts; i+=1								// record results
	ts[i][0] = "V_avg"; ts[i][1] = num2str(dc_noise_results[0]); i+=1				//
	ts[i][0] = "V_sdev"; ts[i][1] = num2str(dc_noise_results[1]); i+=1			//
	ts[i][0] = "I_avg"; ts[i][1] = num2str(dc_noise_results[3]); i+=1				//
	ts[i][0] = "I_sdev"; ts[i][1] = num2str(dc_noise_results[4])					//
	print "test complete"													//
	// analysis: calculate signal/noise ratio
	print "d.c. testing complete"
	return i
end

function run_dc_amp_testing(ts, i)
	wave/t ts
	variable i
	print "testing d.c. amp circuit..."
	// test 1: connect up the tips as in an experiment but apply no bias
	print "d.c. amp circuit test 1"
	redimension/n=(dimsize(ts,0)+1,2) ts; i+=1
	ts[i][0] = "**0 V bias**"												// record test header
	smu#open_comms()													//
	smu#output(0)														// set output off
	smu#close_comms()													//
	wave dc_amp_noise_results = dc_amp_noise_test()						// do dc amp noise test
	redimension/n=(dimsize(ts,0)+6,2) ts; i+=1								// record results
	ts[i][0] = "V_avg"; ts[i][1] = num2str(dc_amp_noise_results[0]); i+=1		//
	ts[i][0] = "V_sdev"; ts[i][1] = num2str(dc_amp_noise_results[1]); i+=1		//
	ts[i][0] = "I_avg"; ts[i][1] = num2str(dc_amp_noise_results[3]); i+=1			//
	ts[i][0] = "I_sdev"; ts[i][1] = num2str(dc_amp_noise_results[4]); i+=1		//
	ts[i][0] = "DSO_avg"; ts[i][1] = num2str(dc_amp_noise_results[6]); i+=1		//
	ts[i][0] = "DSO_sdev"; ts[i][1] = num2str(dc_amp_noise_results[7]); i+=1	//
	print "test complete"													//
	// test 2: connect up the tips as in an experiment and apply a 100 mV bias
	print "d.c. amp circuit test 2"
	redimension/n=(dimsize(ts,0)+1,2) ts; i+=1
	ts[i][0] = "**100 mV bias**"											// record test header
	smu#open_comms()													//
	smu#set_voltage(100e-3)												// set voltage
	smu#set_voltage_range(100e-3)										// set voltage range
	smu#output(1)														// set output on
	smu#close_comms()													//
	wave dc_amp_noise_results = dc_amp_noise_test()						// do dc amp noise test
	redimension/n=(dimsize(ts,0)+6,2) ts; i+=1								// record results
	ts[i][0] = "V_avg"; ts[i][1] = num2str(dc_amp_noise_results[0]); i+=1		//
	ts[i][0] = "V_sdev"; ts[i][1] = num2str(dc_amp_noise_results[1]); i+=1		//
	ts[i][0] = "I_avg"; ts[i][1] = num2str(dc_amp_noise_results[3]); i+=1			//
	ts[i][0] = "I_sdev"; ts[i][1] = num2str(dc_amp_noise_results[4]); i+=1		//
	ts[i][0] = "DSO_avg"; ts[i][1] = num2str(dc_amp_noise_results[6]); i+=1		//
	ts[i][0] = "DSO_sdev"; ts[i][1] = num2str(dc_amp_noise_results[7]); i+=1	//
	print "test complete"													//
	// analysis: calculate signal/noise ratio
	print "d.c. amp testing complete"
	return i
end