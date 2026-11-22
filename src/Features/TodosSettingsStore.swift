import Foundation
import Observation

@MainActor
@Observable
final class TodosSettingsStore {
    private(set) var settings: TodosSettings = .default

    var onDueCheckIntervalChange: (() -> Void)?

    var dueCheckIntervalMinutes: Int {
        get { settings.dueCheckIntervalMinutes }
        set {
            guard let seconds = TodosSettings.seconds(fromMinutes: newValue) else { return }
            setDueCheckIntervalSeconds(seconds)
        }
    }

    private let documentStore: JSONDocumentStore<TodosSettings>?

    init(documentStore: JSONDocumentStore<TodosSettings>? = nil) {
        if let documentStore {
            self.documentStore = documentStore
        } else {
            self.documentStore = try? JSONDocumentStore(filename: "todos-settings.json")
        }
        load()
    }

    func load() {
        guard let documentStore else { return }
        settings = (try? documentStore.load()) ?? .default
    }

    func setDueCheckIntervalSeconds(_ seconds: Int) {
        guard seconds > 0 else { return }
        let minutes = TodosSettings.snappedMinutes(from: seconds / 60)
        guard let gridSeconds = TodosSettings.seconds(fromMinutes: minutes) else { return }
        let previous = settings
        settings = TodosSettings(dueCheckIntervalSeconds: gridSeconds)
        guard persist() else {
            settings = previous
            return
        }
        onDueCheckIntervalChange?()
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
