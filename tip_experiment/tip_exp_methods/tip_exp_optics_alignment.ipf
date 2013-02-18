#pragma rtGlobals=1		// Use modern global access method.

function hyperspec_alignment(angle1, angle2)
	variable angle1, angle2
	hyperspecscan(0.6, 0.03)
	wave wr = root:hyperspecScan:w_coef_633, wb = root:hyperspecScan:w_coef_500
	if (!waveexists(root:hyperspecScan:hyperspec_alignment_data))
		make/o/n=(0,10) root:hyperspecScan:hyperspec_alignment_data
	endif
	wave w = root:hyperspecScan:hyperspec_alignment_data
	variable i = dimsize(w, 0)
	redimension/n=(i+1, 10) w
	w[i][0] = angle1
	w[i][1] = angle2
	w[i][2] = sqrt( (wr[2] - wb[2])^2 + (wr[3] - wb[3])^2 ) // dr
	w[i][3] = atan(wr[3] - wb[3])/(wr[2] - wb[2]) // dtheta
	w[i][4] = wb[2] // x0 blue
	w[i][5] = wb[3] //y0 blue
	w[i][6] = wr[2] // x0 red
	w[i][7] = wr[3] //y0 red
	w[i][8] = wr[2] - wb[2] // dx
	w[i][9] = wr[3] - wb[3] // dy
end