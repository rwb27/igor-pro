#pragma modulename = im_analysis
#pragma rtGlobals=1		// Use modern global access method.

static strconstant gv_folder = "root:global_variables:image_analysis"

function display_for_analysis(image)
	wave image
	dowindow/k im_an
	display/n=im_an
	appendimage image
	Modifyimage '' ctab= {*,*,Geo,0}, ctabAutoscale=1
	
	cursor/a=1/c=(65000,65000,65000)/h=0/i/p/s=2 A, '', dimsize(image, 0)/2, dimsize(image, 1)/2
	setwindow im_an, hook(csrA)=analysis_cursor
	
	wave spec = $("root:pixis_data" + ":spec")
	if (!waveexists(spec))
		make/o/n=(dimsize(image, 0)) $("root:pixis_data" + ":spec")
	endif
	
	appendtograph/l=l2 spec
	setaxis/a=2 l2
	modifygraph axisEnab(l2) = {0, 0.3}, axisEnab(left)={0.3, 1}, freepos(l2) = 0
	modifygraph width = 300, height = {aspect, 1}
end

function analysis_cursor(s)
	struct wmwinhookstruct &s
	string image_loc = "root:pixis_data"
	wave image = $(image_loc + ":image")
	switch (s.eventcode)
		case 7:
			wave spec = $(image_loc + ":spec")
			if (!waveexists(spec))
				make/o/n=(dimsize(image, 0)) $(image_loc + ":spec")
			endif
			spec = image[p][qcsr(A)]
			doupdate
			break
	endswitch
	return 0
end