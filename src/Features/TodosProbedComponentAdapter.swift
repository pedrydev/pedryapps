struct TodosProbedComponentAdapter {
    let store: TodosStore

    var probedComponent: ProbedComponent {
        ProbedComponent(
            id: "todos",
            name: "Todos",
            healthState: store.errorMessage == nil ? .healthy : .unhealthy
        )
    }
}
