#pragma rtGlobals=1		// Use modern global access method.

function fixdata()
	string datafolder = "root:data:Nov2012:day21:tipAlign"
	string varfolder = "root:gVariables:tipAlignment"
	
	make/o/n=(0,4) $(datafolder + ":align_data")
	wave align_data = $(datafolder + ":align_data")
	make/o/n=0 $(datafolder + ":volt_data")
	wave volt_data = $(datafolder + ":volt_data")
	make/o/n=0 $(datafolder + ":pos_data")
	wave pos_data = $(datafolder + ":pos_data")
	make/o/n=0 $(datafolder + ":x_data")
	wave x_data = $(datafolder + ":x_data")
	make/o/n=0 $(datafolder + ":y_data")
	wave y_data = $(datafolder + ":y_data")
	nvar centB = root:gVariables:tipAlignment:x0
	nvar centC = root:gVariables:tipAlignment:y0
	variable i = 1
	nvar pos0 = $(datafolder+":scan_"+num2str(i) + ":startA")
	do
		string scanfolder = datafolder+":scan_"+num2str(i)
		//plotTipAlign(scanfolder)
		setDataFolder $scanfolder								// Swicth to folder
		analyzeGridScan("tipAlignGridScan_yPSDpp")
		setDataFolder root:
		nvar  volt = $(scanfolder + ":sigGenAmplitude")
		nvar pos = $(scanfolder + ":startA")
		redimension/n=(i,4) align_data
		redimension/n=(i) pos_data
		redimension/n=(i) volt_data
		redimension/n=(i) x_data
		redimension/n=(i) y_data
		align_data[i][0] = pos - pos0
		pos_data[i] = pos - pos0
		align_data[i][1] = volt
		volt_data[i] = volt
		align_data[i][2] = centB
		x_data[i] = centB
		align_data[i][3] = centC
		y_data[i] = centC
		i += 1
	while (datafolderexists(scanfolder))
	print scanfolder
end

window HyperSpec() : panel
	// select data button
	string data = "root:NPGridScan"
	// select wavelength button
	variable wlen = 500
	// wavelength to array index conversion
	wave lambda
	variable i = 0
	do
		i++
	while (lambda[i] < wlen)
	variable iu = mod(lambda[i] - wlen), id = mod(lambda[i-1] - wlen)
	if (iu < id) i = iu
	elseif (iu > id) i = id
	endif
	// display data
	dowindow/k HyperSpec
	newpanel/n=HyperSpec/w=(0, 0, 500, 500) as "HyperSpectral Imaging"
	display scatterData
	modifyimage scatterData ctab= {*,*,ColdWarm,0}, ctabAutoscale=3,lookup= $""
	// print display button
	
function autotipalign()
	variable V, z = 0, dz = 0.05

	do
		if(GetKeyState(0) & 32)
			break
		endif
		
		V = 8
		do
			if(GetKeyState(0) & 32)
				break
			endif
			tipalign()
			V += 2
		while (V <= 36)
		moverelPI("A",dz)
		z += dz
	while (1)
	
	string folderName = "root:data:Nov2012:day27:tipAlign"
	generateTipAlignReport(folderName)
end
