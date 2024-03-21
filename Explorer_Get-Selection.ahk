;Source: https://stackoverflow.com/a/39263800/483588 | CC BY-SA 3.0
;Original author: errorseven | https://stackoverflow.com/users/1914172/errorseven

Explorer_GetSelection(hwnd="") {
    WinGet, process, processName, % "ahk_id" hwnd := hwnd? hwnd:WinExist("A")
    WinGetClass class, ahk_id %hwnd%
    if (process = "explorer.exe") 
        if (class ~= "(Cabinet|Explore)WClass") {
            for window in ComObjCreate("Shell.Application").Windows
                if (window.hwnd==hwnd)
                    focusedItem := window.Document.FocusedItem
                    if (focusedItem) {
                        path := focusedItem.path
                        SplitPath, path,, dir
                    } else {
                        try path := window.Document.Folder.Self.Path
                        return path
                    }
            SplitPath, path,,dir
        }
        return dir
}
