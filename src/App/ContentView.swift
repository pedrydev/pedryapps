import SwiftUI

struct ContentView: View {
    let store: TodosStore
    let shouldEnterFullScreen: @MainActor () -> Bool

    var body: some View {
        TodosView(store: store)
            .background {
                EnterFullScreenOnOpen(shouldEnterFullScreen: shouldEnterFullScreen)
            }
    }
}
