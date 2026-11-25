import Foundation
import Observation

@MainActor
@Observable
final class MCPSettingsStore {
    private(set) var settings: MCPSettings = .default

    private let documentStore: JSONDocumentStore<MCPSettings>?

    init(documentStore: JSONDocumentStore<MCPSettings>? = nil) {
        if let documentStore {
            self.documentStore = documentStore
        } else {
            self.documentStore = try? JSONDocumentStore(filename: "mcp-settings.json")
        }
        load()
    }

    func load() {
        guard let documentStore else { return }
        settings = (try? documentStore.load()) ?? .default
    }

    func setPort(_ port: Int) -> Bool {
        let previous = settings
        settings = MCPSettings(port: port)
        guard persist() else {
            settings = previous
            return false
        }
        return true
    }

    private func persist() -> Bool {
        guard let documentStore else { return false }
        do {
            try documentStore.save(settings)
            return true
        } catch {
            return false
        }
    }
}
