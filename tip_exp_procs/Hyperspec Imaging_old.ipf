#pragma rtGlobals=1		// Use modern global access method.
#include "PI733_3CDStage_1"

function hyperspec_alignment(angle1, angle2)
	variable angle1, angle2
	hyperspecscan(1, 0.05)
	wave wr = root:NPgridScan:w_coef_633, wb = root:NPgridScan:w_coef_500
	if (!waveexists(hyperspec_alignment))
		make/o/n=(0,10) hyperspec_alignment_data
	endif
	wave w = hyperspec_alignment_data
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

function HyperSpecScan(gridSize,stepSize)
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
	
	if (datafolderexists("root:NPgridScan"))
		setdatafolder root:NPgridScan			// Folder to store data
	else
		newdatafolder/s root:NPgridScan
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
	
	dowindow/k NPgridScan
	display/n=NPgridScan
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
	
	variable q1, q2, q3  // Loop counters
	do		
		do
			OO_read()								// Measure spectrum
			wave w=root:OO:Data:Current:Spectra		// Declare spectrum wave
			scatterData[q1][q2][] = w[r]
			
			//do							// Copy spectral values to scatterData wave
			//	scatterData[q1][q2][q3] = w[q3]		
			//	q3=q3+1
			//while(q3<numpnts(lambda))
			//q3 = 0						
			doUpdate					
			posA += stepSize		// Increment grid position
			
			//if (q1 >= (gridSize/stepSize))		// Check for end of grid
			//	break
			//endif
			movePI("A", posA); sleep/s delay		
			q1 += 1
		while(q1 <= (gridSize/stepSize))	// Exit via break
		
		posA = initA - gridSize/2		// Reset A position
		q1 = 0						// Reset A counter
		
		posB += stepSize		// Increment grid position
		//if (q2 >= (gridSize/stepSize))		// Check for end of grid
		//	break
		//endif
		
		movePI("B", posB); sleep/s delay
		q2 += 1					// Reset B counter
	while(q2 <= (gridSize/stepSize))		// Exit via break
	
	// Move back to initial position
	movePI("A", initA); sleep/s delay
	movePI("B", initB); sleep/s delay
	setDataFolder root:				// Return to root directory
	fit_hyperspec("root:NPgridScan:scatterData", wl1)
	fit_hyperspec("root:NPgridScan:scatterData", wl2)
end

function fit_hyperspec(wName, wlen)
	string wName
	variable wlen
	wave w = $wName, lambda = root:NPGridScan:lambda
	variable z0, a0, x0, sigx, y0, sigy, corr
	variable i = 0
	do
		i += 1
	while (lambda[i] < wlen)
	if ( abs(lambda[i] - wlen) > abs(wlen - lambda[i-1]))
		i -= 1
	endif
	wlen = i
		
	// Amplitude: Difference between z0 and the grid centre value
	imagestats/m=1/p=(wlen) w
	z0 = V_min
	a0 = V_max - z0
	// Centre-points: The location of the maximum grid value
	x0 = V_maxRowLoc
	y0 = V_maxColLoc
	// Peak width: Set to 250 nm, a typical starting point
	sigx = 0.25
	sigy = 0.25
	// xy correlation: Set to 0
	corr = 0
	
	make/d/n=7/o $("w_coef_"+num2str(wlen))
	wave w_coef = $("w_coef_"+num2str(wlen))
	w_coef[0] = {z0,a0,x0,y0,sigx,sigy,corr}
	FuncFitMD/NTHR=0/Q Gauss2Delliptic w_coef  w /D//C=constraintWave
end

Function DisplayHyperSpec(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			string dataloc = "root:NPgridScan"
			nvar wlen = root:gVariables:HyperSpec:wavelength
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
			dowindow/k HyperSpec
			//display/n=HyperSpec
			//appendimage/w=HyperSpec $(dataloc+":scatterData")
			newimage/f/n=HyperSpec $(dataloc+":scatterData")
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
			dowindow HyperSpec
			if (V_flag == 1)
				string dataloc = "root:NPgridScan"
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
				dowindow HyperSpec
				if (V_flag == 1)
					string dataloc = "root:NPgridScan"
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
	NewPanel /W=(790,75,994,152) as "HyperSpec"
	ModifyPanel frameStyle=1
	ShowTools/A
	Button display,pos={128,3},size={70,20},proc=DisplayHyperSpec,title="Display Data"
	Button display,fSize=11
	if (!datafolderexists("root:gVariables:HyperSpec"))
		newdatafolder root:gVariables:HyperSpec
	endif
	variable/g root:gVariables:HyperSpec:wavelength = 0
	SetVariable setwlen,pos={4,5},size={122,16},bodyWidth=60,proc=SetWavelength,title="Wavelength"
	SetVariable setwlen,fSize=11
	SetVariable setwlen,limits={400,1000,1},value= root:gVariables:HyperSpec:wavelength
	Slider slider0,pos={5,24},size={193,52},proc=WavelengthSlider
	Slider slider0,limits={400,1000,1},variable= root:gVariables:HyperSpec:wavelength,vert= 0
EndMacro
