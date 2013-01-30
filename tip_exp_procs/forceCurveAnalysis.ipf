#pragma rtGlobals=1	// Use modern global access method.

// Plot conductance and PSD signals one above the other

function plotConductancePSD(folderName)

	string folderName
	
	setDataFolder $folderName

	// Produces a nicely formatted current and PSD vs PZ plot
	
	wave tipConductance, tipCurrent, tipVoltage
	tipConductance = tipCurrent/tipVoltage/7.7480917e-5
	
	display tipConductance
	appendtograph/L=L2/B=B2 xPSD,yPSD
	appendtograph/L=L3/B=B3 PZdisplacement

	label bottom "PZ displacement (nm)"
	label left "Conductance (/G0)"
	label L2 "PSD (V)"
	Label L3 "PZ (um)"	
	
	ModifyGraph tick=2,mirror=1,fSize=16,standoff=0
	
	ModifyGraph log(left)=1,lblPos(left)=80,axisEnab(left)={0,0.45}
	ModifyGraph axisEnab(L2)={0.45,0.9},freePos(L2)=0
	ModifyGraph axisEnab(L3)={0.9,1},freePos(L3)=0	
	ModifyGraph tick(B2)=1,mirror(B2)=0,freePos(B2)={0.45,kwFraction}, noLabel(B2)=2,lblPos(L2)=80
	ModifyGraph tick(B3)=1,mirror(B3)=0,freePos(B3)={0.9,kwFraction}, noLabel(B3)=2,lblPos(L3)=80, nticks(L3)=2

	ModifyGraph mode=4,marker=8,msize=2,opaque=1
	ModifyGraph lsize=1.5,rgb(tipConductance)=(0,0,0),rgb(xPSD)=(0,26112,39168)
	ModifyGraph mode(PZdisplacement)=0,lsize(PZdisplacement)=1, rgb(PZdisplacement)=(0,0,0)

	SetDrawEnv ycoord= left,dash= 3;DelayUpdate
	DrawLine -0,1,1,1
	
	setDataFolder root:

end


// Analyse forceConductance scan

function analysePSDsignal(wName)
	
	// Brings up analysis panel for the wave specified by wName 
	string wName
	wave w = $wName
	
	
	newPanel/N=forceAnalysis /W=(0,0,550,550)
	
	// Add graph and format
	display/N=forceData/W=(0,0,0.9,0.9)/HOST=# w
	
	ModifyGraph margin(top)=25
	setaxis left wavemin(w), wavemax(w)
	modifyGraph mode=3,marker=19,msize=2.5,useMrkStrokeRGB=1,opaque=1,rgb=(0,26112,39168)
	modifyGraph tick=2,mirror=1,standoff=0,fSize=16

	label left "PSD signal (V)"
	label bottom "PZ displacement (nm)"
	
	string graphLabel = wName
	TextBox/C/N=text0/A=MT/X=0/Y=0/E=2 graphLabel
	
	// Add panel buttons
	button button0 title="Fit Line",pos={13,500},size={60,30},fSize=14
	button button0 proc=ButtonProc_FitLine
	
	button button1 title="Export Graph",size={100,30},pos={83,500},fSize=14
	button button1 proc=ButtonProc_ExportGraph
	
	ShowInfo

end

Function/S CursorAWave()
	// Returns the full path name of the wave attached to cursor A
	wave/Z w= CsrWaveRef(A)
	if (WaveExists(w)==0)
		return ""
	endif
	return GetWavesDataFolder(w,2)
End

Function ButtonProc_FitLine(ba) : ButtonControl
	// Fit Line button on forceAnalysis panel
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
		
			string wName = CursorAWave()
			wave w = $wName
			
			// Reset residual wave
			make/o/n=(numpnts(w)) forceResidual
			forceResidual = 0
			RemoveFromGraph/Z forceResidual
			
			// Linear fit of data between cursors
			CurveFit/Q/X=1/NTHR=0/TBOX=768 line  w [pcsr(B),pcsr(A)] /R=forceResidual/D
						
//			modifyGraph axisEnab(left)={0,0.75}
//			appendtograph/L=L2/B=B2 forceResidual
//			modifyGraph tick(L2)=2,tick(B2)=1,mirror(L2)=1,fSize=16,noLabel(B2)=2,standoff=0;DelayUpdate
//			modifyGraph axisEnab(L2)={0.75,1},freePos(L2)=0,freePos(B2)={0.75,kwFraction}
//			modifyGraph lblPos(L2)=65, lblPos(left)=65
//			label L2 "Residual"
			
//			modifyGraph mode(forceResidual)=3,marker(forceResidual)=19,msize(forceResidual)=2.5,useMrkStrokeRGB(forceResidual)=1,opaque(forceResidual)=1,rgb(forceResidual)=(65280,0,0)
//			setDrawEnv ycoord= L2,dash= 3
//			drawLine 0,0,1,0
//	
//			variable twoSigma = 2*sqrt(variance(forceResidual,pcsr(A),pcsr(B)))
//	
//			print "rms error of fit: = " + num2str(twoSigma)
//			
//			setDrawEnv ycoord= L2,linefgc= (52224,0,0),dash= 3;DelayUpdate
//			drawLine 0,twoSigma,1,twoSigma
//			
//			setDrawEnv ycoord= L2,linefgc= (52224,0,0),dash= 3;DelayUpdate
//			drawLine 0,-twoSigma,1,-twoSigma
			
			
//			setaxis bottom pcsr(A),pcsr(B)
//			setaxis B2 pcsr(A),pcsr(B)
//			setAxis left waveMin(w,pcsr(A),pcsr(B)),waveMax(w,pcsr(A),pcsr(B))
//			setAxis/A=2 L2 
	
	
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_ExportGraph(ba) : ButtonControl
	// Button to save graph as .png
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			savePICT/WIN=#forceData/E=-5/RES=300	// Export subwindow
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

