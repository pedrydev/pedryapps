import Foundation
import Testing
@testable import PedryApps

@MainActor
struct JSONDocumentStoreTests {
    @Test func savedDocumentCanBeLoaded() throws {
        let directory = try TemporaryDirectory()
        let store = JSONDocumentStore<Document>(directory: directory.url, filename: "state.json")
        let document = Document(title: "First", count: 2)

        try store.save(document)

        #expect(try store.load() == document)
    }

    @Test func loadingMissingDocumentReturnsNil() throws {
        let directory = try TemporaryDirectory()
        let store = JSONDocumentStore<Document>(directory: directory.url, filename: "state.json")

        #expect(try store.load() == nil)
    }

    @Test func replacingDocumentLeavesNoTemporaryFile() throws {
        let directory = try TemporaryDirectory()
        let store = JSONDocumentStore<Document>(directory: directory.url, filename: "state.json")

        try store.save(Document(title: "First", count: 1))
        try store.save(Document(title: "Second", count: 2))

        #expect(try store.load() == Document(title: "Second", count: 2))
        #expect(
            FileManager.default.fileExists(
                atPath: directory.url.appendingPathComponent("state.json.tmp").path
            ) == false
        )
    }
}

private struct Document: Codable, Equatable {
    let title: String
    let count: Int
}
