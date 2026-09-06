import SwiftUI

/// Entry point for the native macOS Caps port.
@main
struct CapsMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Caps", systemImage: "keyboard") {
            MenuBarContentView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environmentObject(appState)
        }

        Window("About Caps", id: "about") {
            AboutView()
        }
        .defaultSize(width: 420, height: 280)
        .windowResizability(.contentSize)
    }
}
