import AppKit
import Foundation

/// macOS-specific integrations (media keys, display sleep, app launchers).
enum SystemIntegration {
    static func openTerminal() {
        NSWorkspace.shared.launchApplication("Terminal")
    }

    static func openEditor() {
        // Placeholder: align with Windows VS Code shortcut during feature port.
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.VSCode") {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        }
    }

    static func sleepDisplay() {
        // Stub: IOKit display sleep call will live here.
    }

    static func setDarkMode(enabled: Bool) {
        // Stub: AppleInterfaceStyle toggling will live here.
        _ = enabled
    }
}
