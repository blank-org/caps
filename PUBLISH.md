# Publish

1. Update version number in scipt  

2. Build
 
 Using AutoHotkey : `AHK2EXE` ( version: `1._` )

 ```ps
 & $env:LocalAppData\Programs\AutoHotKey\Compiler\Ahk2Exe.exe
 /in caps.ahk /out caps.exe /icon Resource/Icon/Keyboard.ico
 ```

3. Package :

```ps
Compress-Archive -LiteralPath caps.exe,CREDITS.md,LICENSE,README.md,Install.md,Resource/Keyboard-map-TKS.svg -DestinationPath Caps-0.5.zip
```
 