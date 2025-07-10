Start_VScode() {
    EnvGet, A_LocalAppData, LocalAppData
    ; Locate code executable
    possible := []
    OutputDebug % "After init: " . possible.Length()
    ; Standard install locations
    possible.Push(A_ProgramFiles  . "\Microsoft VS Code\Code.exe")
    possible.Push(A_ProgramFiles  . "\Microsoft VS Code\bin\code.cmd")
    possible.Push(A_ProgramFiles  . "\Microsoft VS Code\bin\code.exe")
    ; 32-bit on 64-bit OS
    possible.Push(A_ProgramFiles  . "(x86)\Microsoft VS Code\Code.exe")
    possible.Push(A_ProgramFiles  . "(x86)\Microsoft VS Code\bin\code.cmd")
    possible.Push(A_ProgramFiles  . "(x86)\Microsoft VS Code\bin\code.exe")
    ; Per-user install
    possible.Push(A_LocalAppData  . "\Programs\Microsoft VS Code\Code.exe")

    codePath := ""
    possiblePathS := ""
    for _, path in possible {
        OutputDebug % "VSCode path tried:`n" . path
        possiblePathS .= path . "`n"
        if FileExist(path) {
            codePath := path
            break
        }
    }

    if (!codePath) {
        ; print the list
        
        MsgBox, 48, VS Code Not Found, % "Tried paths:`n" . possiblePathS
        return
    }
    v := Explorer_GetSelection()
    if (v) {
        Run "%codePath%" -d "%v%"
    }
    else
        Run "%codePath%"
}
