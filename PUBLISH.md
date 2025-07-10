# Publish

## Setup:

1. Install AHK2EXE (from: AutoHotKey\UX\install-ahk2exe.ahk)

2. Save the default base file in AHK2EXE directory : v1.1_ > Save

## Build:

1. Update version number in scipt (SetFileVersion)

2. Build
 
 Using AutoHotkey : `AHK2EXE` ( version: `1._` )

 ```ps
 & $env:LocalAppData\Programs\AutoHotKey\Compiler\Ahk2Exe.exe /in caps.ahk /out caps.exe /icon Resource/Icon/Keyboard.ico
 ```

3. Package :

```ps
Compress-Archive -LiteralPath caps.exe,CREDITS.md,LICENSE,README.md,Install.md,config.ini,Resource/Keyboard-map-TKS.svg -DestinationPath Caps-<version>.zip
```
