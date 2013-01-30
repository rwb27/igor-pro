#pragma rtGlobals=1		// Use modern global access method.

Function/S ParseDate()
	String day, month, year
	day=date()[0,1], month=date()[3,5], year=date()[7,10]
	strswitch(month)
		case "Jan":
			month="01"
			break
		case "Feb":
			month="02"
			break
		case "Mar":
			month="03"
			break
		case "Apr":
			month="04"
			break
		case "May":
			month="05"
			break
		case "Jun":
			month="06"
			break
		case "Jul":
			month="07"
			break
		case "Aug":
			month="08"
			break
		case "Sep":
			month="09"
			break
		case "Oct":
			month="10"
			break
		case "Nov":
			month="11"
			break
		case "Dec":
			month="12"
			break
	endswitch
	String DateStr=day+"/"+month+"/"+year[2,3]
	return DateStr
End

Function CheckFolder(dirpath)
	String dirpath
	If (!DataFolderExists(dirpath))
		NewDataFolder $dirpath
	EndIf
End