#pragma moduleName = soft_lock
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function/c measure(y, ref, [harmonic])
	wave y, ref
	variable harmonic
	harmonic = 2//paramIsDefault(harmonic) ? 1 : harmonic
	
	duplicate/free ref, smooth_ref
	smooth /b=2 2, smooth_ref //TODO: pick smoothing values nicely!
	variable mr = mean(smooth_ref)
	smooth_ref -= mr
	
	if(harmonic==2)
		smooth_ref = smooth_ref * smooth_ref
		mr = mean(smooth_ref)
		smooth_ref -= mr
	endif
	
	duplicate/free smooth_ref, dr		//take first derivative to get quadrature
	dr[0,numpnts(dr)-2] = smooth_ref[p+1] - smooth_ref[p]
	dr[numpnts(dr)-1] = dr[p-1]
	
	duplicate/free y, temp
	temp = y * smooth_ref
	variable y_dot_r = sum(temp)
	temp = y * dr
	variable y_dot_dr = sum(temp)
	temp = smooth_ref * smooth_ref
	variable r_dot_r = sum(temp)
	temp = dr * dr
	variable dr_dot_dr = sum(temp)
	
	return cmplx(y_dot_r / sqrt(r_dot_r), y_dot_dr / sqrt(dr_dot_dr))
end