import Foundation

/// Tracks Caps Lock layer modifier state (hold, double-tap lock, suspend).
struct CapsModifierState: Equatable {
    var isLayerHeld = false
    var isCapsLockEngaged = false
    var isSuspended = false

    var isLayerActive: Bool {
        isLayerHeld && !isSuspended && !isCapsLockEngaged
    }

    var layerDescription: String {
        if isSuspended { return "Suspended" }
        if isCapsLockEngaged { return "Caps Lock" }
        if isLayerHeld { return "Held" }
        return "Idle"
    }
}
