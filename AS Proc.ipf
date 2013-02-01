#pragma rtGlobals=1		// Use modern global access method.

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