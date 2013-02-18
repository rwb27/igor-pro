#pragma ModuleName = data_display
#pragma version = 6.20
#pragma rtGlobals=1		// Use modern global access method.

#include "data_handling"

function display_tip_exp_data(tip_exp)
	string tip_exp								// location of tip experiment data structure
	// example: root:data:Dec_2012:day_21:tip_experiment_0
	// get waves relating to specific experiment
	wave spec_image = $(tip_exp + ":spectra2D")
	wave conductance = $(tip_exp + ":tipConductance")
	wave wavelengthImageAxis = $(tip_exp + ":wavelengthImageAxis")
	wave energyImageAxis = $(tip_exp + ":energyImageAxis")
	wave steps = $(tip_exp + ":PZdisplacement")
	wave steps_ax = $(tip_exp + ":PZdisplacement_ax")
	wave force_y = $(tip_exp + ":yPSD")
	wave force_x = $(tip_exp + ":xPSD")
	
	// display spectra image
	dowindow/k tip_experiment
	display/n=tip_experiment
	appendimage spec_image vs {steps_ax, energyImageAxis}
	modifyimage '' ctab= {*,*,geo,0}, ctabAutoscale=1
	label left "energy (\\U)"; label bottom "step (\\U)"
	setaxis left 1.2, 2.7
	
	// append extra relevant data
	if (waveexists(conductance))
		appendtograph/l=G conductance vs steps
		modifygraph log(G)=1, rgb=(0,0,0)
		setaxis/a=2 G
		label G "conductance (\\U)"
	endif
	if (waveexists(force_y))
		appendtograph/l=Fy force_y vs steps
		appendtograph/r=Fx force_x vs steps
		modifygraph rgb(''#1)=(65280,0,0), rgb(''#2)=(0,0,65280)
		modifygraph mode(''#1)=3,marker(''#1)=19,msize(''#1)=1.2, usemrkstrokergb(''#1)=1
		modifygraph mode(''#2)=3,marker(''#2)=19,msize(''#2)=1.2, usemrkstrokergb(''#2)=1
		setaxis/a=2 Fy; setaxis/a=2 Fx
		label Fy "axial force (\\U)"; label Fx "torsional force (\\U)"
	endif
	if (waveexists(spec2d_fit))					// append fit information
	endif
	
	modifygraph axisEnab(left)={0.26,0.74}, axisEnab(G)={0,0.24}, axisEnab(Fy)={0.76,1}, axisEnab(Fx)={0.76,1}
	modifygraph lblPosMode=1, freePos=0
	modifygraph mirror=3,minor=1,fSize=11,btLen=4,stLen=2, tickUnit=1
	modifygraph mirror(Fx)=1, mirror(Fy)=1
end