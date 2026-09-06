# Caps for macOS

Native Swift/SwiftUI port of [Caps](../README.md) — a menu-bar keyboard utility that turns **Caps Lock** into a hold-modifier for home-row navigation, editing, media, and more.

> **Status:** scaffold only. The app launches and shows a menu-bar shell; keyboard remapping is not implemented yet.

## Requirements

- macOS 13 (Ventura) or later
- Xcode 15 or later (Xcode 16 recommended)
- Apple Silicon or Intel Mac

## Open in Xcode

```bash
open macos/CapsMac.xcodeproj
```

Select the **CapsMac** scheme, then **Product → Run** (⌘R).

The app runs as a **menu-bar utility** (`LSUIElement`): no Dock icon. Look for the keyboard icon in the menu bar.

## Project layout

```
macos/
├── CapsMac.xcodeproj/     # Xcode project (open this)
├── CapsMac/
│   ├── CapsMacApp.swift   # @main entry, MenuBarExtra + Settings
│   ├── App/               # AppDelegate, shared AppState
│   ├── Views/             # Menu bar menu, Settings, About
│   ├── Modules/
│   │   ├── CapsInput/     # CGEvent tap / modifier state (stubs)
│   │   ├── CapsKeyMap/    # Key → action map (stubs)
│   │   ├── CapsConfig/    # Configuration persistence (stubs)
│   │   └── CapsSystem/    # Accessibility, media, app launch (stubs)
│   └── Resources/         # Info.plist, Assets
└── README.md              # this file
```

## Module boundaries (planned)

| Module | Responsibility |
|--------|----------------|
| **CapsInput** | Capture Caps Lock hold/double-tap; install global event tap |
| **CapsKeyMap** | Map physical keys to actions (parity with `resource/map_caps.csv`) |
| **CapsConfig** | User settings (`~/Library/Application Support/Caps/config.json`) |
| **CapsSystem** | Accessibility permission, volume/media, display sleep, app launchers |

## Accessibility permission

Global key remapping requires **Accessibility** access. The Settings window includes a shortcut to System Settings → Privacy & Security → Accessibility. Grant access before testing future keyboard hooks.

## Command-line build (optional)

On a Mac with Xcode command-line tools:

```bash
cd macos
xcodebuild -scheme CapsMac -configuration Debug -destination 'platform=macOS' build
```

The built app is under `DerivedData` or:

```bash
xcodebuild -scheme CapsMac -configuration Debug -destination 'platform=macOS' -derivedDataPath build/DerivedData build
open build/DerivedData/Build/Products/Debug/CapsMac.app
```

## Windows reference

The shipping Windows build lives at the repo root (`caps.ahk` → `caps.exe`). See [README.md](../README.md) and [APP_FEATURES.md](../APP_FEATURES.md) for the full shortcut map.

## Next steps

1. Wire `CapsInputHandler` to a `CGEvent` tap for Caps Lock.
2. Expand `KeyMap` toward Windows parity using `resource/map_caps.csv`.
3. Implement `SystemIntegration` actions (volume, Terminal, VS Code, dark mode).
4. Add Input Monitoring entitlement if required for certain key paths.
