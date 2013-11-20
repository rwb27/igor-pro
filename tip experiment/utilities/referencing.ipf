#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// These folders must exist
static strconstant ref_path_lab = "C:Users:Hera:Desktop:tip_exp:raw_data"
static strconstant ref_path_laptop = "C:Users:Alan:desktop:referencing"

// This must be run first
function set_references_path(location)
	string location
	if (stringmatch(location, "lab"))
		newpath/c/o/q ref, ref_path_lab
	elseif (stringmatch(location, "laptop"))
		newpath/c/o/q ref, ref_path_laptop
	endif
end

function update_references()
	dfref current_df = getdatafolderdfr()
	setdatafolder root:references
	savedata/d/o/p=ref/r/t ":"
	setdatafolder current_df
end

function load_references()
	loaddata/d/o/p=ref/r/t "references"
end

function make_reference(df, [ref_date, power])
	dfref df	// df is an OO scan folder
	string ref_date
	variable power
	if (paramisdefault(ref_date))
		string day, month, year
		string gExp = "([0-9]+)/([0-9]+)/([0-9]+)"	
		SplitString/E=(gExp) secs2date(datetime,-1), day, month, year
		ref_date = year[2,3] + month + day
	endif
	power = paramIsDefault(power) ? 1100 : power	
	svar/sdfr=df ref_name = datadescription
	svar/sdfr=df sname = spectrometer_save
	wave/sdfr=df raw = spectraraw, bkgd = spectrabkgd, wavelength = wl_wave
	nvar/sdfr=df int = intT_save
	newdatafolder/o root:references
	newdatafolder/o root:references:axial
	newdatafolder/o root:references:axial:$sname
	dfref rdf = root:references:axial:$sname
	duplicate/o wavelength, rdf:wavelength
	make/o/n=(numpnts(wavelength)) rdf:$(ref_date+"_"+num2str(power)+"_"+num2str(int)+"ms_"+ref_name) = (raw - bkgd)
	nvar/sdfr=df ns = numspectrometers_save
	if (ns == 2)
		svar/sdfr=df sname = spectrometer_2_save
		wave/sdfr=df raw = spectraraw_2, bkgd = spectrabkgd_2, wavelength = wl_wave_2
		nvar/sdfr=df int = intT_2_save
		newdatafolder/o root:references:transverse
		newdatafolder/o root:references:transverse:$sname
		dfref rdf = root:references:transverse:$sname
		duplicate/o wavelength, rdf:wavelength
		make/o/n=(numpnts(wavelength)) rdf:$(ref_date+"_"+num2str(power)+"_"+num2str(int)+"ms_"+ref_name) = (raw - bkgd)
	endif
end

function/wave unreference(spectra, ref, bkgd)
	wave spectra, ref, bkgd
	dfref wpath = getwavesdatafolderdfr(spectra)
	string wname = nameofwave(spectra)
	duplicate/o spectra, wpath:$(wname+"_raw")
	wave spectra_raw = wpath:$(wname+"_raw")
	spectra_raw *= ref
	spectra_raw += bkgd
	return spectra_raw
end

function/wave unreference_hyperspec(spectra, ref, bkgd)
	wave spectra, ref, bkgd
	dfref wpath = getwavesdatafolderdfr(spectra)
	string wname = nameofwave(spectra)
	duplicate/o spectra, wpath:$(wname+"_raw")
	wave spectra_raw = wpath:$(wname+"_raw")
	variable i, j
	for (i=0; i<dimsize(spectra,0); i+=1)
	for (j=0; j<dimsize(spectra,1); j+=1)
		make/free/n=(dimsize(spectra,2)) temp
		temp = spectra[i][j][p]
		temp *= ref
		temp += bkgd
		spectra_raw[i][j][] = temp[r]
	endfor
	endfor
	return spectra_raw
end

function/wave rereference(spectra, ref_old, ref_new)
	wave spectra, ref_old, ref_new
	spectra *= ref_old
	spectra /= ref_new
end

function/wave reference_hyperspec(spectra_raw, ref, bkgd)
	wave spectra_raw, ref, bkgd
	dfref wpath = getwavesdatafolderdfr(spectra_raw)
	string wname = nameofwave(spectra_raw)
	duplicate/o spectra_raw, wpath:$(wname+"_refd")
	wave spectra = wpath:$(wname+"_refd")
	variable i, j
	for (i=0; i<dimsize(spectra_raw,0); i+=1)
	for (j=0; j<dimsize(spectra_raw,1); j+=1)
		make/free/n=(dimsize(spectra_raw,2)) temp
		temp = spectra_raw[i][j][p]
		temp -= bkgd
		temp /= ref
		spectra[i][j][] = temp[r]
	endfor
	endfor
	return spectra
end

function/wave rereference_hyperspec(spectra, ref_old, ref_new)
	wave spectra, ref_old, ref_new
	variable i, j
	for (i=0; i<dimsize(spectra,0); i+=1)
	for (j=0; j<dimsize(spectra,1); j+=1)
		make/free/n=(dimsize(spectra,2)) temp
		temp = spectra[i][j][p]
		temp *= ref_old
		temp /= ref_new
		spectra[i][j][] = temp[r]
	endfor
	endfor
	return spectra
end