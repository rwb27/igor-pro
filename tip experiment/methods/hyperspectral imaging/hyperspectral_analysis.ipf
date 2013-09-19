#pragma ModuleName = hyperspec_analysis
#pragma version = 6.23
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "analysis_tools"

function analyse_scan(hs_data, wavelength)
	wave hs_data
	variable wavelength
	display_scan(hs_data, wavelength)
	cursor/a=1/c=(65000,65000,65000)/h=0/i/p/s=2 A, ''#0, dimsize(hs_data, 0)/2, dimsize(hs_data, 1)/2
	setwindow hyperspectral_image, hook(csrA)=spectra_cursor
	svar image = $(gv_folder + ":image")
	wave spec = $(image + ":spec"), wl_wave = $(image + ":wavelength")
	if (!waveexists(spec))
		make/o/n=(dimsize(hs_data, 2)) $(image + ":spec")
	endif
	dowindow/k hs_spec
	display/n=hs_spec spec vs wl_wave
	setaxis/a=2 left
	setaxis bottom 450, 1000
end

function spectra_cursor(s)
	struct wmwinhookstruct &s
	svar image = $(gv_folder + ":image")
	wave hs_data = $(image + ":hyperspec_image")
	wave wavelength = $(image + ":wavelength")
	switch (s.eventcode)
		case 7:
			wave spec = $(image + ":spec")
			if (!waveexists(spec))
				make/o/n=(dimsize(hs_data, 2)) $(image + ":spec")
			endif
			spec = hs_data[pcsr(A)][qcsr(A)][p]
			doupdate
			break
	endswitch
	return 0
end

function analyse_multi_scan(hs_data1, hs_data2, wavelength)
	wave hs_data1, hs_data2
	variable wavelength
	display_multi_scan(hs_data1, hs_data2, wavelength)
	cursor/a=1/c=(65000,65000,65000)/h=0/i/p/s=0 A, ''#0, dimsize(hs_data1, 0)/2, dimsize(hs_data1, 1)/2
	cursor/a=1/c=(65000,65000,65000)/h=0/i/p/s=0 B, ''#1, dimsize(hs_data2, 0)/2, dimsize(hs_data2, 1)/2
	setwindow hyperspectral_image, hook(csrA)=multi_spectra_cursor
	svar image1 = $(gv_folder + ":image")
	wave spec1 = $(image1 + ":spec"), wl_wave = $(image1 + ":wavelength")
	if (!waveexists(spec1))
		make/o/n=(dimsize(hs_data1, 2)) $(image1 + ":spec")
	endif
	svar image2 = $(gv_folder + ":image2")
	wave spec2 = $(image2 + ":spec")
	if (!waveexists(spec2))
		make/o/n=(dimsize(hs_data2, 2)) $(image2 + ":spec")
	endif
	dowindow/k hs_spec
	display/n=hs_spec spec1 vs wl_wave
	modifygraph rgb(''#0)=(0,0,0)
	appendtograph/r spec2 vs wl_wave
	setaxis/a=2 left; setaxis/a=2 right
	setaxis bottom 450, 1000
end

function multi_spectra_cursor(s)
	struct wmwinhookstruct &s
	svar image1 = $(gv_folder + ":image")
	svar image2 = $(gv_folder + ":image2")
	wave hs_data1 = $(image1 + ":hyperspec_image")
	wave hs_data2 = $(image2 + ":hyperspec_image")
	wave wavelength = $(image1 + ":wavelength")
	switch (s.eventcode)
		case 7:
			wave spec1 = $(image1 + ":spec")
			if (!waveexists(spec1))
				make/o/n=(dimsize(hs_data1, 2)) $(image1 + ":spec")
			endif
			spec1 = hs_data1[pcsr(A)][qcsr(A)][p]
			wave spec2 = $(image2 + ":spec")
			if (!waveexists(spec2))
				make/o/n=(dimsize(hs_data2, 2)) $(image2 + ":spec")
			endif
			spec2 = hs_data2[pcsr(B)][qcsr(B)][p]
			doupdate
			break
	endswitch
	return 0
end