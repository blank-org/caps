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
rwinIsHeld := 0  ; Right Cmd (RWin) is physically down — alternate layer key, see *RWin
moveHeld := 0    ; bitmask of caps-layer mouse keys currently held (see Caps_MoveKey)
moveTimerOn := 0

Caps_CloseStaleInstances()
Caps_ResetState()
OnMessage(0x218, "Caps_PowerBroadcast")
; While the machine is locked, input goes to the secure desktop and this hook
; sees nothing — a layer key released there is never observed, leaving the
; layer stuck on after unlock (first symptom: space opens a terminal). Reset on
; lock and unlock. NOTIFY_FOR_THIS_SESSION = 0.
DllCall("Wtsapi32\WTSRegisterSessionNotification", "Ptr", A_ScriptHwnd, "UInt", 0)
OnMessage(0x2B1, "Caps_SessionChange") ; WM_WTSSESSION_CHANGE

; WTS_SESSION_LOCK = 0x7, WTS_SESSION_UNLOCK = 0x8
Caps_SessionChange(wParam, lParam, msg, hwnd) {
    if (wParam = 0x7 || wParam = 0x8)
        Caps_ResetState()
}

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
    global lastCapsLockTime, capsLocked, capsIsHeld, capsActive, capsLedOn, rwinIsHeld
    lastCapsLockTime := 0
    capsLocked := 0
    capsIsHeld := 0
    capsActive := 0
    rwinIsHeld := 0
    Caps_ReleaseAll()
    Caps_SetLed(0)
}

