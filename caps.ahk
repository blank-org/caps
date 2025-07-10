#Requires AutoHotkey v1.1

;@Ahk2Exe-SetDescription Caps - shortcuts executioner
;@Ahk2Exe-SetProductVersion 0.8
;@Ahk2Exe-SetProductName Caps - keyboard shortcuts
;@Ahk2Exe-SetFileVersion 0.8.3.0
;@Ahk2Exe-SetCopyright 2024 - Ujjwal Singh @ ujnotes.com

#SingleInstance Force

; Double-tap CapsLock detection
doubleCapsLockInterval := 300
lastCapsLockTime := 0
capsOverrideDisabled := 0

~*CapsLock::
    now := A_TickCount
    if (now - lastCapsLockTime < doubleCapsLockInterval) {
        capsOverrideDisabled := 1
        SetCapsLockState, On
        ; Optional: show a tooltip or sound to indicate override is disabled
    }
    lastCapsLockTime := now
return

*CapsLock up::
    if (capsOverrideDisabled) {
        ; If CapsLock is now off, re-enable overrides
        if (GetKeyState("CapsLock", "T") = 0) {
            capsOverrideDisabled := 0
        }
        return
    } else {
        SetCapsLockState, off
        if (GetKeyState("CapsLock", "T") = 0) {
            capsOverrideDisabled := 0
        }
    }
return

; Read config.ini to check if right_click_left is enabled
IniRead, rightClickLeft, %A_ScriptDir%\config.ini, Settings, right_click_left, 0
; normalize to integer
; message dialog with value of rightClickLeft
rightClickLeft := (rightClickLeft = "1" || rightClickLeft = "true") ? 1 : 0

#include AutoHotkey-script-Open-Show-Apps\Switch-opened-windows-of-same-App.ahk
#include Explorer_Get-Selection.ahk
#include dark_mode.ahk
#include paste_type.ahk
#include start_terminal.ahk
#include app_menu.ahk
#include sleep_out.ahk
#include turn_off_monitor.ahk
#include start_vscode.ahk


pause::volume_up
scrollLock::volume_down
printScreen::volume_mute

#If GetKeyState("Capslock","T") && !capsOverrideDisabled

AppSKey::StartRun()

q::SleepOut()
w::up
e::ins
r::pgdn
t::home
y::end
u::pgup
i::+up
o::volume_down
p::media_play_pause
[::volume_up
]::media_prev
\::media_next

a::left
s::down
d::right
f::mbutton
g::lbutton
h::rbutton
j::^+left
k::+down
l::^+right
`;::volume_mute
;apostrophe
;enter

z::TurnOffMonitor()
x::browser_back
;c::
v::^left
b::PasteType()
n::^right
;m::
,::browser_forward
.::ToggleDarkMode()
/::Start_VScode()
;rshift

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
^backspace::^del

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


#include right_to_left_click.ahk
