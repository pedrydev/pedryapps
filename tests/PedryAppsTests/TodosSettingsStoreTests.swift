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

        store.setDueCheckIntervalSeconds(600)
        let reloaded = makeStore(in: directory.url)

        #expect(store.settings.dueCheckIntervalSeconds == 600)
        #expect(reloaded.settings.dueCheckIntervalSeconds == 600)
    }

    @Test func offGridStoredIntervalIsReadAsNearestStepWithoutRewrite() throws {
        let directory = try TemporaryDirectory()
        try Data("{\"dueCheckIntervalSeconds\": 420}".utf8).write(to: settingsURL(in: directory.url))
        let store = makeStore(in: directory.url)

        #expect(store.dueCheckIntervalMinutes == 5)
        #expect(store.settings.dueCheckIntervalSeconds == 420)
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

        store.setDueCheckIntervalSeconds(300)

        #expect(makeStore(in: directory.url).settings.dueCheckIntervalSeconds == 300)
    }

    @Test func offGridIntervalWritesAreSnappedToTheFiveMinuteGrid() throws {
        let directory = try TemporaryDirectory()
        let store = makeStore(in: directory.url)

        store.setDueCheckIntervalSeconds(1)
        #expect(store.dueCheckIntervalMinutes == 5)
        #expect(store.settings.dueCheckIntervalSeconds == 300)

        store.setDueCheckIntervalSeconds(2580)
        #expect(store.dueCheckIntervalMinutes == 45)
        #expect(store.settings.dueCheckIntervalSeconds == 2700)

        store.setDueCheckIntervalSeconds(3600)
        #expect(store.dueCheckIntervalMinutes == 60)
        #expect(store.settings.dueCheckIntervalSeconds == 3600)
    }

    @Test func failedSaveRollsBackIntervalChange() {
        let missingDirectory = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = TodosSettingsStore(
            documentStore: JSONDocumentStore(directory: missingDirectory, filename: "todos-settings.json")
        )

        store.setDueCheckIntervalSeconds(300)

        #expect(store.settings.dueCheckIntervalSeconds == 300)
    }

    @Test func settingsRemainUsableAfterFailedSave() throws {
        let directory = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let documentStore = JSONDocumentStore<TodosSettings>(directory: directory, filename: "todos-settings.json")
        let store = TodosSettingsStore(documentStore: documentStore)

        store.setDueCheckIntervalSeconds(300)
        #expect(store.settings.dueCheckIntervalSeconds == 300)

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        store.setDueCheckIntervalSeconds(600)

        #expect(store.settings.dueCheckIntervalSeconds == 600)
        #expect(try documentStore.load()?.dueCheckIntervalSeconds == 600)
    }

    @Test func settingsAreIndependentOfTodosDocument() throws {
        let directory = try TemporaryDirectory()
        let todosStore = TodosStore(
            documentStore: JSONDocumentStore(directory: directory.url, filename: "board.json")
        )
        let category = try #require(todosStore.addCategory("Work"))
        todosStore.addTodo("Buy milk", in: category)
        let settingsStore = makeStore(in: directory.url)

        settingsStore.setDueCheckIntervalSeconds(300)
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
