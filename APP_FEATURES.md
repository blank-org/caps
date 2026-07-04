# App Features

Caps repurposes the <kbd>CapsLock</kbd> key as a hold-modifier that activates a navigation/editing layer, so the hands never leave the home row. Reference: full key table in [README.md](README.md), visual map in `keyboard-map-tks.svg` (also on <kbd>Caps</kbd>+<kbd>=</kbd>).

## Caps layer basics

- **Hold <kbd>Caps</kbd>** — layer active while held; CapsLock LED doubles as the layer indicator.
- **Double-tap <kbd>Caps</kbd>** — normal caps lock (type capitals); next press turns it off.
- **Suspend** — tray icon > right-click > Suspend Hotkeys.

## Navigation (layer)

- **Arrows, twin clusters**: <kbd>W</kbd><kbd>A</kbd><kbd>S</kbd><kbd>D</kbd> and <kbd>I</kbd><kbd>J</kbd><kbd>K</kbd><kbd>L</kbd> → ↑ ← ↓ →.
- <kbd>T</kbd>/<kbd>Y</kbd> → Home/End, <kbd>U</kbd>/<kbd>R</kbd> → Page Up/Page Down.
- Word jumps: <kbd>V</kbd>/<kbd>N</kbd> → Ctrl+←/→; history/word: <kbd>C</kbd>/<kbd>M</kbd> → Alt+←/→; browser: <kbd>X</kbd>/<kbd>,</kbd> → Back/Forward.

## Selection (layer)

- <kbd>E</kbd>/<kbd>F</kbd> → Shift+↑/Shift+↓ (select line up/down).
- <kbd>G</kbd>/<kbd>H</kbd> → Ctrl+Shift+←/→ (select word left/right).

## Editing (layer)

- <kbd>Backspace</kbd> → Delete; <kbd>Ctrl</kbd>+<kbd>Backspace</kbd> → delete word.
- <kbd>5</kbd> → Insert; <kbd>B</kbd> → paste-type (types clipboard contents); <kbd>4</kbd> → ₹; <kbd>-</kbd> → – (en dash), <kbd>Shift</kbd>+<kbd>-</kbd> → — (em dash).

## Mouse (layer)

- <kbd>1</kbd>/<kbd>2</kbd>/<kbd>3</kbd> → left/middle/right mouse button.

## Media & volume

- Layer: <kbd>O</kbd> volume down, <kbd>[</kbd> volume up, <kbd>;</kbd> mute, <kbd>P</kbd> play/pause, <kbd>]</kbd>/<kbd>\</kbd> previous/next track.
- Direct (no layer): <kbd>PrtSc</kbd> mute, <kbd>ScrLk</kbd> volume down, <kbd>Pause</kbd> volume up.

## Apps & system (layer)

- <kbd>Space</kbd> terminal at active Explorer path, <kbd>/</kbd> VS Code, <kbd>'</kbd> Notepad, <kbd>.</kbd> toggle Windows dark mode, <kbd>=</kbd> open keyboard map, <kbd>Menu</kbd> app shortcut menu, <kbd>Q</kbd> sleep, <kbd>Z</kbd> monitor off.

## TKL numpad layer

With <kbd>Caps</kbd> held, the nav cluster emulates a numpad on tenkeyless boards: <kbd>PrtSc</kbd>/<kbd>ScrLk</kbd>/<kbd>Pause</kbd> → 7/8/9, <kbd>Ins</kbd>/<kbd>Home</kbd>/<kbd>PgUp</kbd> → 4/5/6, <kbd>Del</kbd>/<kbd>End</kbd>/<kbd>PgDn</kbd> → 1/2/3, arrows → 0 . - +.

## Window switching

- <kbd>Alt</kbd>+<kbd>`</kbd> — switch between windows of the same app.

## Config (`config.ini`)

- `right_click_left=1` — maps mouse right click to left click.
