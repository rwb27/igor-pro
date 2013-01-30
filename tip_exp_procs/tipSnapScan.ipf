#pragma rtGlobals=1		// Use modern global access method.

function tipscan()
	nvar grid_size
	nvar grid_step
	
	// record current positions
	nvar posA
	nvar posB
	nvar posC
	variable posA0 = posA, posB0 = posB, posC0 = posC
	
	// make counters
	variable iB = 0, iC = 0, i_max = grid_size/grid_step
	
	// load waves
	wave spectra = root:OO:current:spectra
	
	// set data location
	string dirPath
	string currDate = date()
	string day, monthYear
	day = "day"+currDate[0,1]; monthYear = currDate[3,5]+currDate[7,10]

	dirPath = "root:data:"
	if(!dataFolderExists(dirPath))
		newDataFolder $dirPath
	endif
	dirPath = "root:data:"+monthYear
	if(!dataFolderExists(dirPath))
		newDataFolder $dirPath
	endif
	dirPath = "root:data:"+monthYear+":"+day
	if(!dataFolderExists(dirPath))
		newDataFolder $dirPath
	endif	
	dirPath = "root:data:"+monthYear+":"+day+":tipScan"
	if(!dataFolderExists(dirPath))
		newDataFolder $dirPath
	endif	
	// Find unique scan number
	variable q = 1
	do
		dirPath = "root:data:"+monthYear+":"+day+":tipScan:"+"scan_"+num2str(q)
		if(!dataFolderExists(dirPath))
			newDataFolder/s $dirPath
			break
		endif		
		q += 1
	while(1)
	
	// make data waves
	make/o/n=(i_max, i_max) tipScanCurrent
	make/o/n=(i_max, i_max, numpnts(spectra)) tipScanSpectra
	
	// initialise scan
	posB = posB0 - grid_size/2
	posC = posC0 - grid_size/2
	setscale/P x, posB, grid_step, tipScanCurrent, tipScanSpectra
	setscale/P y, posC, grid_step, tipScanCurrent, tipScanSpectra
	movePI("B", posB)
	movePI("C", posC)
	sleep/s 1
	
	// plot scan
	//plotTipScan(getdatafolder(1))
	
	// scan grid
	do
		do
			// measure current
			tipScanCurrent[iB][iC] = measureCurrentSMU()
			
			// measure spectra
			OO_read()
			tipScanSpectra[iB][iC][] = spectra[r]
			
			doupdate
			
			posB = posB + grid_step
			movePI("B", posB)
			sleep/s 0.5
			iB += 1
		while (iB < i_max)
		
		posB = posB0 - grid_size/2
		posC = posC + grid_step
		movePI("B", posB)
		movePI("C", posC)
		sleep/s 0.5
		iB = 0
		iC += 1
	while (iC < i_max)
	
	movePI("B", posB0)
	movePI("C", posC0)
	setDataFolder root:
	
	// fit data
	
	// retract
end