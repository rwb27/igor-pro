#pragma rtGlobals=1		// Use modern global access method.
#include "PI733_3CDStage_1"

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

function HyperSpecScan(gridSize, stepSize)
	variable gridSize  			// in um
	variable stepSize 			// in um
	
	// Get PZ positions
	nvar initA = root:gVariables:PZactuators:posA
	nvar initB = root:gVariables:PZactuators:posB
	nvar initC = root:gVariables:PZactuators:posC
	variable posA, posB, delay = 0.2		// Delay between movements
	
	// Move PZs to initial positions
	posA = initA - gridSize/2
	posB = initB - gridSize/2
	movePI("A", posA); sleep/s delay
	movePI("B", posB); sleep/s delay
	
	if (datafolderexists("root:hyperspecScan"))
		setdatafolder root:hyperspecScan			// Folder to store data
	else
		newdatafolder/s root:hyperspecScan
	endif
	duplicate/o root:OO:Data:Current:wl_wave, lambda		// Get Wavelength wave
	make/o/n=(gridSize/stepSize+1, gridSize/stepSize+1, numpnts(lambda)) scatterData		// 3D data wave
	scatterData = 0
	setscale/p x posA, stepSize, scatterData			// Set row dimension (A)
	setscale/p y posB, stepSize, scatterData			// Set column dimension (B)
	
	variable wl1 = 633, wl2 = 500
	variable wl1i, wl2i, i = 0
	do
		i += 1
	while (lambda[i] < wl1)
	if ((lambda[i] - wl1) > (wl1 - lambda[i-1]))
		i -= 1
	endif
	wl1i = i; i = 0
	do
		i += 1
	while (lambda[i] < wl2)
	if ((lambda[i] - wl2) > (wl2 - lambda[i-1]))
		i -= 1
	endif
	wl2i = i
	
	dowindow/k hyperspecScan
	display/n=hyperspecScan
	appendimage scatterData
	modifyimage scatterData plane = wl1i
	appendimage/L=L2 scatterData
	modifyimage scatterData#1 plane = wl2i
	
	modifygraph tick=2,mirror=1,fSize=14,standoff=0,axisEnab(left)={0.51,1}
	modifygraph axisEnab(L2)={0,0.49},freePos(L2)=0
	Modifygraph width=226.772
	modifygraph height={Aspect,2}
	modifyimage scatterData ctab= {*,*,ColdWarm,0}
	modifyimage scatterData ctabAutoscale=2,lookup= $""
	modifyimage scatterData#1 ctab= {*,*,ColdWarm,0}
	modifyimage scatterData#1 ctabAutoscale=2,lookup= $""
//	SetAxis/A/R left;DelayUpdate
//	SetAxis/A/R bottom;DelayUpdate
//	SetAxis/A/R L2
	
	variable q1, q2 // Loop counters
	do		
		do
			if(GetKeyState(0) & 32)	// Check for user abort (escape key)
				movePI("A", initA); sleep/s delay
				movePI("B", initB); sleep/s delay
				abort
			endif
			OO_read()								// Measure spectrum
			wave w=root:OO:Data:Current:Spectra		// Declare spectrum wave
			scatterData[q1][q2][] = w[r]					
			doUpdate					
			posA += stepSize		// Increment grid position
			movePI("A", posA); sleep/s delay		
			q1 += 1
		while(q1 <= (gridSize/stepSize))
		
		posA = initA - gridSize/2		// Reset A position
		q1 = 0						// Reset A counter
		
		posB += stepSize		// Increment grid position
		movePI("B", posB); sleep/s delay
		q2 += 1					// Reset B counter
	while(q2 <= (gridSize/stepSize))
	
	// Move back to initial position
	movePI("A", initA); sleep/s delay
	movePI("B", initB); sleep/s delay
	setDataFolder root:				// Return to root directory
	//fit_hyperspec("root:hyperspecScan:scatterData", wl1)
	//fit_hyperspec("root:hyperspecScan:scatterData", wl2)
	fit_hyperspec(wl1); fit_hyperspec(wl2)
end

