#SingleInstance Force

#include Switch-Windows_same-App.ahk
#include Explorer_Get-Selection.ahk

StartTerminal() {
	v := Explorer_GetSelection()
	if (v)
		Run wt.exe -d "%v%"
	else
		Run wt.exe
}

; Shortcut menu for the app ?
StartRun() {
	Send {ralt down}
	Send {space down}
	Send {space up}
	Send {ralt up}
}

SleepOut() {
	SetCapsLockState, off
	DllCall("PowrProf\SetSuspendState", "Int", 0, "Int", 1, "Int", 0)
}

TurnOffMonitor() {
	;screensaver ?
	;SendMessage 0x112, 0xF140, 0, , Program Manager ; Start screensaver
	
	Sleep 1000
	SendMessage 0x112, 0xF170, 2, , Program Manager ; Monitor off

	;lock workstation
	;DllCall("LockWorkStation")	
}

#If GetKeyState("Capslock","T")

AppSKey::StartRun()

q::TurnOffMonitor()
w::up
e::ins
r::pgdn
t::home
y::end
u::pgup
i::volume_down
o::media_play_Pause
p::volume_up
[::media_prev
]::media_next
;\

a::left
s::down
d::right
f::mbutton
g::lbutton
h::rbutton
j::left
k::down
l::right
`;::
;apostrophe

z::SleepOut()
x::browser_forward
c::+up
v::^left
b::browser_back
n::^right
m::+down
;,
;.
;/

;``
;1
;2
;3
4::Send {₹}
;5
;6
;7
;8
;9
;0
;-
;=
backspace::del

space::StartTerminal()

printScreen::7
scrollLock::8
break::9
del::1
home::5
end::2
PgUp::6
pgDn::3
ins::4
up::0
down::.
left::-
right::+

*CapsLock up::SetCapsLockState, off
