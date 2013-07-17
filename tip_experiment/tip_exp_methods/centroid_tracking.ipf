#pragma moduleName = centroid
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function adjust_bkgd(data, axis)
	wave data
	string axis
	variable n = dimsize(data, 0), m = dimsize(data, 1)
	// subtract/adjust background
	print "getting background"
	variable a,b,c,d
	if (stringmatch(axis, "y"))
		// first row
		make/free/n=(n) temp = data[0][p]
		a = wavemax(temp)
		// last row
		make/free/n=(n) temp = data[n-1][p]
		b = wavemax(temp)
		c = -1; d = -1
	elseif (stringmatch(axis, "x"))
		a = -1; b = -1
		// first column
		make/free/n=(m) temp = data[p][0]
		c = wavemax(temp)
		// last column
		make/free/n=(m) temp = data[p][m-1]
		d = wavemax(temp)
	endif
	make/free/n=4 temp={a,b,c,d}
	variable bkgd = wavemax(temp)
	if (bkgd < wavemax(data))
		print "subtracting background"
		data -= wavemax(temp)
		print "adjusting data"
		variable i, j
		for (i = 0; i < dimsize(data, 0); i += 1)
			for (j = 0; j < dimsize(data, 1); j += 1)
				if (data[i][j] < 0)
					data[i][j] = 0
				endif
			endfor
		endfor
		print "background subtracted"
	endif
	return 0
end

function adjust_data(data)
	wave data
	variable n = dimsize(data, 0), m = dimsize(data, 1)
	// normalise data
	variable wmax = wavemax(data)
	data /= wmax
	// invert data if necessary
	if (mean(get_outer_ring(data)) > data[n/2][m/2])
		print "inverting", nameofwave(data)
		data = 1 - data
	endif
end

function/wave get_outer_ring(data)
	wave data
	variable n = dimsize(data, 0), m = dimsize(data, 1)
	make/free/n=(n) first_row = data[0][p]
	make/free/n=(n) last_row = data[n-1][p]
	make/free/n=(m-2) first_column = data[p+1][0]
	make/free/n=(m-2) last_column = data[p+1][m-1]
	make/free/n=0 outer_ring
	concatenate/np/kill/o {first_row, last_row, first_column, last_column}, outer_ring
	return outer_ring
end

function get_centroid(data, ax, axis)
	wave data, ax
	string axis
	adjust_bkgd(data, axis)
	variable centroid = 0, num = 0, denom = 0
	variable i, j
	if (stringmatch(axis, "x"))
		for (i = 0; i < dimsize(data, 0); i += 1)
			for (j = 0; j < dimsize(data, 1); j += 1)
				num += ax[i] * data[i][j]
				denom += data[i][j]
			endfor
		endfor
	elseif (stringmatch(axis, "y"))
		for (i = 0; i < dimsize(data, 0); i += 1)
			for (j = 0; j < dimsize(data, 1); j += 1)
				num += ax[j] * data[i][j]
				denom += data[i][j]
			endfor
		endfor
	endif
	centroid = num/denom
	return centroid
end

function get_centroids(data, x_ax, y_ax)
	wave data, x_ax, y_ax
	adjust_data(data)
	dfref df = getwavesdatafolderdfr(data)
	string expr = "(.*)_(.*)", wave_id, rest_of_wavename
	splitstring/e=(expr) nameofwave(data), rest_of_wavename, wave_id
	variable/g df:$(wave_id + "_x0") = get_centroid(data, x_ax, "x")
	variable/g df:$(wave_id + "_y0") = get_centroid(data, y_ax, "y")
	return 0
end

// Test Functions //
function create_gaussian()
	make/o/n=(10,10) test_gaussian
	make/o/n=7 w_coef = {0, 5, 5.33, 50, 6.33, 50, 0.33}
	make/o/n=10 x_ax=x, y_ax=x
	wave test_gaussian, x_ax, y_ax, w_coef
	test_gaussian[][] = 6 - gauss2d(w_coef, x_ax[p], y_ax[q])
end

function create_gaussian2()
	make/o/n=(10,10) test_gaussian
	make/o/n=7 w_coef = {0, 5, 5.33, 50, 6.33, 50, 0.33}
	make/o/n=10 x_ax=x, y_ax=x
	wave test_gaussian, x_ax, y_ax, w_coef
	test_gaussian[][] = gauss2d(w_coef, x_ax[p], y_ax[q])
end

function print_centroids()
	create_gaussian()
	print get_centroids(root:test_gaussian, root:x_ax, root:y_ax)
	create_gaussian2()
	print get_centroids(root:test_gaussian, root:x_ax, root:y_ax)
end