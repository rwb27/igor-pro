#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function convert(wavelength)
	wave wavelength
	make/o/n=(numpnts(wavelength)) wavenumber
	wavenumber = 1e7 * ( (1/638) - (1/wavelength) )
end