#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include "pi_pi733_3cd_stage"
#include "Infinity v3.0"
#include "data_handling"

function test_piezo()
	dfref pztf = $(data#check_folder("root:piezo_testing"))
	dfref images = $(data#check_folder("root:piezo_testing:images"))
	variable n = 12*60
	make/o/n=(0) pztf:positions_a, pztf:positions_b, pztf:positions_c
	wave positions_a = pztf:positions_a
	wave positions_b = pztf:positions_b
	wave positions_c = pztf:positions_c
	string time_stamp = time()
	newimage/f/s=0/n=image  root:Infinity:InfImg
	textbox/c/n=text0/f=0/b=1/a=LT "\\Z11\\K(65535,65535,65535)"+time_stamp
	newmovie/o as "c:\\users\\hera\\desktop\\piezo_drift"
	dowindow/k pz_test
	display/n=pz_test
	appendtograph positions_a
	appendtograph positions_b
	appendtograph/r positions_c
	pi_stage#open_comms()
	variable t_range = 60*60, delay = 60//t_range/n
	variable i = 0
	nvar/sdfr=$(pi_stage#gv_path()) pos_a, pos_b, pos_c
	do
		if (getkeystate(0) & 32)
			break
		endif
		Infinity_Image()
		time_stamp = time()
		dowindow/f image
		textbox/c/n=text0/f=0/b=1/a=LT "\\Z11\\K(65535,65535,65535)"+time_stamp
		addmovieframe
		//duplicate/o root:Infinity:InfImg, images:$("img_"+num2str(i))
		pi_stage#get_pos()
		redimension/n=(i+1) positions_a, positions_b, positions_c
		positions_a[i] = pos_a
		positions_b[i] = pos_b
		positions_c[i] = pos_c
		doupdate
		i += 1
		sleep/s delay
	while (i < n)
	closemovie
	pi_stage#close_comms()
	make/t/o/n=(13,2) pztf:piezo_test_results
	wave/t pzt = pztf:piezo_test_results
	pzt[0][0] = "time stamp"; pzt[0][1] = date() + " " + time()
	wavestats/q positions_a
	pzt[1][0] = "pos_a"
	pzt[2][0] = "avg"; pzt[2][1] = num2str(V_avg)
	pzt[3][0] = "sdev"; pzt[3][1] = num2str(1000*V_sdev)
	pzt[4][0] = "pk-pk"; pzt[4][1] = num2str(1000*(V_max-V_min))
	wavestats/q positions_b
	pzt[5][0] = "pos_b"
	pzt[6][0] = "avg"; pzt[6][1] = num2str(V_avg)
	pzt[7][0] = "sdev"; pzt[7][1] = num2str(1000*V_sdev)
	pzt[8][0] = "pk-pk"; pzt[8][1] = num2str(1000*(V_max-V_min))
	wavestats/q positions_c
	pzt[9][0] = "pos_c"
	pzt[10][0] = "avg"; pzt[10][1] = num2str(V_avg)
	pzt[11][0] = "sdev"; pzt[11][1] = num2str(1000*V_sdev)
	pzt[12][0] = "pk-pk"; pzt[12][1] = num2str(1000*(V_max-V_min))
end