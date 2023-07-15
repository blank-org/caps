# Publish

1. Built using

 >AutoHotkey : `AHK2EXE`  
 Ahk2Exe.exe /in caps.ahk /out caps.exe /icon Resource/Icon/Keyboard.ico
 
2. Version number added using: [github: electron/rcedit](https://github.com/electron/rcedit)

 > rcedit caps.exe --set-version-string "FileDescription" "Caps - shortcuts executioner" --set-version-string "ProductVersion" "0.4" --set-version-string "ProductName" "Caps - keyboard shortcuts" --set-version-string "ProductVersion" "0.4"

3. Package :

 > zip -j Caps-0.4.zip caps.exe CREDITS.md LICENSE README.md Resource/Keyboard-map-TKS.svg
