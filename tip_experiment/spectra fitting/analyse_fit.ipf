#pragma rtGlobals=1		// Use modern global access method.

function display_analysis()
	wave params = params
	dowindow/k data_analysis; display/n=data_analysis	
	appendtograph params[][0]
	appendtograph/l=amp params[][1]
	appendtograph/l=damp params[][2]
	modifygraph rgb(''#0)=(65280,0,0), rgb(''#1)=(65280,0,0), rgb(''#2)=(65280,0,0)
	label left "\\s(''#0) energy (eV)"; label amp "\\s(''#1) amplitude (a.u.)"; label damp "\\s(''#2) damping (eV)"
	label bottom "step"
	appendtograph/r params[][3]
	appendtograph/r=amp2 params[][4]
	appendtograph/r=damp2 params[][5]
	modifygraph rgb(''#0)=(0,65280,0), rgb(''#1)=(0,65280,0), rgb(''#2)=(0,65280,0)
	label right "\\s(''#3) energy (eV)"; label amp2 "\\s(''#4) amplitude (a.u.)"; label damp2 "\\s(''#5) damping (eV)"
	appendtograph/l=cond tipConductance
	modifygraph log(cond)=1
	label cond "\\s(''#6)conductance (G\B0\M)"
	setaxis bottom 200, 240
	setaxis/a=2 left
	setaxis/a=2 amp
	setaxis/a=2 damp
	setaxis/a=2 right
	setaxis/a=2 amp2
	setaxis/a=2 damp2
	setaxis/a=2 cond
	modifygraph freepos=0
	modifygraph axisEnab(left)={0.76, 1}, axisEnab(amp)={0.51, 0.74}, axisEnab(damp)={0.26, 0.49}
	modifygraph axisEnab(right)={0.76, 1}, axisEnab(amp2)={0.51, 0.74}, axisEnab(damp2)={0.26, 0.49}
	modifygraph axisEnab(cond)={0, 0.23}
	modifygraph mode=4, marker=19, msize=1.2, usemrkstrokergb=1
	modifygraph mirror(cond)=1, minor=1, fSize=10, btLen=4, stLen=2, lblPosMode=1
	legend/c/n=text0/j/a=lt "\\Z10\\s(''#0) mode 1\r\\s(''#3) mode 2"
end