import Foundation

nonisolated struct TodosDocument: Codable {
    var todos: [Todo] = []
}
