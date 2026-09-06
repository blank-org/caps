import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var configuration = ConfigStore.shared.load()

    var body: some View {
        Form {
            Section("Layer") {
                LabeledContent("Status") {
                    Text(appState.isSuspended ? "Suspended" : "Active")
                }
            }

            Section("Configuration") {
                Toggle("Map right click to left click", isOn: $configuration.rightClickMapsToLeftClick)
                    .help("Mirrors the Windows `right_click_left` option in config.ini.")
            }

            Section("Permissions") {
                LabeledContent("Accessibility") {
                    Text(AccessibilityPermission.statusDescription)
                }
                Button("Open Accessibility Settings") {
                    AccessibilityPermission.requestAccess()
                }
            }

            Section("Development") {
                Text("Keyboard remapping is not implemented yet. This build is a scaffold for the native macOS port.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 420, minHeight: 320)
        .onDisappear {
            ConfigStore.shared.save(configuration)
        }
    }
}
