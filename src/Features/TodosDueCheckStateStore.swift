import Foundation

@MainActor
protocol TodosDueCheckStoring {
    var lastReviewedBoundary: Date? { get }
    func markReviewed(_ boundary: Date)
}

@MainActor
final class TodosDueCheckStateStore: TodosDueCheckStoring {
    private(set) var lastReviewedBoundary: Date?

    private let documentStore: JSONDocumentStore<TodosDueCheckState>?

    init(documentStore: JSONDocumentStore<TodosDueCheckState>? = nil) {
        if let documentStore {
            self.documentStore = documentStore
        } else {
            self.documentStore = try? JSONDocumentStore(filename: "todos-due-check-state.json")
        }
        if let documentStore = self.documentStore, let state = try? documentStore.load() {
            lastReviewedBoundary = state.lastReviewedBoundary
        } else {
            lastReviewedBoundary = nil
        }
    }

    func markReviewed(_ boundary: Date) {
        guard boundary > (lastReviewedBoundary ?? .distantPast) else { return }
        let previous = lastReviewedBoundary
        lastReviewedBoundary = boundary
        do {
            try documentStore?.save(TodosDueCheckState(lastReviewedBoundary: boundary))
        } catch {
            lastReviewedBoundary = previous
        }
    }
}
