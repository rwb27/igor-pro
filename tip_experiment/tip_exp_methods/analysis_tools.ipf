#pragma ModuleName = tools
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

constant h = 6.626068e-34
constant c = 2.99792458e8
constant e = 1.60217646e-19

function wavelength_to_energy(wavelength)		// convert to eV
	variable wavelength
	variable energy = h*c / wavelength / e
	return energy
end