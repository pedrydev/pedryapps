import SwiftUI

struct ContentView: View {
    @State private var store: TodosStore?
    @State private var setupError: String?

    var body: some View {
        Group {
            if let store {
                TodosView(store: store)
            } else if let setupError {
                ContentUnavailableView {
                    Label("Todos Unavailable", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(setupError)
                }
            }
        }
        .task {
            do {
                store = try TodosStore()
            } catch {
                setupError = error.localizedDescription
            }
        }
    }
}
