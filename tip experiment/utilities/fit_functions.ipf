#pragma ModuleName = func
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

function gaussian(w, x) : fitfunc
	wave w
	variable x
	variable x0 = w[0], A = abs(w[1]), sigma = abs(w[2])
	variable f = A * ( 1 / (sigma * sqrt(2*pi)) ) * exp( -(x - x0)^2 / (2 * sigma^2) )
	if (f == NaN)
		f = 0.0
		print "/0 error"
	endif
	return f
end

function lorentzian(w, x) : fitfunc
	wave w
	variable x
	variable x0 = w[0], A = abs(w[1]), G = abs(w[2])
	variable f = A * ( 1/pi ) * ( (G/2) / ( (x - x0)^2 + (G/2)^2 ) )
	return f
end

function gaussian_2d(w, x, y) : fitfunc
	wave w
	variable x, y
	variable bkgd = w[0], A = w[1]
	variable x0 = w[2], sig_x = w[3], y0 = w[4], sig_y = w[5]
	variable corr = w[6]
	variable f = bkgd
	f += A * exp( -1 * (1 / (1-corr^2)) * ( ((x-x0)^2 / (2*sig_x^2)) + ((y-y0)^2 / (2*sig_y^2)) - ((2*corr*(x - x0)*(y - y0)) / (sig_x*sig_y)) ))
	return f
end