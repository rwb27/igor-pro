#pragma moduleName = centroid
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function/c get_centroids(data, x_ax, y_ax)
	wave data, x_ax, y_ax
	adjust_data(data)
	dfref df = getwavesdatafolderdfr(data)
	string expr = "(.*)_(.*)", wave_id, rest_of_wavename
	splitstring/e=(expr) nameofwave(data), rest_of_wavename, wave_id
	variable x0 = get_centroid(data, x_ax, "x")
	variable y0 = get_centroid(data, y_ax, "y")
	variable/c centroids = cmplx(x0, y0)
	variable/g df:$(wave_id + "_x0") = x0
	variable/g df:$(wave_id + "_y0") = y0
	return centroids
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
	make/free/n=(m) first_row = data[p][0]
	make/free/n=(m) last_row = data[p][m-1]
	make/free/n=(n-2) first_column = data[0][p+1]
	make/free/n=(n-2) last_column = data[n-1][p+1]
	make/free/n=0 outer_ring
	concatenate/np/kill/o {first_row, last_row, first_column, last_column}, outer_ring
	return outer_ring
end

function get_centroid(data, ax, axis)
	wave data, ax
	string axis
	// create a free wave duplicate of the data to manipulate
	make/free/n=(dimsize(data,0), dimsize(data,1)) temp_data
	temp_data = data
	waveclear data
	variable bkgd_point = adjust_bkgd(temp_data, axis)
	if (bkgd_point != 0)
		return bkgd_point
	endif
	variable centroid = 0, num = 0, denom = 0
	variable i, j
	if (stringmatch(axis, "x"))
		for (i = 0; i < dimsize(temp_data, 0); i += 1)
			for (j = 0; j < dimsize(temp_data, 1); j += 1)
				num += ax[i] * temp_data[i][j]
				denom += temp_data[i][j]
			endfor
		endfor
	elseif (stringmatch(axis, "y"))
		for (i = 0; i < dimsize(temp_data, 0); i += 1)
			for (j = 0; j < dimsize(temp_data, 1); j += 1)
				num += ax[j] * temp_data[i][j]
				denom += temp_data[i][j]
			endfor
		endfor
	endif
	centroid = num/denom
	return centroid
end

function adjust_bkgd(data, axis)
	wave data
	string axis
	variable n = dimsize(data, 0), m = dimsize(data, 1)
	// subtract/adjust background
	if (stringmatch(axis, "x"))
		wave boundaries = get_vertical_boundaries(data)
	elseif (stringmatch(axis, "y"))
		wave boundaries = get_horizontal_boundaries(data)
	endif
	variable bkgd = wavemax(boundaries)
	variable bkgd_point
	if (bkgd < wavemax(data))
		data -= bkgd
		variable i, j
		for (i = 0; i < dimsize(data, 0); i += 1)
			for (j = 0; j < dimsize(data, 1); j += 1)
				if (data[i][j] < 0)
					data[i][j] = 0
				endif
			endfor
		endfor
		bkgd_point = 0
	elseif (bkgd == wavemax(data))
		imagestats/q data
		if (stringmatch(axis,"x"))
			bkgd_point = V_maxRowLoc
		elseif (stringmatch(axis,"y"))
			bkgd_point = V_maxColLoc
		endif
	endif
	return bkgd_point
end

function/wave get_vertical_boundaries(data)
	// required for x-axis centroid
	// columns are displayed vertically in Igor images
	// vertical edges in an image correspond to the columns in the Igor tables
	wave data
	// sum over first and last columns: rows 0 and n-1 held constant
	variable n = dimsize(data, 0)
	make/free/n=(n) first_column = data[0][p]
	make/free/n=(n) last_column = data[n-1][p]
	make/free/n=0 vertical_boundaries
	concatenate/np/kill/o {first_column, last_column}, vertical_boundaries
	return vertical_boundaries
end

function/wave get_horizontal_boundaries(data)
	// required for y-axis centroid
	// rows are displayed horizontally in Igor images
	// horizontal edges in an image correspond to the rows in the Igor tables
	wave data
	// sum over first and last rows: columns 0 and m-1 held constant
	variable m = dimsize(data, 1)
	make/free/n=(m) first_row = data[p][0]
	make/free/n=(m) last_row = data[p][m-1]
	make/free/n=0 horizontal_boundaries
	concatenate/np/kill/o {first_row, last_row}, horizontal_boundaries
	return horizontal_boundaries
end

// Test Functions //
// gaussian profiles have {bkgd, amp, x0, x_width, y0, y_width, correlation}
function create_gaussian()
	variable nx=6, ny=6
	make/o/n=(nx,ny) test_gaussian
	make/o/n=7 w_coef = {0, 5, nx/2, 50, ny/2, 50, 0.33}
	make/o/n=10 x_ax=x, y_ax=x
	wave test_gaussian, x_ax, y_ax, w_coef
	test_gaussian[][] = 6 - gauss2d(w_coef, x_ax[p], y_ax[q]) + enoise(2e-3)
end

function create_gaussian2()
	variable nx=6, ny=6
	make/o/n=(nx,ny) test_gaussian
	make/o/n=7 w_coef = {0, 5, nx/2, 50, ny/2, 50, 0.33}
	make/o/n=10 x_ax=x, y_ax=x
	wave test_gaussian, x_ax, y_ax, w_coef
	test_gaussian[][] = gauss2d(w_coef, x_ax[p], y_ax[q]) + enoise(2e-3)
end

static function test()
	create_gaussian()
	print get_centroids(root:test_gaussian, root:x_ax, root:y_ax)
	create_gaussian2()
	print get_centroids(root:test_gaussian, root:x_ax, root:y_ax)
end