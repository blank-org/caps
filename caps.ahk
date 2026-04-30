#Requires AutoHotkey v1.1

#Include %A_ScriptDir%\build\version-info.ahk

#SingleInstance Force
#InstallKeybdHook
SetBatchLines, -1

; CapsLock layer state
; capsLocked  — double-tapped, stays on until next CapsLock press
; capsIsHeld  — key is physically down (filters spurious auto-repeat events)
; capsActive  — layer is live (held OR locked); drives #If below, faster than GetKeyState
doubleCapsLockInterval := 300
lastCapsLockTime := 0
capsLocked := 0
capsIsHeld := 0
capsActive := 0

Caps_ResetState()
OnMessage(0x218, "Caps_PowerBroadcast")

Caps_ResetState() {
    global lastCapsLockTime, capsLocked, capsIsHeld, capsActive
    lastCapsLockTime := 0
    capsLocked := 0
    capsIsHeld := 0
    capsActive := 0
    SetCapsLockState, Off
}

Caps_PowerBroadcast(wParam, lParam, msg, hwnd) {
    if (wParam = 0x6 || wParam = 0x7 || wParam = 0x12) {
        Caps_ResetState()
        SetTimer, Caps_ReloadAfterResume, -1500
    }
    return true
}

Caps_ReloadAfterResume() {
    Reload
}

; No ~ prefix: AHK owns CapsLock entirely via SetCapsLockState, no race with system toggle
*CapsLock::
    if (capsIsHeld)
        return
    capsIsHeld := 1
    if (capsLocked) {
        capsLocked := 0
        capsActive := 0
        SetCapsLockState, Off
        return
    }
    now := A_TickCount
    if (now - lastCapsLockTime < doubleCapsLockInterval)
        capsLocked := 1
    lastCapsLockTime := now
    capsActive := 1
    SetCapsLockState, On
return

*CapsLock up::
    capsIsHeld := 0
    if (capsLocked)
        return
    capsActive := 0
    SetCapsLockState, Off
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

#If capsActive

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
c::!left
v::^left
b::PasteType()
n::^right
m::!right
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
-::–
+-::—
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
