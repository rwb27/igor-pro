#pragma rtGlobals=1		// Use modern global access method.

// GUI for Infinity Camera v3.0, 05/10/2012
// written by PC, XOP written by AH

// Image and parameters are stored in Igor in "root:Infinity:InfImg"
// The "Save Image" button will save the content of the folder "root:Infinity" to the folder "root:Scan#"
// Images are now 16bit, can be stored as B/W and rotated
// Resolution options are the same ones as in the Infinity Capture program
// With "Top" and "Left" one can move around the image if the resolution is smaller than 1392x1040px

Menu "Infinity"
	"Open",/Q, Infinity_Init()
	"Close",/Q, Infinity_Close()
End

Function Infinity_Init()
	Infinity_Connect
	newdatafolder/o/s root:Infinity
	Variable/G gain = Infinity_Gain()
	Variable/G exposure = Infinity_Exposure()
	Variable/G left = Infinity_TargetLeft()
	Variable/G top = Infinity_TargetTop()
	Variable/G width = Infinity_TargetWidth()
	Variable/G height = Infinity_TargetHeight()
	Variable/G maxWidth = Infinity_MaxWidth()
	Variable/G maxHeight = Infinity_MaxHeight()
	Variable/G Livemode = 0
	Variable/G ImgBW = 0
	Variable/G Imgrotate = 0
	Variable/G ImgBin = 0
	Variable/G NextSave = 0
	String/G type =  Infinity_Model()
	String/G InfinityDesc = ""
	setdatafolder root:
	execute "InfinityPanel()"
End

Function Infinity_Close()
	Infinity_Disconnect
	KillWindow InfinityPanel
End

Function Infinity_Image()
	Infinity_capture image = root:Infinity:InfImg
	AbortOnRTE								// Avoid Igor Crash
	wave image = root:Infinity:InfImg
	nvar ImgBW = root:Infinity:ImgBW
	nvar ImgRotate = root:Infinity:ImgRotate
	nvar ImgBin = root:Infinity:ImgBin
	if (ImgBW)								// Black and White image
		make/o/n=(dimsize(image,0),dimsize(image,1)) imageBW
		matrixop/o/free imageBW = sumbeams(image)/3
		redimension/u/w imageBW
		duplicate/o imageBW, image
	endif
	switch (ImgRotate)						// Rotate image
		case 90:
			imagerotate/o/c image
			break
		case 180:
			imagerotate/o/f image
			break
		case 270:
			imagerotate/o/w image
			break
	endswitch
	if (ImgBin!=0)								// Pixel Binning
		duplicate/o/free image, tempw
		ImageInterpolate/PXSZ={ImgBin,ImgBin}/dest=image pixelate tempw
	endif
	duplicate/o image, root:InfImg
	return 0
End

Function Infinity_LiveView()
	Nvar Livemode = root:Infinity:LiveMode
	if (Livemode==0)
	   Button bLiveView title="Stop", fColor=(65535,0,0)
	   Livemode = 1
	   SetBackground Infinity_image()
	   CtrlBackground period=30, start		// poll every 0.5s
	 else
	   Button bLiveView title="LiveView", fColor=(0,0,0)
	   Livemode = 0
	   KillBackground
	 endif
End

Function Infinity_Save()
	nvar nr = root:Infinity:NextSave
	string str = "root:scan"+num2str(nr)
	DuplicateDataFolder root:Infinity, $str
	KillVariables/z $(str+":NextSave")
	nr += 1
End

// ======================= GUI ======================================

Function ButtonProcInf(ctrlName) : ButtonControl
	String ctrlName
	strswitch(ctrlName)
		case "bTakeSnapshot":
			Infinity_Image()
			break
		case "bLiveView":
			Infinity_LiveView()
			break
		case "bSaveImg":
			Infinity_Save()
			break
	endswitch
End

