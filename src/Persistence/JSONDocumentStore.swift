import Foundation

@MainActor
final class JSONDocumentStore<Document: Codable> {
    private let fileURL: URL
    private let fileManager: FileManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(directory: URL, filename: String, fileManager: FileManager = .default) {
        self.fileURL = directory.appendingPathComponent(filename)
        self.fileManager = fileManager
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    convenience init(filename: String) throws {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        self.init(directory: directory, filename: filename)
    }

    func load() throws -> Document? {
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(Document.self, from: data)
    }

    func save(_ document: Document) throws {
        let data = try encoder.encode(document)
        let temporaryURL = fileURL.deletingLastPathComponent()
            .appendingPathComponent(fileURL.lastPathComponent + ".tmp")
        try data.write(to: temporaryURL, options: .atomic)

        if fileManager.fileExists(atPath: fileURL.path) {
            _ = try fileManager.replaceItemAt(fileURL, withItemAt: temporaryURL)
        } else {
            try fileManager.moveItem(at: temporaryURL, to: fileURL)
        }
    }
}
