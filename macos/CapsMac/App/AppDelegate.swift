import AppKit

/// AppKit lifecycle hooks for low-level keyboard integration (CGEvent taps, etc.).
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var inputHandler: CapsInputHandler?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let configuration = ConfigStore.shared.load()
        inputHandler = CapsInputHandler(configuration: configuration)
        inputHandler?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        inputHandler?.stop()
        inputHandler = nil
    }
}
