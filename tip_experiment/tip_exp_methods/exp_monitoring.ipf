#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include "pi_pi733_3cd_stage"
#include "Infinity v3.0"
#include "data_handling"
#include "temperature_sensor"

function start_monitoring(delay, overwrite)
	variable delay, overwrite	// interval in seconds
	
	// create time wave if it does not exist
	dfref monitor_df = $(data#check_folder("root:experiment_monitoring"))
	wave/sdfr=monitor_df sensor_time
	if (!waveexists(sensor_time) || overwrite)
		print "creating sensor log"
		make/d/o/n=0 monitor_df:sensor_time
		setscale d, 0, 0, "dat", monitor_df:sensor_time
		make/o/n=0 monitor_df:temperature, monitor_df:humidity
		setscale d, 0, 0, "°C", monitor_df:temperature
		setscale d, 0, 0, "% RH", monitor_df:humidity
		make/o/n=0 monitor_df:positions_a, monitor_df:positions_b, monitor_df:positions_c
	else
		print "appending sensor log"
	endif
	
	wave/sdfr=monitor_df sensor_time
	wave temp = monitor_df:temperature
	wave hum  = monitor_df:humidity
	wave/sdfr=monitor_df positions_a
	wave/sdfr=monitor_df positions_b
	wave/sdfr=monitor_df positions_c
	
	wave current_data = sensor#measure_data()
	variable temp_i = current_data[0], hum_i = current_data[1]
	nvar/sdfr=$(pi_stage#gv_path()) pos_a, pos_b, pos_c
	
	// create data graphs and movie frames
	//dowindow/k sensor_logging
	//display/n=sensor_logging
	//appendtograph temp vs sensor_time
	//appendtograph/r hum vs sensor_time
	//modifygraph rgb=(0,0,0), lstyle(humidity)=3
	//label left "temperature (\\U)"
	//label right "humidity (\\U)"
	//label bottom "time"
	
	dowindow/k mov
	newimage/f/s=0/n=mov  root:Infinity:InfImg
	variable y_offset = 0.4
	string time_stamp = time()
	textbox/c/n=text0/f=0/b=1/a=LT/x=0.5/y=1.0 "\\Z10\\K(65535,65535,65535)"+time_stamp 
	//textbox/c/n=text0/f=0/b=1/a=LB/x=0.5/y=(100*y_offset) "\\Z10\\K(65535,65535,65535)"+time_stamp
	string data_str = num2str(temp_i)+"°C, "+num2str(hum_i)+"% RH"
	textbox/c/n=text1/f=0/b=1/a=RT/x=0.5/y=1.0 "\\Z10\\K(65535,65535,65535)"+data_str
	//textbox/c/n=text1/f=0/b=1/a=RB/x=0.5/y=(100*y_offset) "\\Z10\\K(65535,65535,65535)"+data_str
	modifygraph axisenab(left)={y_offset,1}
	variable ar = 600/800, w = 300, h = (1+y_offset)*w*ar
	modifygraph width = w, height = h
	
	display/host=#/w=(0,1-y_offset,1,1)/fg=(fl, *, fr, fb) temp vs sensor_time
	appendtograph/r hum vs sensor_time
	modifygraph rgb=(0,0,0), lstyle(humidity)=3
	label left "temperature (\\U)"
	label right "humidity (\\U)"
	label bottom "time"
	modifygraph nticks=10, minor=1, fSize=8, btLen=4, stLen=2
	setactivesubwindow ##
	
	doupdate
	dowindow/f mov
	newmovie/o/f=60 as "c:\\users\\hera\\desktop\\exp_monitor"
	
	sensor#open_comms()
	pi_stage#open_comms()
	variable numTicks = delay * 60		// run every <delay> seconds
	CtrlNamedBackground exp_monitor, period=numTicks, proc=monitor_exp
	CtrlNamedBackground exp_monitor, start
end

function stop_monitoring()
	CtrlNamedBackground exp_monitor, stop
	closemovie
	sensor#close_comms()
	pi_stage#close_comms()
end

function monitor_exp(s)
	// Monitors the experiment using the camera and all sensors for <t_range> seconds with a delay
	// of <delay> seconds between measurements.
	
	struct WMBackgroundStruct &s
	dfref monitor_df = $(data#check_folder("root:experiment_monitoring"))
		
	// get data
	variable t = datetime
	string time_stamp = time()
	Infinity_Image()
	time_stamp = time()
	wave current_data = sensor#measure_data()
	variable temp_i = current_data[0], hum_i = current_data[1]
	string data_str = num2str(temp_i)+"°C, "+num2str(hum_i)+"% RH"
	pi_stage#get_pos()
	nvar/sdfr=$(pi_stage#gv_path()) pos_a, pos_b, pos_c
		
	// append data
	wave/sdfr=monitor_df sensor_time
	wave temp = monitor_df:temperature
	wave hum  = monitor_df:humidity
	variable i = dimsize(sensor_time, 0)
	redimension/n=(i+1) sensor_time, temp, hum
	sensor_time[i] = t
	temp[i] = temp_i
	hum[i] = hum_i
	
	wave/sdfr=monitor_df positions_a
	wave/sdfr=monitor_df positions_b
	wave/sdfr=monitor_df positions_c	
	redimension/n=(i+1) positions_a, positions_b, positions_c
	positions_a[i] = pos_a
	positions_b[i] = pos_b
	positions_c[i] = pos_c
	
	// append movie frame
	dowindow/f mov
	textbox/c/n=text0 "\\Z10\\K(65535,65535,65535)"+time_stamp
	textbox/c/n=text1 "\\Z10\\K(65535,65535,65535)"+data_str
	addmovieframe
	doupdate
	return 0
end
