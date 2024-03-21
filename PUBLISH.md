# Publish

1. Built using

 AutoHotkey : `AHK2EXE`  
 version: `1.1.37._ AutoHotKeyU64`

 ```ps
 Ahk2Exe.exe /in caps.ahk /out caps.exe /icon Resource/Icon/Keyboard.ico
 ```

2. Version number added using: [github: electron/rcedit](https://github.com/electron/rcedit)

 ```ps
 rcedit caps.exe --set-version-string "FileDescription" "Caps - shortcuts executioner" --set-version-string "ProductVersion" "0.4" --set-version-string "ProductName" "Caps - keyboard shortcuts" --set-version-string "ProductVersion" "0.4"
 ```

3. Package :

ps
```ps
Compress-Archive -LiteralPath caps.exe,CREDITS.md,LICENSE,README.md,Install.md,Resource/Keyboard-map-TKS.svg -DestinationPath Caps-0.5.zip
```
cmd
```
zip -j Caps-0.4.zip caps.exe CREDITS.md LICENSE README.md Install.md Resource/Keyboard-map-TKS.svg
```
