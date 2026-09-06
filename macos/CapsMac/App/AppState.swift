import Combine
import Foundation

/// Shared UI/runtime state for the menu bar shell.
final class AppState: ObservableObject {
    @Published var isSuspended = false
    @Published var modifierState = CapsModifierState()

    func toggleSuspended() {
        isSuspended.toggle()
    }
}
