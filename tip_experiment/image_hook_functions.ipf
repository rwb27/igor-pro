#pragma moduleName = im_hook
#pragma rtGlobals=1		// Use modern global access method.

// call with cursor/i/c=(0,0,0)/h=1/p a, ''#0, dimsize(image, 0)/2, dimsize(image, 1)/2

function spectra_cursor(s)
	struct wmwinhookstruct &s
	svar image = $(gv_folder + ":image")
	wave hs_data = $(image + ":hyperspec_image")
	wave wavelength = $(image + ":wavelength")
	switch (s.eventcode)
		case 7:
			if (!waveexists)
				make/o/n=(dimsize(hs_data, 2)) $(image + ":spec")
			endif
			wave spec = $(image + ":spec")
			spec = hs_data[pcsr(A)][qcsr(A)][p]
			doupdate
			break
	endswitch
	return
end
