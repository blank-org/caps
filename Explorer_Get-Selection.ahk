; Using shortcut to get the selected path in Windows Explorer reliably as direct com methods kept failing

Explorer_GetSelection(hwnd := "") {
    ; Only proceed if an Explorer window is active
    if !WinActive("ahk_class CabinetWClass")
        return ""  

    ; Backup and clear the clipboard
    clipBackup := ClipboardAll
    Clipboard := ""  

    ; Focus the address bar (active tab), select all, and copy
    Send {F4}           ; F4 → focus that tab’s address bar :contentReference[oaicite:3]{index=3}
    Sleep 50
    Send ^a            ; Ctrl+A → select all :contentReference[oaicite:4]{index=4}
    Sleep 50
    Send ^c            ; Ctrl+C → copy selection :contentReference[oaicite:5]{index=5}
    ClipWait, 0.5
    ; send esc
    Send {Esc}         ; Escape → close the address bar :contentReference[oaicite:6]{index=6}

    ; Retrieve and restore clipboard
    path := Clipboard
    Clipboard := clipBackup

    return path
}
