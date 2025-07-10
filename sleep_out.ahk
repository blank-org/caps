SleepOut() {
	SetCapsLockState, off
	DllCall("PowrProf\SetSuspendState", "Int", 0, "Int", 1, "Int", 0)
}
