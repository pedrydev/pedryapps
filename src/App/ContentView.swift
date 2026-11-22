import SwiftUI

struct ContentView: View {
    let store: TodosStore

    var body: some View {
        TodosView(store: store)
    }
}
