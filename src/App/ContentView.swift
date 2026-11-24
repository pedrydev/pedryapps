import SwiftUI

struct ContentView: View {
    let todosStore: TodosStore
    let selectionStore: MiniAppSelectionStore
    let shouldEnterFullScreen: @MainActor () -> Bool

    private var selection: Binding<MiniApp> {
        Binding(
            get: { selectionStore.selected },
            set: { selectionStore.select($0) }
        )
    }

    var body: some View {
        HStack(spacing: 0) {
            MiniAppSidebarView(selection: selection)
            destination
        }
        .background {
            EnterFullScreenOnOpen(shouldEnterFullScreen: shouldEnterFullScreen)
        }
    }

    @ViewBuilder
    private var destination: some View {
        switch selectionStore.selected {
        case .todos:
            TodosView(store: todosStore)
        case .notifications, .calendar:
            EmptyView()
        }
    }
}
