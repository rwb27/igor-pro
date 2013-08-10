#pragma rtGlobals=3		// Use modern global access method and strict wave access.

constant current_k = 0.2
constant current_calibration = 23.138 // V/um
// other values from same day 

function/wave convert_volts_to_force(volt_wave, force_wave_name)
	wave volt_wave
	string force_wave_name
	duplicate/o volt_wave, $force_wave_name
	wave force_wave = $force_wave_name
	variable nm_per_volt = 1000 / current_calibration
	force_wave *= nm_per_volt
	force_wave *= 1e-9
	force_wave *= current_k
	setscale d, 0, 0, "N", force_wave
	return force_wave
end