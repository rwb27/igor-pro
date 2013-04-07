#pragma ModuleName = tools
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

constant h = 6.626068e-34
constant c = 2.99792458e8
constant e = 1.60217646e-19

function wavelength_to_index_oo(wavelength)
	variable wavelength
	wave wl_wave = root:oo:data:current:wl_wave
	variable index, i = 0
	do
		i += 1
	while (wl_wave[i] < wavelength)
	if ((wl_wave[i] - wavelength) > (wavelength - wl_wave[i-1]))
		i -= 1
	endif
	return i
end

function wavelength_to_index(wl_wave, wavelength)
	wave wl_wave
	variable wavelength
	variable index, i = 0
	do
		i += 1
	while (wl_wave[i] < wavelength)
	if ((wl_wave[i] - wavelength) > (wavelength - wl_wave[i-1]))
		i -= 1
	endif
	return i
end

function wavelength_to_energy(wavelength)		// convert to eV
	variable wavelength
	variable energy = h*c / wavelength / e
	return energy
end