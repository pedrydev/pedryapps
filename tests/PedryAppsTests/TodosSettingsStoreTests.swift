import Foundation
import Testing
@testable import PedryApps

@MainActor
struct TodosSettingsStoreTests {
    @Test func missingSettingsDocumentUsesDefaultInterval() throws {
        let directory = try TemporaryDirectory()

        let store = makeStore(in: directory.url)

        #expect(store.settings.dueCheckIntervalSeconds == 300)
    }

    @Test func changingIntervalPersistsAndRestores() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)

        store.setDueCheckIntervalSeconds(60)
        let reloaded = makeStore(in: directory.url)

        #expect(store.settings.dueCheckIntervalSeconds == 60)
        #expect(reloaded.settings.dueCheckIntervalSeconds == 60)
    }

    @Test func injectedPositiveSecondsAreNotClampedToMinuteBounds() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)

        store.setDueCheckIntervalSeconds(1)

        #expect(store.settings.dueCheckIntervalSeconds == 1)
    }

    @Test func nonPositiveIntervalIsIgnored() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)

        store.setDueCheckIntervalSeconds(0)
        store.setDueCheckIntervalSeconds(-300)

        #expect(store.settings.dueCheckIntervalSeconds == 300)
    }

    @Test func malformedDocumentFallsBackToDefault() throws {
        let directory = try TemporaryDirectory()
        try Data("not json".utf8).write(to: settingsURL(in: directory.url))

        let store = makeStore(in: directory.url)

        #expect(store.settings.dueCheckIntervalSeconds == 300)
    }

    @Test(arguments: [0, -300])
    func outOfRangeStoredIntervalFallsBackToDefault(_ seconds: Int) throws {
        let directory = try TemporaryDirectory()
        try Data("{\"dueCheckIntervalSeconds\": \(seconds)}".utf8).write(to: settingsURL(in: directory.url))

        let store = makeStore(in: directory.url)

        #expect(store.settings.dueCheckIntervalSeconds == 300)
    }

    @Test func fallbackIsReplacedOnNextWrite() throws {
        let directory = try TemporaryDirectory()
        try Data("not json".utf8).write(to: settingsURL(in: directory.url))
        let store = makeStore(in: directory.url)
        #expect(store.settings.dueCheckIntervalSeconds == 300)

        store.setDueCheckIntervalSeconds(60)

        #expect(makeStore(in: directory.url).settings.dueCheckIntervalSeconds == 60)
    }

    @Test func subMinuteInjectedIntervalStaysWithinDisplayBounds() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)

        store.setDueCheckIntervalSeconds(1)
        #expect(store.dueCheckIntervalMinutes == 1)

        store.setDueCheckIntervalSeconds(3600)
        #expect(store.dueCheckIntervalMinutes == 60)
    }

    @Test func failedSaveRollsBackIntervalChange() {
        let missingDirectory = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = TodosSettingsStore(
            documentStore: JSONDocumentStore(directory: missingDirectory, filename: "todos-settings.json")
        )

        store.setDueCheckIntervalSeconds(60)

        #expect(store.settings.dueCheckIntervalSeconds == 300)
    }

    @Test func settingsRemainUsableAfterFailedSave() throws {
        let directory = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let documentStore = JSONDocumentStore<TodosSettings>(directory: directory, filename: "todos-settings.json")
        let store = TodosSettingsStore(documentStore: documentStore)

        store.setDueCheckIntervalSeconds(60)
        #expect(store.settings.dueCheckIntervalSeconds == 300)

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        store.setDueCheckIntervalSeconds(120)

        #expect(store.settings.dueCheckIntervalSeconds == 120)
        #expect(try documentStore.load()?.dueCheckIntervalSeconds == 120)
    }

    @Test func settingsAreIndependentOfTodosDocument() throws {
        let directory = try TemporaryDirectory()
        let todosStore = TodosStore(
            documentStore: JSONDocumentStore(directory: directory.url, filename: "todos.json")
        )
        todosStore.addTodo("Buy milk")
        let settingsStore = makeStore(in: directory.url)

        settingsStore.setDueCheckIntervalSeconds(60)
        todosStore.load()

        #expect(todosStore.todos.map(\.title) == ["Buy milk"])
    }

    private func makeStore(in directory: URL) -> TodosSettingsStore {
        TodosSettingsStore(
            documentStore: JSONDocumentStore(directory: directory, filename: "todos-settings.json")
        )
    }

    private func settingsURL(in directory: URL) -> URL {
        directory.appendingPathComponent("todos-settings.json")
    }
}
