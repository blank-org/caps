#Requires AutoHotkey v1.1

#Include %A_ScriptDir%\build\version-info.ahk

#SingleInstance Force
#InstallKeybdHook
SetBatchLines, -1

; CapsLock layer state
; capsLocked  — double-tapped: normal caps lock (capitals), layer off until next press
; capsIsHeld  — key is physically down (filters spurious auto-repeat events)
; capsActive  — nav layer is live (held, not locked); drives #If below, faster than GetKeyState
; capsLedOn   — desired real CapsLock toggle; on only while capsLocked, so the LED
;               means capitals. Holding the layer does not touch the real toggle:
;               rapid per-tap toggle injections race the input queue and get lost.
doubleCapsLockInterval := 300
lastCapsLockTime := 0
capsLocked := 0
capsIsHeld := 0
capsActive := 0
capsLedOn := 0
capsLedTries := 0

Caps_CloseStaleInstances()
Caps_ResetState()
OnMessage(0x218, "Caps_PowerBroadcast")

; After resume, #SingleInstance Force can fail to replace an unresponsive old
; instance and copies pile up; hard-close any other process running this exe.
Caps_CloseStaleInstances() {
    if (!A_IsCompiled)
        return
    ownPid := DllCall("GetCurrentProcessId")
    SplitPath, A_ScriptFullPath, exeName
    for proc in ComObjGet("winmgmts:").ExecQuery("SELECT ProcessId, ExecutablePath FROM Win32_Process WHERE Name = '" . exeName . "'") {
        if (proc.ProcessId != ownPid && proc.ExecutablePath = A_ScriptFullPath)
            Process, Close, % proc.ProcessId
    }
}

Caps_ResetState() {
    global lastCapsLockTime, capsLocked, capsIsHeld, capsActive, capsLedOn
    lastCapsLockTime := 0
    capsLocked := 0
    capsIsHeld := 0
    capsActive := 0
    Caps_SetLed(0)
}

; True CapsLock toggle state. This thread never receives keyboard input, so its own
; key-state view is stale/zeroed; briefly attach to the foreground thread's input
; state to read the value that actually capitalizes the user's typing.
Caps_RealToggleState() {
    self := DllCall("GetCurrentThreadId", "UInt")
    tid := DllCall("GetWindowThreadProcessId", "Ptr", DllCall("GetForegroundWindow", "Ptr"), "Ptr", 0, "UInt")
    attached := (tid && tid != self) ? DllCall("AttachThreadInput", "UInt", self, "UInt", tid, "Int", 1) : 0
    state := DllCall("GetKeyState", "Int", 0x14, "Short") & 1
    if (attached)
        DllCall("AttachThreadInput", "UInt", self, "UInt", tid, "Int", 0)
    return state
}

; Drive the real CapsLock toggle to match capsLedOn. SetCapsLockState is not usable
; here: it consults this thread's stale key-state view and skips needed toggles; and
; even direct injections issued inside the CapsLock hotkey handler get discarded when
; turning the state off. So the worker runs from a timer (outside handler context),
; verifies the real state, and re-injects until it converges. Injections are marked
; KEY_IGNORE (0xFFC3D44F) so our own hook passes them through instead of suppressing.
Caps_SetLed(on) {
    global capsLedOn, capsLedTries
    capsLedOn := on
    capsLedTries := 0
    SetTimer, Caps_LedWorker, -50
}

Caps_LedWorker() {
    global capsLedOn, capsLedTries
    if (Caps_RealToggleState() = capsLedOn || ++capsLedTries > 8)
        return
    DllCall("keybd_event", "UChar", 0x14, "UChar", 0x3A, "UInt", 0, "Ptr", 0xFFC3D44F)
    DllCall("keybd_event", "UChar", 0x14, "UChar", 0x3A, "UInt", 0x2, "Ptr", 0xFFC3D44F)
    SetTimer, Caps_LedWorker, -60
}

Caps_PowerBroadcast(wParam, lParam, msg, hwnd) {
    ; PBT_APMRESUMECRITICAL (0x6) / PBT_APMRESUMESUSPEND (0x7) / PBT_APMRESUMEAUTOMATIC (0x12)
    if (wParam = 0x6 || wParam = 0x7 || wParam = 0x12) {
        Caps_ResetState()
        ; Reload only on 0x12 — sent exactly once per wake. 0x7 follows it on user
        ; input and used to schedule a second reload, piling up caps.exe processes.
        if (wParam = 0x12)
            SetTimer, Caps_ReloadAfterResume, -1500
    }
    return true
}

Caps_ReloadAfterResume() {
    Reload
}

; No ~ prefix: AHK owns CapsLock entirely via Caps_SetLed, no race with system toggle
*CapsLock::
    if (capsIsHeld)
        return
    capsIsHeld := 1
    if (capsLocked) {
        capsLocked := 0
        capsActive := 0
        Caps_SetLed(0)
        return
    }
    now := A_TickCount
    if (now - lastCapsLockTime < doubleCapsLockInterval) {
        capsLocked := 1
        capsActive := 0 ; layer off, real caps lock on: capitals type normally
        Caps_SetLed(1)
    } else {
        capsActive := 1
    }
    lastCapsLockTime := now
return

*CapsLock up::
    capsIsHeld := 0
    if (!capsLocked)
        capsActive := 0
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
#include start_notepad.ahk

OpenKeyboardMap() {
    keymapPath := A_ScriptDir . "\keyboard-map-tks.svg"
    if FileExist(keymapPath) {
        Run, %keymapPath%
        return
    }
    MsgBox, 48, Caps, Keyboard map not found:`n%keymapPath%
}

pause::volume_up
scrollLock::volume_down
printScreen::volume_mute

#If capsActive

AppSKey::StartRun()

q::SleepOut()
w::up
e::+up
r::pgdn
t::home
y::end
u::pgup
i::up
o::volume_down
p::media_play_pause
[::volume_up
]::media_prev
\::media_next

a::left
s::down
d::right
f::+down
g::^+left
h::^+right
j::left
k::down
l::right
`;::volume_mute
SC028::StartNotepad()
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
1::lbutton
2::mbutton
3::rbutton
4::Send {₹}
5::ins
;6
;7
;8
;9
;0
-::–
+-::—
=::OpenKeyboardMap()
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
