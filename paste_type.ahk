PasteType() {
	; Use InputHook to ignore (supress) space bar and detect its press
	ih := InputHook("V")
	ih.KeyOpt("{Space}", "S") ; Ignore space bar
	ih.Start()
	Loop 25 {
		if GetKeyState("Space", "P") {
			break
		}
		Sleep 100
	}
	ih.Stop()
	SetKeyDelay 20
	Send {raw}%Clipboard%
}
