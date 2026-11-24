import Foundation
import Testing
@testable import PedryApps

@MainActor
struct TodosDocumentTests {
    @Test func categoriesAndTodosRoundTripInOrder() throws {
        let directory = try TemporaryDirectory()
        let documentStore = JSONDocumentStore<TodosDocument>(directory: directory.url, filename: "board.json")
        let work = PedryApps.Category(name: "Work")
        let home = PedryApps.Category(name: "Home")
        let todo = Todo(categoryID: home.id, title: "Buy milk")

        try documentStore.save(TodosDocument(categories: [work, home], todos: [todo]))

        let loaded = try #require(try documentStore.load())
        #expect(loaded.categories == [work, home])
        #expect(loaded.todos == [todo])
    }

    @Test func flatListFileIsNotUsedByTheBoardDocument() throws {
        let directory = try TemporaryDirectory()
        let documentStore = JSONDocumentStore<TodosDocument>(directory: directory.url, filename: "board.json")
        try Data(#"{"todos":[{"title":"Buy milk"}]}"#.utf8)
            .write(to: directory.url.appendingPathComponent("todos.json"))

        #expect(try documentStore.load() == nil)
    }

    @Test func malformedDocumentCannotBeDecoded() throws {
        let directory = try TemporaryDirectory()
        let documentStore = JSONDocumentStore<TodosDocument>(directory: directory.url, filename: "board.json")
        try Data("not json".utf8).write(to: directory.url.appendingPathComponent("board.json"))

        #expect(throws: (any Error).self) { try documentStore.load() }
    }
}
