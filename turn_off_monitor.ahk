TurnOffMonitor() {
	;screensaver ?
	;SendMessage 0x112, 0xF140, 0, , Program Manager ; Start screensaver
	
	Sleep 1000
	SendMessage 0x112, 0xF170, 2, , Program Manager ; Monitor off

	;lock workstation
	;DllCall("LockWorkStation")	
}
