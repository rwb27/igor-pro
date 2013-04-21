#pragma rtGlobals=1		// Use modern global access method.


//========Program to control Fianium Laser, Track and Plot values of the different variables=============
//=========Control of SC10 Shutter===============
//============Run function mypanel() to load control panel and initialize devices==============================

Function Fianium_select()
VDTOperationsPort2 COM27
End

Function Fianium_Initialization()  //Initialize communication with device
// COM5 Lab 3, COM9 Lab 2, COM4 on NP-Carbon Lab 2, COM3 on NP-Magnesium Primary Fianium (COM7 secondary Fianium), 8 for Chris Fianium, 9 for spare fianium
	VDT2/P=COM27 baud=19200, stopbits=1, databits=8, in=2, out=2
	Fianium_select()
	VDTOpenPort2 COM27
	Variable/G F_interval
	Execute "Variable/G totalpower, oldpower, brpv, preampval,pumacur, DAClevel,pumac,LASERcontrolVal"
	Execute "String/G getalarm, resetalarms, Fcmd"
	print "Initialization Completed"
End

//==========Fianium Commands==============

Macro Fianium_Test()		//Get version firmware info
	Fianium_Write("V?")
	Print Fianium_readout()
EndMacro

Function/S Fianium_GetAlarm()	//Get Alarm codes, if any present
	String/G getalarm
	SVAR getalarm
	Fianium_Write("A?")
	return(getalarm)
End

Function/S Fianium_ResetAlarms()		//Reset Alarms
	String/G resetalarms
	SVAR resetalarms
	Fianium_Write("A=0")
	return(resetalarms)
End

Function Fianium_SetDACValue()	//Set DAC current value
	NVAR totalpower
	String tpower=num2istr(totalpower)
	Fianium_Write("Q="+tpower)
End

Function Fianium_GetBackReflectionValue()		//Diode Back reflection current value
	Variable/G brpv
	NVAR brpv
	Fianium_Write("B?")
	sscanf Fianium_readout(), "\nBack reflection photodiode = %f", brpv
	return(brpv)
End	

Function Fianium_GetBackReflectionLevel()		//Diode Back reflection current value
	Variable/G brpl
	NVAR brpl
	Fianium_Write("L?")
	sscanf Fianium_readout(), "\nBack reflection photodiode level = %f", brpl
	return(brpl)
End	

Function Fianium_GetPreAmpValue()		//PreAmplifier Value
	Variable/G preampval
	NVAR preampval
	Fianium_Write("P?")
	sscanf Fianium_readout(), "\nPreamplifier photodiode = %f", preampval
	return(preampval)
End

Function Fianium_GetPumaCurrent()		//Puma current value
	Variable/G pumacur
	NVAR pumacur
	Fianium_Write("Q?")
	sscanf Fianium_readout(), "\nPuma current = %f", pumacur
	Return(pumacur)
End

Function Fianium_GetDACLevel()		//Get DAC current value
	Variable/G DACLevel, pumac
	NVAR DACLevel, pumac
	Fianium_Write("Q?")
	sscanf Fianium_readout(), "\n  Puma current = %f\rDAC Level = %f", pumac, DACLevel
	//print V_Flag
	Return(DACLevel)
End

Function Fianium_FwdCnt()   // Gets the Forward Count setting	
	Fianium_Write("D?")
	Print Fianium_readout()
End

Function Fianium_BkRfSP()  // Gets the Back Reflection Set Point
	Fianium_Write("L?")
	Print Fianium_readout()
End

Function Fianium_PhotoDMonitor()
	Fianium_Write("x=0")
	Print Fianium_readout()
End

Function Fianium_PowerFailureLvl()
	Fianium_Write("C?")
	Print Fianium_readout()
End

//==========Fianium Initialization, Read and Write Commands===========


Function Fianium_pendingread() //Reading the amount of data in the buffer
	VDTGetStatus2 0,0,0
	return(V_VDT)	//Returning variable that stores the amount of data in the buffer
End

Function Fianium_Write(ss)		// write to Fianium
	String ss
	Fianium_select()
	if (Fianium_pendingread()>0)
  		print Fianium_readout()
	endif
	VDTWrite2/O=3  ss + "\r"
	Sleep/Q/T 10
