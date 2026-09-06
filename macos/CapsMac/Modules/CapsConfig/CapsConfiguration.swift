import Foundation

/// User-facing configuration for the macOS port.
struct CapsConfiguration: Codable, Equatable {
    /// Mirrors Windows `config.ini` → `right_click_left`.
    var rightClickMapsToLeftClick: Bool = false

    /// Placeholder for future key-map profile selection.
    var keyMapProfileName: String = "default"
}
