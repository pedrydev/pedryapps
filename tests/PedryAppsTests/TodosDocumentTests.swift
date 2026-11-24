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

    @Test func reorderedTodosRoundTripWithTheirCategoryAssignments() throws {
        let directory = try TemporaryDirectory()
        let documentStore = JSONDocumentStore<TodosDocument>(directory: directory.url, filename: "board.json")
        let work = PedryApps.Category(name: "Work")
        let home = PedryApps.Category(name: "Home")
        let buyMilk = Todo(categoryID: work.id, title: "Buy milk", doOnDate: DoOnDate(Date().addingTimeInterval(3600)))
        let callSam = Todo(categoryID: home.id, title: "Call Sam", doOnDate: DoOnDate(Date().addingTimeInterval(7200)))
        let payBills = Todo(categoryID: work.id, title: "Pay bills", doOnDate: DoOnDate(Date().addingTimeInterval(10800)))

        try documentStore.save(TodosDocument(categories: [work, home], todos: [payBills, callSam, buyMilk]))

        let loaded = try #require(try documentStore.load())
        #expect(loaded.todos.map(\.id) == [payBills.id, callSam.id, buyMilk.id])
        #expect(loaded.todos.map(\.title) == ["Pay bills", "Call Sam", "Buy milk"])
        let loadedBuyMilk = try #require(loaded.todos.first { $0.id == buyMilk.id })
        let loadedCallSam = try #require(loaded.todos.first { $0.id == callSam.id })
        #expect(loadedBuyMilk.categoryID == work.id)
        #expect(loadedCallSam.categoryID == home.id)
        #expect(loadedBuyMilk.doOnDate == buyMilk.doOnDate)
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
