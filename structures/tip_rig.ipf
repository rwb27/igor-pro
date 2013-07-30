#pragma moduleName = tip_rig
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "tip_system"

structure tip_rig
	struct tip_system tips
	variable V_dc
	variable V_ac
	variable f
endstructure

static function initialise(s, tips)
	struct tip_rig &s
	struct tip_system &tips
	s.V_dc = 0
	s.V_ac = 10
	s.f = 6.5e3
end

static function change_param(s, [V_dc, V_ac, f])
     struct tip_rig &s
     s.V_dc = IfParamIsDefault(V_dc) ? 0 : V_dc
     s.V_ac = IfParamIsDefault(V_ac) ? 10 : V_ac
     s.f = IfParamIsDefault(f) ? 6.5e3 : f
end

static function set_driving_voltage(V_dc, V_ac, f)
	variable V_dc, V_ac, f
	function driving_voltage(t)
		return V_dc + V_ac * cos(2*pi*f*t)
	end
	return driving_voltage
end