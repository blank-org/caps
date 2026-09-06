import Foundation

/// Captures and interprets Caps Lock / layer key events.
///
/// Future work: install a CGEvent tap or IOHID callback, coordinate with
/// `CapsModifierState`, and route keys through `KeyMap`.
final class CapsInputHandler {
    private let configuration: CapsConfiguration
    private(set) var modifierState = CapsModifierState()

    init(configuration: CapsConfiguration) {
        self.configuration = configuration
    }

    func start() {
        // Stub: no event tap installed yet.
        _ = configuration
    }

    func stop() {
        modifierState = CapsModifierState()
    }

    func handleCapsLockKeyDown(at timestamp: TimeInterval) {
        // Stub for double-tap detection and hold tracking.
        _ = timestamp
    }

    func handleCapsLockKeyUp(at timestamp: TimeInterval) {
        _ = timestamp
    }
}
