import Foundation

/// Persists configuration to Application Support.
final class ConfigStore {
    static let shared = ConfigStore()

    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func load() -> CapsConfiguration {
        guard let url = configFileURL,
              fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let configuration = try? decoder.decode(CapsConfiguration.self, from: data) else {
            return CapsConfiguration()
        }
        return configuration
    }

    func save(_ configuration: CapsConfiguration) {
        guard let url = configFileURL else { return }
        do {
            try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try encoder.encode(configuration)
            try data.write(to: url, options: .atomic)
        } catch {
            // Scaffold: log to stderr until a logging module exists.
            fputs("CapsMac: failed to save configuration: \(error)\n", stderr)
        }
    }

    private var configFileURL: URL? {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Caps", isDirectory: true)
            .appendingPathComponent("config.json")
    }
}
