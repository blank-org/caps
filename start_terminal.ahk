StartTerminal() {
	v := Explorer_GetSelection()
	if (v)
		Run wt.exe -d "%v%"
	else
		Run wt.exe
}
