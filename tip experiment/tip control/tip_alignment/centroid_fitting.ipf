#pragma moduleName = centroid_fitting
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include "fit_functions"

function fit_alignment_scan(scan_folder, data)
	dfref scan_folder
	wave data
	
	dowindow/f tip_alignment
	setdatafolder scan_folder
	
	variable z0, a0, x0, sigx, y0, sigy, corr
	imagestats data
	
	variable ix = dimsize(data, 0)-1, iy = dimsize(data, 1)-1
	z0 = 0.25 * (data[0][0] + data[ix][0] + data[0][iy] + data[ix][iy])		// background
	a0 = data[ix/2][iy/2] - z0										// amplitude
	x0 = dimoffset(data, 0) + ix/2 * dimdelta(data, 0)					// x centre
	sigx = 0.25													// x width
	y0 = dimoffset(data, 1) + iy/2 * dimdelta(data, 1)					// y centre
	sigy = 0.25													// y width
	corr = 0														// correlation
	
	// constraints on fit
	// note: {K0,K1,K2,K3,K4,K5,K6} = {z0, a0, x0, sigx, y0, sigy, corr}
	make/o/t/n=0 scan_folder:t_constraints
	wave/t/sdfr=scan_folder t_constraints
	variable q = 0		// Constraint counter
	
	// Constraint -- x0 and y0 must lie within the scan area
	redimension/n=(q+2) t_constraints
	t_constraints[q] = "K2 > " + num2str(dimOffset(data,0)) ; q = q+1
	t_constraints[q] = "K2 < " + num2str(dimOffset(data,0)+dimsize(data,0)*dimDelta(data,0)); q = q+1
	redimension/n=(q+2) t_constraints
	t_constraints[q] = "K4 > " + num2str(dimOffset(data,1)); q = q+1
	t_constraints[q] = "K4 < " + num2str(dimOffset(data,1)+dimsize(data,1)*dimDelta(data,1)); q = q+1
	
	// Constraint -- sigx and sigy must be between 50nm and 1um
	redimension/n=(q+2) t_constraints
	t_constraints[q] = "K3 > 0.05"; q = q+1
	t_constraints[q] = "K3 < 1"; q = q+1
	redimension/n=(q+2) t_constraints
	t_constraints[q] = "K5 > 0.05"; q = q+1
	t_constraints[q] = "K5 < 1"; q = q+1
	
	// Constraint -- corr must be between -1 and 1
	redimension/n=(q+2) t_constraints
	t_constraints[q] = "K6 > -1"; q = q+1
	t_constraints[q] = "K6 < 1"; q = q+1
	
	make/d/n=7/o scan_folder:w_coef
	wave/sdfr=scan_folder w_coef
	w_coef[0] = {z0, a0, x0, sigx, y0, sigy, corr}
	funcfitmd/nthr=0/q gauss2d_elliptic w_coef  data /d/c=t_constraints
	//curvefit/x=1/nthr=0/q gauss2d, kwcwave=w_coef, data /d/c=t_constraints
	modifycontour/w=tip_alignment $("fit_" + nameofwave(data)) labels=0//, ctabLines={*,*,Geo,0}
	wave w_sigma
	setdatafolder root:
	
	string expr = "(.*)_(.*)", wave_id, rest_of_wavename
	splitstring/e=(expr) nameofwave(data), rest_of_wavename, wave_id
	duplicate/o w_coef, scan_folder:$(wave_id + "_w_coef")
	duplicate/o w_sigma, scan_folder:$(wave_id + "_w_sigma")
	variable/g scan_folder:$(wave_id + "_x0") = w_coef[2]
	variable/g scan_folder:$(wave_id + "_y0") = w_coef[4]
end

function gauss2d_elliptic(w, x, y) : fitfunc
	wave w
	variable x, y
	return w[0]+w[1]*exp(-1/2/(1-w[6]^2)*((x-w[2])^2/w[3]^2+(y-w[4])^2/w[5]^2)-2*w[6]*(x-w[2])*(y-w[4])/w[3]/w[5])
end