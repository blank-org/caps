#If (!GetKeyState("CapsLock", "T") && rightClickLeft)
RButton::
    ; Caps Lock is off, so replace right-click with left-click
    Send {LButton down}
    KeyWait, RButton
    Send {LButton up}
    return
#If  ; end context-sensitive block
