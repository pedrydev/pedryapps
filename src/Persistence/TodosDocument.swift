import Foundation

nonisolated struct TodosDocument: Codable {
    var categories: [Category] = []
    var todos: [Todo] = []
}
