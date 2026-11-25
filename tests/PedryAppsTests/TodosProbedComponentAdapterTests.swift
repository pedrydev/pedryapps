import Foundation
import Testing
@testable import PedryApps

@MainActor
struct TodosProbedComponentAdapterTests {
    @Test func healthyWhenTodosHasNoError() throws {
        let directory = try TemporaryDirectory()
        let store = TodosStore(
            documentStore: JSONDocumentStore(directory: directory.url, filename: "board.json")
        )

        let probedComponent = TodosProbedComponentAdapter(store: store).probedComponent

        #expect(probedComponent.id == "todos")
        #expect(probedComponent.name == "Todos")
        #expect(probedComponent.healthState == .healthy)
    }

    @Test func unhealthyWhenTodosHasUnresolvedError() throws {
        let directory = try TemporaryDirectory()
        let documentURL = directory.url.appendingPathComponent("board.json")
        try Data("not json".utf8).write(to: documentURL)
        let store = TodosStore(
            documentStore: JSONDocumentStore(directory: directory.url, filename: "board.json")
        )

        #expect(
            TodosProbedComponentAdapter(store: store).probedComponent.healthState == .unhealthy
        )
    }
}
