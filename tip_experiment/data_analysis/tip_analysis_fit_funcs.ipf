#pragma rtGlobals=1		// Use modern global access method.

function cdm_n(A, x0, G, x)
	variable A, x0, G, x
	A = abs(A)
	
	variable x_bar = x / x0
	variable G_bar = G / x0
	variable e = G_bar^2 * (1 + G_bar^2/4)
	variable B = G^2/e
	
	variable f = (A * B * x_bar^2) / (1 + (1/e) * (1-x_bar^2)^2)
	return f
end

function lor1(A, x0, G, x)
	variable A, x0, G, x
	A = abs(A)
	variable f = A * (G / (2 * pi)) / ((x - x0)^2 + (G/2)^2)
	return f
end

function gauss1(A, x0, sigma, x)
	variable A, x0, sigma, x
	A = abs(A)
	variable f = A * exp(-(x - x0)^2 / (2*sigma^2))
	return f
end

function mode_fit(w, x) : FitFunc
	wave w
	variable x
	svar mode_1, mode_2, mode_3, mode_4, mode_5
	variable f = w[0]
	// mode 1
	if (stringmatch(mode_1, "gauss"))
		f += gauss1(w[2], w[1], w[3], x)
	elseif (stringmatch(mode_1, "lor"))
		f += lor1(w[2], w[1], w[3], x)
	endif
	// mode 2
	if (stringmatch(mode_2, "gauss"))
		f += gauss1(w[5], w[4], w[6], x)
	elseif (stringmatch(mode_2, "lor"))
		f += lor1(w[5], w[4], w[6], x)
	endif
	// mode 3
	if (stringmatch(mode_3, "gauss"))
		f += gauss1(w[8], w[7], w[9], x)
	elseif (stringmatch(mode_3, "lor"))
		f += lor1(w[8], w[7], w[9], x)
	endif
	// mode 4
	if (stringmatch(mode_4, "gauss"))
		f += gauss1(w[11], w[10], w[12], x)
	elseif (stringmatch(mode_4, "lor"))
		f += lor1(w[11], w[10], w[12], x)
	endif
	// mode 5
	if (stringmatch(mode_5, "gauss"))
		f += gauss1(w[14], w[13], w[15], x)
	elseif (stringmatch(mode_5, "lor"))
		f += lor1(w[14], w[13], w[15], x)
	endif
	return f
end