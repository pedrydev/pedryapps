import Foundation
import Testing
@testable import Macos

@MainActor
struct JSONDocumentStoreTests {
    @Test func savedDocumentCanBeLoaded() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = JSONDocumentStore<Document>(directory: directory, filename: "state.json")
        let document = Document(title: "First", count: 2)

        try store.save(document)

        #expect(try store.load() == document)
    }

    @Test func loadingMissingDocumentReturnsNil() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = JSONDocumentStore<Document>(directory: directory, filename: "state.json")

        #expect(try store.load() == nil)
    }

    @Test func replacingDocumentLeavesNoTemporaryFile() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = JSONDocumentStore<Document>(directory: directory, filename: "state.json")

        try store.save(Document(title: "First", count: 1))
        try store.save(Document(title: "Second", count: 2))

        #expect(try store.load() == Document(title: "Second", count: 2))
        #expect(!FileManager.default.fileExists(atPath: directory.appendingPathComponent("state.json.tmp").path))
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

private struct Document: Codable, Equatable {
    let title: String
    let count: Int
}
