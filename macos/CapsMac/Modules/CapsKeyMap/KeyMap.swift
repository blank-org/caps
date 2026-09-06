import Foundation

/// Maps physical keys to Caps-layer actions.
///
/// Parity target: `resource/map_caps.csv` and the shortcut table in README.md.
struct KeyMap {
    private let bindings: [String: ShortcutAction]

    init(bindings: [String: ShortcutAction] = KeyMap.defaultBindings) {
        self.bindings = bindings
    }

    func action(forKeyCode keyCode: UInt16) -> ShortcutAction {
        bindings[String(keyCode), default: .unmapped]
    }

    func action(forKeyLabel label: String) -> ShortcutAction {
        bindings[label.lowercased(), default: .unmapped]
    }

    /// Minimal seed map for development; expand toward Windows parity.
    static let defaultBindings: [String: ShortcutAction] = [
        "w": .moveUp,
        "a": .moveLeft,
        "s": .moveDown,
        "d": .moveRight,
        "i": .moveUp,
        "j": .moveLeft,
        "k": .moveDown,
        "l": .moveRight,
        "t": .home,
        "y": .end,
        "u": .pageUp,
        "r": .pageDown,
        "o": .volumeDown,
        "p": .playPause,
        "[": .volumeUp,
        "]": .previousTrack,
        "\\": .nextTrack,
        ";": .volumeMute,
        "1": .mouseLeftClick,
        "2": .mouseMiddleClick,
        "3": .mouseRightClick,
        "space": .openTerminal,
        "/": .openEditor,
        ".": .toggleDarkMode,
        "=": .showKeyboardMap,
        "q": .sleepDisplay,
        "b": .pasteType,
    ]
}
