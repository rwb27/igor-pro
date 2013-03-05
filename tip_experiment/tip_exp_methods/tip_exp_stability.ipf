#pragma modulename = stability
#pragma rtGlobals=1		// Use modern global access method.

#include "pi_pi733_3cd_stage"

function test_stability(mins, interval)
	variable mins, interval
	variable t_max = 60*mins
	
	pi_stage#open_comms()
	variable init_a, init_b, init_c
	pi_stage#get_pos()
	string gv_folder_pi = pi_stage#gv_path()
	nvar pos_a, pos_b, pos_c
	
	make/o/n=0 pos_a_wave, pos_b_wave, pos_c_wave
	wave pos_a_wave, pos_b_wave, pos_c_wave
	
	display/n=stability_test
	appendtograph/l pos_a_wave
	appendtograph/l=l1 pos_b_wave
	appendtograph/l=l2 pos_c_wave
	modifygraph axisEnab(left)={0, 0.3}, axisEnab(l1)={0.35, 0.65}, axisEnab(l2)={0.7, 1.0}
	setaxis/a=2 left; setaxis/a=2 l1; setaxis/a=2 l2
	
	variable t=0
	init_a = pos_a; init_b = pos_b; init_c = pos_c
	do
		pi_stage#get_pos()
		redimension/n=(numpnts(pos_a_wave) + 1) pos_a_wave
		redimension/n=(numpnts(pos_b_wave) + 1) pos_b_wave
		redimension/n=(numpnts(pos_c_wave) + 1) pos_c_wave
		pos_a_wave[numpnts(pos_a_wave) - 1] = pos_a
		pos_b_wave[numpnts(pos_b_wave) - 1] = pos_b
		pos_c_wave[numpnts(pos_c_wave) - 1] = pos_c
		sleep/s interval
		t += interval
	while (t <= t_max)
end