Function PopMenuProcInf(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName, popStr
	Variable popNum
	nvar W = root:Infinity:width
	nvar H = root:Infinity:height
	nvar L = root:Infinity:left
	nvar T = root:Infinity:top
	nvar ImgBin = root:Infinity:ImgBin
	ImgBin = 0
	switch (popnum)
		case 1:
			W=320; H=240
		break
		case 2:
			//W=348; H=256
			W=1392; H=1040
			ImgBin=4
		break
		case 3:
			W=640; H=480
		break
		case 4:
			//W=696; H=520
			W=1392; H=1040
			ImgBin=2
		break
		case 5:
			W=800; H=640
		break
		case 6:
			W=1024; H=768
		break
		case 7:
			W=1280; H=1024
		break
		case 8:
			W=1392; H=1040
		break
	endswitch
	L=round((1392-W)/2); T=round((1040-H)/2)
	Camera_Set("",0,"","")
End

Function Camera_Set(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName, varStr, varName
	Variable varNum 
	nvar exposure = root:Infinity:exposure
	nvar gain = root:Infinity:gain
	nvar L = root:Infinity:left
	nvar T = root:Infinity:top
	nvar W = root:Infinity:width
	nvar H = root:Infinity:height
	Infinity_Set exposure=exposure, gain=gain, target={L,T,W,H}
end

Window InfinityPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(400,100,616,315) /N=Infinityv3p0
	SetDrawLayer UserBack
	DrawLine 24,146,191,146
	Button bLiveView,pos={118,12},size={90,30},proc=ButtonProcInf,title="LiveView"
	Button bLiveView,font="@Arial Unicode MS",fStyle=1
	SetVariable svGain,pos={9,50},size={90,16},proc=Camera_Set,title="Gain"
	SetVariable svGain,format="%d",limits={0,512,1},value= root:Infinity:gain
	SetVariable svExposure,pos={119,50},size={90,16},proc=Camera_Set,title="ExpT"
	SetVariable svExposure,format="%d"
	SetVariable svExposure,limits={1,60000,1},value= root:Infinity:exposure
	SetVariable svLeft,pos={9,72},size={90,16},proc=Camera_Set,title="Left"
	SetVariable svLeft,format="%d",limits={0,inf,1},value= root:Infinity:left
	SetVariable svTop,pos={119,72},size={90,16},proc=Camera_Set,title="Top"
	SetVariable svTop,format="%d",limits={0,inf,1},value= root:Infinity:top
	Button bTakeSnapshot,pos={9,12},size={90,30},proc=ButtonProcInf,title="Snapshot"
	Button bTakeSnapshot,font="@Arial Unicode MS",fStyle=1
	SetVariable setvar_Rotate,pos={9,122},size={90,16},title="Rotate",format="%d"
	SetVariable setvar_Rotate,limits={0,270,90},value= root:Infinity:Imgrotate
	CheckBox check0,pos={118,124},size={41,14},title="B/W"
	CheckBox check0,variable= root:Infinity:ImgBW
	SetVariable svGain1,pos={9,154},size={199,16},proc=Camera_Set,title="Description"
	SetVariable svGain1,limits={0,512,1},value= root:Infinity:InfinityDesc
	Button bSaveImg,pos={118,176},size={90,30},proc=ButtonProcInf,title="Save Image"
	Button bSaveImg,font="@Arial Unicode MS",fStyle=1
	SetVariable setvar_savenr,pos={9,181},size={90,16},title="ScanNR",format="%d"
	SetVariable setvar_savenr,limits={0,inf,1},value= root:Infinity:NextSave
	PopupMenu popup_Resolution,pos={9,95},size={141,21},proc=PopMenuProcInf,title="Resolution"
	PopupMenu popup_Resolution,mode=8,popvalue="1392 x 1040",value= #"\"320 x 240;348 x 256 (bin4x4);640 x 480;696 x 520 (bin2x2);800 x 600;1024 x 768;1280 x 1024;1392 x 1040\""
EndMacro
