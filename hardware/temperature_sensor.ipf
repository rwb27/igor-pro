#pragma moduleName = sensor
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

static function get_sensor(sensor_name)
	string sensor_name
	variable com = 28
	return com
end

static function sensor_select()
	VDTOperationsPort2 COM28
end

static function open_comms()
	VDT2/P=COM28 baud=9600
	sensor_select()
	VDTOpenPort2 COM28
	VDTWrite2 "R\n"
	return 0
end

static function close_comms()
	VDTOperationsPort2 None
	VDTClosePort2 COM28
	return 0
end

static function measure_temperature()
	string data_str="", char
	variable temp
	sensor_select()
	VDTWrite2 "temp?\n"
	
	// temperature sensor has a 5 second delay between measurements
	// wait at least 5 seconds for command to be accepted
	variable t, t0 = datetime
	do
		sleep/t 10
		VDTGetStatus2 0,0,0
		t = datetime
	while (!V_VDT && (t-t0) <= 5)
	
	// read out each line - should all be one line but with some empty characters
	do
		VDTGetStatus2 0,0,0
		if (V_VDT == 0)
			break
		endif
		VDTRead2/O=10 temp
		VDTRead2/O=10/T="\r\n" char
	while (1)
	
	return temp
end

static function measure_humidity()
	string data_str="", char
	variable hum
	sensor_select()
	VDTWrite2 "hum?\n"
	
	// temperature sensor has a 5 second delay between measurements
	// wait at least 5 seconds for command to be accepted
	variable t, t0 = datetime
	do
		sleep/t 10
		VDTGetStatus2 0,0,0
		t = datetime
	while (!V_VDT && (t-t0) <= 5)
	
	// read out each line - should all be one line but with some empty characters
	do
		VDTGetStatus2 0,0,0
		if (V_VDT == 0)
			break
		endif
		VDTRead2/O=10 hum
		VDTRead2/O=10/T="\r\n" char
	while (1)
	
	return hum
end

static function/wave measure_data()
	string data_str="", char
	variable secs, temp, hum, dew
	sensor_select()
	VDTWrite2 "measure\n"
	
	// temperature sensor has a 5 second delay between measurements
	// wait at least 5 seconds for command to be accepted
	variable t, t0 = datetime
	do
		sleep/t 10
		VDTGetStatus2 0,0,0
		t = datetime
	while (!V_VDT && (t-t0) <= 5)
	//print t-t0
	
	// read out each line - should all be one line but with some empty characters
	do
		VDTGetStatus2 0,0,0
		if (V_VDT == 0)
			break
		endif
		VDTRead2/O=10 secs, temp, hum
		VDTRead2/O=10/T="\r\n" char
		if (temp == 0)
			print secs, temp, hum
		endif
	while (1)
	
	make/free/n=3 data = {secs, temp, hum}
	return data
end

static function purge_buffer()
	string char
	do
		VDTGetStatus2 0,0,0
		if (V_VDT == 0)
			break
		endif
		VDTRead2/Q/O=1 char
		print char
	while (1)
end

function log_data(s)	
	struct WMBackgroundStruct &s
	
	wave sensor_log
	if (!waveexists(sensor_log))
		make/o/n=(0,3) sensor_log
		make/d/o/n=0 sensor_log_time
		setscale d, 0, 0, "dat", sensor_log_time
	endif
	
	wave current_data = sensor#measure_data()
	variable i = dimsize(sensor_log, 0), j = numpnts(current_data)
	redimension/n=(i+1,j) sensor_log
	sensor_log[i][] = current_data[q]
	
	wave sensor_log_time
	redimension/n=(i+1) sensor_log_time
	sensor_log_time[i] = datetime
	doupdate
	
	return 0	// continue background task
end

function start_data_logging(dt)
	variable dt	// time interval in seconds
	sensor#open_comms()
	variable numTicks = dt * 60		// run every 60 seconds
	CtrlNamedBackground data_logging, period=numTicks, proc=log_data
	CtrlNamedBackground data_logging, start
end

function stop_data_logging()
	CtrlNamedBackground data_logging, stop
	sensor#close_comms()
end

function display_data_logging()
	wave sensor_log, sensor_log_time
	dowindow/k sensor_logging
	display/n=sensor_logging
	appendtograph sensor_log[][0] vs sensor_log_time
	appendtograph/r sensor_log[][1] vs sensor_log_time
	modifygraph rgb=(0,0,0), lstyle(sensor_log#1)=3
	label left "temperature (°C)"
	label right "humidity (%)"
	label bottom "time"
end