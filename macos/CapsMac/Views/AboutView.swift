import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "keyboard")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("Caps for macOS")
                .font(.title2.bold())

            Text("Native port scaffold — hold Caps Lock for a home-row navigation layer.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Text("Version 0.1.0 (scaffold)")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Link("Windows Caps reference", destination: URL(string: "https://github.com/blank-org/caps")!)
                .font(.caption)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
