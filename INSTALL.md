# Installation

## Scripted install

From the project directory, run:

```powershell
.\install.ps1
```

The script builds `caps.exe`, stops the currently installed `caps.exe` when it is running from the install directory, and copies changed release files to `C:\Programs\Caps`. Use `-InstallDir` to choose another folder, `-SkipBuild` to sync an existing build, and `-Launch` to start the installed app after syncing.

Example:

```powershell
.\install.ps1 -InstallDir "$env:LocalAppData\Programs\Caps" -Launch
```

## Manual install

1. Recommended path:

		\Programs\Caps\
  
2. Place shortcut in the `Startup` directory:

 `Run:`  `shell:startup` 

 or,
 
		%AppData%\Microsoft\Windows\Start Menu\Programs\Startup\
  
3. Place shortcut to the `Keyboard-map` and `Readme` in Start menu:

		%AppData%\Microsoft\Windows\Start Menu\

## Optional: Right Cmd layer key without Win+L locking

Windows detects <kbd>Win</kbd>+<kbd>L</kbd> in the kernel from physical key state, before any keyboard hook runs, so holding <kbd>Right Cmd</kbd> as the layer key would otherwise lock the workstation on <kbd>L</kbd>. To prevent this, relabel Right Cmd's scancode to F24 inside the kernel via a Scancode Map (admin PowerShell, then reboot):

```powershell
$map = [byte[]](0,0,0,0, 0,0,0,0, 2,0,0,0, 0x76,0,0x5C,0xE0, 0,0,0,0)
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout' -Name 'Scancode Map' -Value $map -Type Binary
```

This maps scancode `E0 5C` (Right Win/Cmd) to `00 76` (F24) for all keyboards system-wide; `caps.exe` treats F24 identically to Right Win as the layer key. To undo, delete the `Scancode Map` value and reboot.
