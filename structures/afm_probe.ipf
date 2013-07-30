#pragma moduleName = afm_probe
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

structure afm_probe
	// estimated values
	variable k
	variable r
	// measured values
	variable f0
	variable f_fwhm
	// calculated values
	variable w0
	variable w_fwhm
	variable Q
	variable tip_area
	variable m
	variable delta
	variable B
endstructure

static function initialise(s, k ,f0, f_fwhm, r)
	struct afm_probe &s
	variable k, f0, f_fwhm, r
	// estimated values
	s.k = k
	s.r = r
	// measured values
	s.f0 = f0
	s.f_fwhm = f_fwhm
	// calculated values
	s.w0 = 2*pi*s.f0
	s.w_fwhm =2*pi*s.f_fwhm
	s.Q = s.w0 / s.w_fwhm
	s.tip_area = pi*s.r^2
	s.m = s.k / s.w0^2
	s.delta = s.w0/(2*s.Q)
	s.B = 2*s.m*s.delta
end
	