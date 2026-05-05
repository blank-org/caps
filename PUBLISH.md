# Publish

## Setup:

1. Install AHK2EXE (from: AutoHotKey\UX\install-ahk2exe.ahk)

2. Save the default base file in AHK2EXE directory : v1.1_ > Save

## Build:

1. Update version numbers in `build/version.env`

2. Build
 
 Using AutoHotkey : `AHK2EXE` ( version: `1._` )

 ```ps
 .\make.ps1
 ```

3. Package :

```ps
Compress-Archive -LiteralPath caps.exe,CREDITS.md,LICENSE,README.md,Install.md,config.ini,keyboard-map-tks.svg -DestinationPath Caps-<version>.zip
```
