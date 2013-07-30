#pragma moduleName = tip_system
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "afm_probe"

structure tip_system
	struct afm_probe tip1
	struct afm_probe tip2
	variable separation
	variable k0
	variable m
	variable tip_area
endstructure

static function initialise(s, tip1, tip2, d)
	struct tip_system &s
	struct afm_probe &tip1
	struct afm_probe &tip2
	variable d
	s.separation = d
	s.k0 = ((tip1.k)^(-1) + (tip2.k)^(-1))^(-1)
	s.m = ((tip1.m)^(-1) + (tip2.m)^(-1))^(-1)
	s.tip_area = min(tip1.tip_area, tip2.tip_area)
end