; Safety fallback: release anything the caps layer can hold down — the mouse buttons
; behind 1/2/3, the modifiers behind the shift/ctrl/alt remaps — and stop the mouse
; mover, so a layer toggle or a resume can never leave a button or modifier stuck.
; Each key is released ONLY if it is currently down: a bare {RButton Up} with no
; matching Down is delivered as WM_RBUTTONUP and pops a context menu, so unconditional
; releases would fire a menu (and stray clicks) on every toggle.
Caps_ReleaseAll() {
    Caps_StopMouseMove()
    for index, key in ["LButton", "MButton", "RButton", "LShift", "RShift", "LCtrl", "RCtrl", "LAlt", "RAlt"]
        if GetKeyState(key)
            Send, {Blind}{%key% Up}
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
    Caps_ReleaseAll() ; safety fallback: a toggle must never carry a stuck button/modifier
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
    if (!capsLocked && !rwinIsHeld)
        capsActive := 0
return

; Alternate layer key: the Apple Magic Keyboard does not deliver caps+ctrl+7/8/9 correctly.
; Right Cmd (RWin) arrives correctly, so holding it drives the nav layer from that board.
; Hold-only: no double-tap capitals lock, no LED. Suppressed, so a lone press cannot pop
; the Start menu.

; Win+L is detected in the kernel's raw-input path from PHYSICAL key state,
; BEFORE low-level hooks run (same protected mechanism as Ctrl+Alt+Del), so no
; hook trick can stop RWin+L locking: suppression, injected Win-ups, and remaps
; all run too late, and the DisableLockWorkstation policy escape hatch is not
; writable without elevation (HKCU\...\Policies is read-only to the user).
; Fix: a Scancode Map registry value relabels Right Cmd's scancode E0 5C to F24
; (00 76) inside the kernel, before Win+L detection ever sees a Win key — set
; 2026-07-05, effective after reboot. *F24 is the layer key from then on;
; *RWin stays stacked for keyboards without the remap applied.
*RWin::
*F24::
    if (rwinIsHeld)
        return
    rwinIsHeld := 1
    Caps_ReleaseAll() ; same safety fallback as the CapsLock handler
    capsActive := 1
return

*RWin up::
*F24 up::
    rwinIsHeld := 0
    if (!capsIsHeld || capsLocked)
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
; 7-0 drive the mouse pointer directly (Windows MouseKeys ignored our numpad
; injections). Explicit down/up hotkey pairs own the held-key state — see the
; Caps_MouseMoveTick comment for why GetKeyState polling is not usable here.
;   Shift = fast · Ctrl = precise · none = normal · Alt rotates 45° to a diagonal.
;   cardinal: 7 ←  8 ↑  9 ↓  0 →      with Alt: 7 ↖  8 ↗  9 ↙  0 ↘
*7::Caps_MoveKey("7", 1)
*7 up::Caps_MoveKey("7", 0)
*8::Caps_MoveKey("8", 1)
*8 up::Caps_MoveKey("8", 0)
*9::Caps_MoveKey("9", 1)
*9 up::Caps_MoveKey("9", 0)
*0::Caps_MoveKey("0", 1)
*0 up::Caps_MoveKey("0", 0)
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

; Non-blocking mouse mover for the caps-layer 7/8/9/0 keys, driven by a timer so
; every hotkey thread returns instantly (an earlier blocking `while GetKeyState()`
; loop desynced modifier tracking). Crucially it does NOT poll GetKeyState(.., "P"):
; that reads AHK's own hook bookkeeping, which goes stale when Shift/Ctrl is mixed
; into these suppressed wildcard hotkeys — first seen as movement continuing after
; the key was released, then as speed stuck fast/precise after leaving Shift/Ctrl.
; Instead the down/up hotkey pairs above own the held-key state in moveHeld, and
; modifiers are read from the OS async key state each tick (so speed/diagonal still
; update live mid-hold) — the OS self-heals that state on every real key event.
; The timer self-stops when the layer drops or all move keys are up, clearing
; moveHeld so a key-up missed while the layer is off can't leave a stale direction.
; moveHeld is an integer bitmask, NOT an object keyed by key name: v1 objects store
; a numeric string via a variable and via a literal under two different keys, so a
; moveKeys["7"] lookup never saw what moveKeys[key] stored.
;   Ctrl = precise (small step) · Shift = fast (large step) · neither = normal
;   Alt rotates the direction 45deg clockwise into the matching diagonal.
Caps_MoveKey(key, down) {
    global moveHeld, moveTimerOn
    bit := key = "7" ? 1 : key = "8" ? 2 : key = "9" ? 4 : 8
    moveHeld := down ? (moveHeld | bit) : (moveHeld & ~bit)
    if (down && !moveTimerOn) {
        moveTimerOn := 1
        SetTimer, Caps_MouseMoveTick, 10
    }
}

Caps_StopMouseMove() {
    global moveHeld, moveTimerOn
    moveTimerOn := 0
    moveHeld := 0
    SetTimer, Caps_MouseMoveTick, Off
}

Caps_ModifierDown(vk) {
    return DllCall("GetAsyncKeyState", "Int", vk, "UShort") & 0x8000
}

Caps_MouseMoveTick:
    if (!capsActive || !moveHeld) {
        Caps_StopMouseMove()
        return
    }
    moveDX := 0
    moveDY := 0
    moveAlt := Caps_ModifierDown(0x12)  ; VK_MENU (Alt)
    if (moveHeld & 1) {                 ; 7:  ← / ↖
        moveDX := moveDX - 1
        moveDY := moveDY - (moveAlt ? 1 : 0)
    }
    if (moveHeld & 2) {                 ; 8:  ↑ / ↗
        moveDY := moveDY - 1
        moveDX := moveDX + (moveAlt ? 1 : 0)
    }
    if (moveHeld & 4) {                 ; 9:  ↓ / ↙
        moveDY := moveDY + 1
        moveDX := moveDX - (moveAlt ? 1 : 0)
    }
    if (moveHeld & 8) {                 ; 0:  → / ↘
        moveDX := moveDX + 1
        moveDY := moveDY + (moveAlt ? 1 : 0)
    }
    ; opposing keys can cancel out; keep ticking so releasing one resumes movement
    if (moveDX = 0 && moveDY = 0)
        return
    ; VK_CONTROL / VK_SHIFT
    moveStep := Caps_ModifierDown(0x11) ? 4 : (Caps_ModifierDown(0x10) ? 30 : 12)
    MouseMove, moveDX * moveStep, moveDY * moveStep, 0, R
return
