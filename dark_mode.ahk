; DarkModeToggle.ahk
; This script defines a function to toggle Windows dark mode, including the taskbar.

ToggleDarkMode() {
    ; Read the current value of AppsUseLightTheme from the registry
    RegRead, AppsUseLightTheme, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize, AppsUseLightTheme
    if (ErrorLevel) {
        MsgBox, Error reading the AppsUseLightTheme registry value.
        return
    }

    ; Determine the new value (toggle between 0 and 1)
    if (AppsUseLightTheme = 0) {
        NewValue := 1  ; Switch to light mode
    } else {
        NewValue := 0  ; Switch to dark mode
    }

    ; Write the new values to the registry for both apps and system
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize, AppsUseLightTheme, %NewValue%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize, SystemUsesLightTheme, %NewValue%

    ; Notify the system of the setting change
    ; Send WM_SETTINGCHANGE message to all top-level windows
    SendMessage, 0x1A, 0, 0, , Program Manager  ; WM_SETTINGCHANGE

    ; Broadcast WM_THEMECHANGED message to all windows
    ; This forces the taskbar and other system components to update
    SendMessageTimeout := DllCall("User32.dll\SendMessageTimeout", "UInt", 0xFFFF, "UInt", 0x031A, "UInt", 0, "UInt", 0, "UInt", 0x0002, "UInt", 500, "Ptr*", Result)

    ; Force a redraw of the desktop
    DllCall("Shell32.dll\SHChangeNotify", "Int", 0x8000000, "UInt", 0x1000, "Ptr", 0, "Ptr", 0)
}