function fit_hyperspec(wlen)
	//string wName
	variable wlen
	wave w = root:hyperspecScan:scatterData, lambda = root:hyperspecScan:lambda
	variable z0, a0, x0, sigx, y0, sigy, corr
	variable i = 0
	do
		i += 1
	while (lambda[i] < wlen)
	if ( abs(lambda[i] - wlen) > abs(wlen - lambda[i-1]))
		i -= 1
	endif
	variable wleni = i
		
	// Amplitude: Difference between z0 and the grid centre value
	imagestats/m=1/p=(wleni) w
	z0 = V_min
	a0 = V_max - z0
	// Centre-points: The location of the maximum grid value
	x0 = DimOffset(w,0)+V_maxRowLoc*DimDelta(w,0)
	y0 = DimOffset(w,1)+V_maxColLoc*DimDelta(w,1)
	// Peak width: Set to 100 nm, a typical starting point
	sigx = 0.1
	sigy = 0.1
	// xy correlation: Set to 0
	corr = 0
	
	make/d/n=7/o $("root:hyperspecScan:w_coef_"+num2str(wlen))
	wave w_coef = $("root:hyperspecScan:w_coef_"+num2str(wlen))
	w_coef[0] = {z0, a0, x0, y0, sigx, sigy, corr}
	FuncFitMD/NTHR=0/Q Gauss2Dc, w_coef, w[][][wleni] /D//C=constraintWave
end

function Gauss2Dc(w,x,y) : FitFunc
	wave w
	variable x, y
	variable z0 = w[0], A = w[1], x0 = w[2], y0 = w[3], sigx = w[4], sigy = w[5], corr = w[6]
	variable f = z0 + A * exp( ( -1/(2*(1-corr^2)) ) * ( ( (x - x0)^2 / (2*sigx^2) ) + ( (y - y0)^2 / (2*sigy^2) ) - ( (2*corr*(x-x0)*(y-y0))/(sigx*sigy) ) ) )
	return f
end

// -- PANEL -- //

Function DisplayHyperSpec(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			string dataloc = "root:hyperspecScan"
			nvar wlen = root:gVariables:hyperspec_imaging:wavelength
			// find index from wavelength
			wave lambda = $(dataloc+":lambda")
			variable i
			do
				i += 1
			while (lambda[i] < wlen)
			if ((lambda[i] - wlen) > (wlen - lambda[i-1]))
				i -= 1
			endif
			// display data
			dowindow/k HyperspecImage
			//display/n=HyperSpec
			//appendimage/w=HyperSpec $(dataloc+":scatterData")
			newimage/f/n=HyperspecImage $(dataloc+":scatterData")
			modifyimage scatterData ctab= {*,*,ColdWarm,0}
			modifyimage scatterData plane = i
			modifyimage scatterData ctabAutoscale=3,lookup= $""
			textbox/c/n=text0/f=0/b=1/g=(65280,65280,0)/a=rt "\\Z10\\F'Symbol'l\\F'Arial' = "+num2str(wlen)+" nm"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function SetWavelength(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			dowindow HyperspecImage
			if (V_flag == 1)
				string dataloc = "root:hyperspecScan"
				wave lambda = $(dataloc+":lambda")
				variable i
				do
					i += 1
				while (lambda[i] < dval)
				if ((lambda[i] - dval) > (dval - lambda[i-1]))
					i -= 1
				endif
				modifyimage scatterData plane = i
				textbox/k/n=text0
				textbox/c/n=text0/f=0/b=1/g=(65280,65280,0)/a=rt "\\Z10\\F'Symbol'l\\F'Arial' = "+num2str(dval)+" nm"
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function WavelengthSlider(sa) : SliderControl
	STRUCT WMSliderAction &sa

	switch( sa.eventCode )
		case -1: // control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				Variable curval = sa.curval
				dowindow HyperspecImage
				if (V_flag == 1)
					string dataloc = "root:hyperspecScan"
					wave lambda = $(dataloc+":lambda")
					variable i
					do
						i += 1
					while (lambda[i] < curval)
					if ((lambda[i] - curval) > (curval - lambda[i-1]))
						i -= 1
					endif
					modifyimage scatterData plane = i
					textbox/k/n=text0
					textbox/c/n=text0/f=0/b=1/g=(65280,65280,0)/a=rt "\\Z10\\F'Symbol'l\\F'Arial' = "+num2str(curval)+" nm"
				endif
			endif
			break
	endswitch

	return 0
End

Window HyperSpecImaging() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(790,75,994,152) as "HyperspecImage"
	ModifyPanel frameStyle=1
	ShowTools/A
	Button display,pos={128,3},size={70,20},proc=DisplayHyperSpec,title="Display Data"
	Button display,fSize=11
	if (!datafolderexists("root:gVariables:hyperspec_imaging"))
		newdatafolder root:gVariables:hyperspec_imaging
	endif
	variable/g root:gVariables:hyperspec_imaging:wavelength = 0
	SetVariable setwlen,pos={4,5},size={122,16},bodyWidth=60,proc=SetWavelength,title="Wavelength"
	SetVariable setwlen,fSize=11
	SetVariable setwlen,limits={400,1000,1},value= root:gVariables:hyperspec_imaging:wavelength
	Slider slider0,pos={5,24},size={193,52},proc=WavelengthSlider
	Slider slider0,limits={400,1000,1},variable= root:gVariables:hyperspec_imaging:wavelength,vert= 0
EndMacro