End

Function/S Fianium_readout()		//read from Fianium
	String Srd="",Sbit
	do
		if (Fianium_pendingread()==0)
    			break
  		endif
		vdtread2/T="\r" /Q /O=3 sbit
		if(char2num(sbit[0])==67 && char2num(sbit[1])==111 && char2num(sbit[2])==109 && char2num(sbit[3])==109 && char2num(sbit[4])==97 && char2num(sbit[5])==110 && char2num(sbit[6])==100 && char2num(sbit[7])==62)
			Srd+=""
		else
			Srd+=("\r"+Sbit)
		endif
	while (1)
return(Srd)
end

//=================Control Panel=======================

Window Fianium() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(28,65,474,287) as "Fianium"
	SetDrawLayer UserBack
	DrawRect 5,4,146,102
	DrawText 21,24,"LASER Control Mode"
	DrawRect 158,4,438,68
	DrawRect 6,105,185,177
	DrawText 71,126,"Tracking"
	DrawRect 199,74,386,212
	DrawText 256,96,"y-Axis vs Time"
	SetVariable setpower,pos={174,15},size={260,18},title="Amplifier Current Control DAC Value"
	SetVariable setpower,font="Arial",limits={0,2700,1},value= totalpower,live= 1
	SetVariable F_interval,pos={17,127},size={160,18},title="Time Interval (mins)"
	SetVariable F_interval,font="Arial",limits={1,3600,1},value= F_interval,live= 1
	Button bsetpower,pos={335,42},size={90,20},proc=pwrset,title="Set"
	Button bStart,pos={20,149},size={100,20},proc=StartStopButton,title="Start Tracking"
	Button binit,pos={27,78},size={90,20},proc=initialize,title="Initialization"
	Button bgraph,pos={269,185},size={50,20},proc=graph,title="Plot"
	CheckBox LASERControlCheck0,pos={52,33},size={58,15},proc=SetLASERControlMode,title="Manual"
	CheckBox LASERControlCheck0,value= 0,mode=1
	CheckBox LASERControlCheck1,pos={52,54},size={43,15},proc=SetLASERControlMode,title="USB"
	CheckBox LASERControlCheck1,value= 1,mode=1
	CheckBox ycheck0,pos={208,98},size={169,15},proc=MyCheckyaxis,title="Back Reflection Photodiode"
	CheckBox ycheck0,value= 1,mode=1
	CheckBox ycheck1,pos={208,118},size={151,15},proc=MyCheckyaxis,title="Preamplifier Photodiode"
	CheckBox ycheck1,value= 0,mode=1
	CheckBox ycheck2,pos={208,138},size={137,15},proc=MyCheckyaxis,title="Amplifier Control DAC"
	CheckBox ycheck2,value= 0,mode=1
	CheckBox ycheck3,pos={208,158},size={95,15},proc=MyCheckyaxis,title="Puma Current"
	CheckBox ycheck3,value= 0,mode=1
	CustomControl cc2,pos={10,183},size={98,27},proc=noproc
	CustomControl cc2,picture= {ProcGlobal#LOGO,1}
EndMacro
	

Function initialize(binit) : ButtonControl
	String binit
	Fianium_Initialization()
	Execute"trackstart(5)"
End


Function SetVarProcOne(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	Svar Fcmd
	Fianium_Write(Fcmd)
	Print Fianium_readout()
End



Function Pwrset(bsetpower) : ButtonControl
	String bsetpower
	//FiSetDACValue()
	ChangePwr()
End



Function MyCheckyaxis(name,value)	//Determine which has been chosen for ploting in the y-axis
	String name
	Variable value
	NVAR yrVal= root:yrVal
	Wave Ftime, FBckRefl, FPreAmpDiode, FAmpDAC, FPumaCur
	SVAR ytype
	strswitch (name)
		case "ycheck0":
			yrVal= 1
			ytype="FBckRefl"
			break
		case "ycheck1":
			yrVal= 2
			ytype="FPreAmpDiode"
			break
		case "ycheck2":
			yrVal= 3
			ytype="FAmpDAC"
			break
		case "ycheck3":
			yrVal= 4
			ytype="FPumaCur"
			break
	endswitch
	CheckBox ycheck0,value= yrVal==1
	CheckBox ycheck1,value= yrVal==2
	CheckBox ycheck2,value= yrVal==3
	CheckBox ycheck3,value= yrVal==4
End


//Function graph(bgraph) : ButtonControl
	String bgraph
	mgraph()
End


Function mgraph()	//Create graphs of values being tracked
	WAVE Ftime, FBckRefl, FPreAmpDiode, FAmpDAC, FPumaCur
	SVAR ytype
	Nvar yrval
	Display $ytype vs Ftime
	Label bottom "Time"
	//SetAxis/N=1 bottom 0,*
	//ModifyGraph manTick(bottom)={0,30,0,0,sec},manMinor(bottom)={0,50}
	//ModifyGraph dateInfo(bottom)={0,2,0}
	ModifyGraph mode=2,lsize=2.5
		
	switch(yrval)	// numeric switch that determines the labeling of y-axis in the graphs
		case 1:		// execute if case matches expression
			Label left "Back Reflection Photodiode"
			break						// exit from switch
		case 2:		// execute if case matches expression
			Label left "Preamplifier Photodiode"
			break						// exit from switch
		case 3:		// execute if case matches expression
			Label left "Amplifier Control DAC"
			break						// exit from switch
		case 4:		// execute if case matches expression
			Label left "Puma Current"
			break						// exit from switch
	endswitch
End


Function ChangePwr()		//Change the power
	NVAR OldPower,totalpower
	if(totalpower>oldpower)
		PowerIncrease()
		oldpower=totalpower					// execute if condition is TRUE
	elseif(totalpower<oldpower)
		PowerDecrease()
		oldpower=totalpower					// execute if condition is FALSE
	endif
End


Function PowerIncrease()		//Function for power Increase
	Nvar totalpower, oldpower
	Variable csrt1
	do
		NVAR totalpower
		Fianium_Write("Q="+num2str(oldpower))
		Sleep /T 18
		oldpower+=100
		csrt1=ABS(totalpower-oldpower)								// execute the loop body
	while (csrt1>=100)
	Fianium_Write("Q="+num2str(totalpower))				// as long as expression is TRUE
End


Function PowerDecrease()		//Power Decrease
	Nvar totalpower, oldpower
	Variable csrt1
	do
		Fianium_Write("Q="+num2str(oldpower))
		Sleep /T 18
		oldpower-=100
		csrt1=ABS(totalpower-oldpower)								// execute the loop body
	while (csrt1>=100)				// as long as expression is TRUE
	Fianium_Write("Q="+num2str(totalpower))
End



Function SetLASERControlMode(name,value)	//Set Fianyum Control mode as USB or controlled from the potensiometer
	String name
	Variable value
	NVAR LASERcontrolVal= root:LASERcontrolVal
	strswitch (name)
		case "LASERControlCheck0":
			LASERcontrolVal= 1
			Fianium_Write("M=0")
			break
		case "LASERControlCheck1":
			LASERcontrolVal= 2
			Fianium_Write("M=1")
			break
	endswitch
	CheckBox LASERControlCheck0,value= LASERcontrolVal==1
	CheckBox LASERControlCheck1,value= LASERcontrolVal==2
End




//===================tracking commands=================
Function track()
	PauseUpdate
	Variable vv = numpnts(FPumaCur)
	Wave Ftime,FBckRefl,FPreAmpDiode,FAmpDAC,FPumaCur
	Nvar Finittime,FSetPower; Svar Ffn
	Insertpoints vv,1,Ftime,FBckRefl,FPreAmpDiode,FAmpDAC,FPumaCur
	Ftime[vv] = DateTime
	FBckRefl[vv] = Fianium_GetBackReflectionValue()
	FPreAmpDiode[vv] = Fianium_GetPreAmpValue()
	FAmpDAC[vv] = Fianium_GetDACLevel()
	FPumaCur[vv] = Fianium_GetPumaCurrent()
	Save/O/G/P=bpath Ftime,FBckRefl,FPreAmpDiode,FAmpDAC,FPumaCur as Ffn
	return 0
End


Macro trackstart(interval)
	Variable interval	// time in mins between readings
	Make/O/N=1 Ftime,FBckRefl,FPreAmpDiode,FAmpDAC,FPumaCur
	SetScale/P x 0,1,"dat", Ftime; SetScale d 0,0,"dat", Ftime
	Ftime[0] = DateTime
	FBckRefl[0] = Fianium_GetBackReflectionValue()
	FPreAmpDiode[0] = Fianium_GetPreAmpValue()
	FAmpDAC[0] = Fianium_GetDACLevel()
	FPumaCur[0] = Fianium_GetPumaCurrent()
	Variable/G Finittime = DateTime
	String Fdate, Fsecs
	String/G Ffn
	Fdate = Secs2Date(Finittime,2)
	Fsecs= Secs2Time(Finittime,1)
	Fdate = replacestring(" ",Fdate,"_")
	Fsecs = replacestring(":",Fsecs,"_")
	//Print Fdate,Fsecs
	Ffn=Fdate+"."+Fsecs+".dat"
	NewPath/Q/O/C bpath, "C:Documents and Settings:hera:My Documents:0-common:Computer Control:Lab1_diagnostics"
	SetBackground track()
	CtrlBackground period=(60*60*interval), start
EndMacro

Function trackstop()
	KillBackground
End


//============Display Logo=================


// PNG: width= 98, height= 27
Picture LOGO
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!".!!!!<#Qau+!!ql7:]LIq&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U#NA<C5u^s?m9"-tP\1b\jutIS1Z3G2mAa/Jb]G:lE?V`QQ!II$#)\-Jkp@#P$4$YcW*SEoj$F#dd
	Q_soboiFWZ)ls=$A+/[Xq`=[6kE;`"C2gK`K#J5_7>&:n_G:jIf2;DXi5G9]$E%DF3]-Ho0)9\3JWs
	aG.S&(#Qp,(0)H-@:AiU,#a%Y'6D4qj0-Wpd7gSnim/[,E+H31:31'dQXoOhJ:]9-sg;-)0M%a5pQ!
	->QW+c0'$?0`&.SXfis0L&J!EcIaSf[26?i8+3oW_StPM*VEh3S`3e3I!%GY`X1=4b-)mBL/L_'%FB
	Fl@g"Xso)Ig7,CR1nT6n_+,S!;^eG@EoFkXJ3Y5bYupl"qkr-r#R5nsMoB/1"G=P4H])'%i%,"W]r%
	[hpAj&p6[A("iP0cg#9YWO%`%;lBM(mS80i4:SRSl!8&o$l(hV'`\RNO8+713SG.Tm`,mD*Zpiq16r
	$8sEXeoee,*rjY!<D3ABN_m%ca/Pfj$0E'r\e7r@j_qCa^j,0@Df'CV^CFL"9O->UX<a3)M(.-H#M(
	Xh=6%2<qpqo^BU%F:PF@<>]3pcc+T1m1%;rf?,C?a!gnA\\WG"r[r1#J;;S%qo^0ArMhb[F3e)lS:P
	A-T'=6!?Y6=ip#W%5_6AS_pp38]C],a.19T34/&,/(>1.)";X4=:jCi%>_Fou\C*$Z[Q;Q3Wh:cu^g
	@U`eu@2Ph=.?R.FRLqkU7n3TY<%<&2NK9.trVgIo=[-B#3&G7n$MrXCh$[_Jd.kniNLsPtUd@S,[0O
	\j0`L<ZA(D`*#U-Pde7uDAC/%K"V`lsVNQG^O3#l1Y77BZ39D@o4J+rA:.SiZ/il4nn:dF-SG3ram2
	)R8CY@$I=bKJ'2d*g?_i4oBEXLc!S]=XONfPEI>:ad"bD)N=VjM?HR-Bh#t;K7\!D]Ki=>ISK]<GJq
	qA28Em*nK8gckIE<4*U*t!-5W?XeXb0?@%K;R.Bfg!$[Or/sk&DYL.#3;sEQ2&rD;(:bJ*<?bbI\o@
	;FC!oWTnXM_up`2ctCL<r>X2#!j4eu];_!gG$_5TgUD-r&mNT;MnCR+Bl\4aR6]JD]hIlh+6-gtZ.:
	=@d(%AnL05V?qcP.dcH`n9VcSY;\C!(VlP$EsNr,_o#*C&qElZm-<m,HG(qtC['9D!93&!S"#lbL8h
	2Q!`2ou7ZXmjOg_\V.Oco"Up$`#YNO=:@*=ife>BLUOWNlUm,V3rkic].I6BG?/hX$@B?m%+oD&A=?
	+SP:ejc4>\$p^t?A;km"pXYio*Yp6T9#kUTDp^;VVbqaQ).'O<-$<.G'3pX9hcpecp"I1X$cf'g9_/
	O<E0bWK[rme70OjQiGd.>U/r-^p?gT>@.ig8>ah+MR^b8TWN"i5&OP'M=TcHI0LYh:L1+h3C1q&(RQ
	>KMaLQBTK#&RFo8IZ8PR2R#baeF.cu/TDIeM&O^;E,I6@:s=,(V*.EDAK$(l%0,`1G$0dIkB<EcL1^
	NsB*_#OVK9"?f1:KL7:+n(bI[Za7!3Tjc!%*Ho'.Unf7t4.DNi7J-6cGQ]FK_Mn6H$B_rNb[7AWs4o
	4+4?W:C$D:$GT?l\Krs"Ao'HT:YKRQ%#@4WUCpKRut\?E+)iPUGmaiW#0:Br#/bNY+fXK9'Yn(u3P.
	ut]42Ijac[;4A@,pb^LRf)&mjGEX3#f(XKrXV94HcGWR;Q5s8?Z*4':7O;[$3pe@04);YR$a8)PJ[a
	l"dh\%.4H\H?n`F"Q-Eo&H1Ib1.ck:;LEd?9!'#H*38IXaMMd9H1GcYT]DML&2f@Da1`E>uX]D?rV,
	^Ps!Z2dmTiM-"C'$X%O*j;in]Y\iE;,A%jSt4^q$@[p`V.R)^Y^cad5_pN$AG4a\@ArSFk*Kl:8]m"
	/M.M>jQG^`\T=[ATRbiA!8P>=s4Xkr#mgp7V56\C*o48AS(HuNb/sc^>$BY9h49[jZ"1t>kN0eDE9u
	Dm\$<3cCc:VPHHQ6?ZY013qXf+4il-g/?bUpWi'@>V',/QT/H[[`1fRad%7$uEb%*9cWI%PSN'/lgc
	1ki5__5riSF;%!f(*u6]WnEsRc<A^o@n/3eIOnhOY@3]Si*"^!-C7B.li"PE(KWSg"AQ]O)!pTUWC^
	)-%rY6[YEEf=Kl1LClEL-bHR\6JK(pjVZU<bRgC7uj5]bS>mN?,hAjgKCMPF`Gl%'sE:*AdgKDkKW$
	_$C)2.p+5Q6FSU$D%E&#<CJ]aq^rSf@7VG/V$65O85&0Ait`C?+=5\?/7JPNd0M)Djlc=kTN<Me[$C
	H[C)C!eJI(RQl;980jq`o()?%=0;r?$ilsTAkl+Hc'pX&*BM^,h@?3]XtCqDK=fg_Sip;Udj67bE20
	7JV"kf4"Ned-GVVYOlKUu68h);?L51NbA7oPAQ'H'k=uJ<69hjDs2D6_%p[6l(A(8-[)]:6101WC9Q
	H/stk>/#H<C#U\*d%/`'*LRJ0As.u-\08p4YU!n]ji]UPc9V_1so2&nD33AX,Y1W`MU<Q5cBPPc\[Q
	nn>[Z&Um!B0`@^n>1eAj^.=9/;9hkO)),_R^?q3kJz8OZBBY!QNJ
	ASCII85End
End


Function StartStopButton(ctrlName) : ButtonControl
	String ctrlName
	Nvar F_interval
	if( cmpstr(ctrlName,"bStart") == 0 )
		Button $ctrlName,title="Stop Tracking",rename=bStop
		Execute "trackstart(F_interval)"
	else
		Button $ctrlName,title="Start Tracking",rename=bStart
		trackstop() // or whatever you want when stop is pressed
	endif
End
