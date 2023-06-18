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

AppSKey::StartRun()

#If GetKeyState("Capslock","T")

q::SleepOut()
w::up
e::media_prev
r::pgdn
t::home
y::end
u::pgup
;i
o::media_next
p::volume_up
;[
;]
;\

a::left
s::down
d::right
f::media_play_Pause
g::lbutton
h::rbutton
j::left
i::up
k::down
l::right
`;::mbutton
;apostrophe

z::volume_down
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
