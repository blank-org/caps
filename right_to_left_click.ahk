; capsActive/capsLocked variables instead of GetKeyState: the real CapsLock toggle
; no longer tracks the held layer, and this thread's key-state view is stale anyway
#If (!capsActive && !capsLocked && rightClickLeft)
RButton::
    ; Caps Lock is off, so replace right-click with left-click
    Send {LButton down}
    KeyWait, RButton
    Send {LButton up}
    return
#If  ; end context-sensitive block
