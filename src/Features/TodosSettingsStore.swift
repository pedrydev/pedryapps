import Foundation
import Observation

@MainActor
@Observable
final class TodosSettingsStore {
    private(set) var settings: TodosSettings = .default

    var dueCheckIntervalMinutes: Int {
        get {
            min(
                max(settings.dueCheckIntervalMinutes, TodosSettings.minuteBounds.lowerBound),
                TodosSettings.minuteBounds.upperBound
            )
        }
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
        let previous = settings
        settings = TodosSettings(dueCheckIntervalSeconds: seconds)
        if !persist() { settings = previous }
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
