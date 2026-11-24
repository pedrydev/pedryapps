import AppKit
import SwiftUI
import Testing

@testable import PedryApps

@Suite(.serialized)
@MainActor
struct NotificationsInboxViewTests {
    @Test(
        "Selecting a Notification marks it read regardless of type",
        arguments: [NotificationType.information, .attentionRequest]
    )
    func selectingNotificationMarksItRead(type: NotificationType) async throws {
        let directory = try TemporaryDirectory()
        let store = NotificationsStore(
            documentStore: JSONDocumentStore(directory: directory.url, filename: "notifications.json")
        )
        store.post(source: .todos, type: type, title: "Notification", body: "Body")
        let identifier = try #require(store.notifications.first?.id)
        let rootView = NSHostingView(rootView: SelectionHarness(store: store, identifier: identifier))
        rootView.layoutSubtreeIfNeeded()

        let button = try #require(allButtons(in: rootView).last)
        button.performClick(nil)
        try await Task.sleep(for: .milliseconds(100))

        #expect(store.notifications.first?.isRead == true)
        #expect(store.unreadCount == 0)
    }

    @Test func inboxFilterPanelStartsAtAllAndSurvivesNewNotificationsWhileOpen() async throws {
        let directory = try TemporaryDirectory()
        let store = NotificationsStore(
            documentStore: JSONDocumentStore(directory: directory.url, filename: "notifications.json")
        )
        store.post(source: .todos, type: .information, title: "Information", body: "Body")
        store.post(source: .todos, type: .attentionRequest, title: "Attention", body: "Body")
        let (window, rootView) = makeWindow(rootView: FilterHarness(store: store))
        defer { window.close() }
        rootView.layoutSubtreeIfNeeded()

        let searchField = try #require(firstTextField(in: rootView))
        #expect(searchField.placeholderString == "Filter by name or description")
        let typeButtons = allButtons(in: rootView)
        #expect(typeButtons.count == 3)
        #expect(visibleRowCount(in: rootView) == 2)

        typeButtons[1].performClick(self)
        try await Task.sleep(for: .milliseconds(100))
        #expect(visibleRowCount(in: rootView) == 1)

        store.post(source: .todos, type: .attentionRequest, title: "New attention", body: "Body")
        try await Task.sleep(for: .milliseconds(100))
        #expect(visibleRowCount(in: rootView) == 1)

        typeButtons[2].performClick(self)
        try await Task.sleep(for: .milliseconds(100))
        #expect(visibleRowCount(in: rootView) == 2)
        #expect(store.notifications.count == 3)
        #expect(store.unreadCount == 3)
    }

    @Test func toolbarActionButtonMarksEveryNotificationReadAndCanBeDisabled() async throws {
        let directory = try TemporaryDirectory()
        let store = NotificationsStore(
            documentStore: JSONDocumentStore(directory: directory.url, filename: "notifications.json")
        )
        store.post(source: .todos, type: .information, title: "Information", body: "Body")
        store.post(source: .todos, type: .attentionRequest, title: "Attention", body: "Body")
        let (window, rootView) = makeWindow(
            rootView: VStack {
                ToolbarActionButton(
                    title: "Mark All Read",
                    systemImage: "checkmark.circle",
                    action: store.markAllRead
                )
                .buttonStyle(.borderless)
                ToolbarActionButton(
                    title: "Mark All Read",
                    systemImage: "checkmark.circle",
                    action: {},
                    isDisabled: true
                )
                .buttonStyle(.borderless)
            }
        )
        defer { window.close() }
        rootView.layoutSubtreeIfNeeded()

        let buttons = allButtons(in: rootView)
        #expect(buttons.count == 2)
        #expect(buttons[1].isEnabled == false)
        buttons[0].performClick(nil)
        try await Task.sleep(for: .milliseconds(100))

        #expect(store.notifications.allSatisfy { $0.isRead })
        #expect(store.unreadCount == 0)
    }

    private func allButtons(in view: NSView) -> [NSButton] {
        let direct = (view as? NSButton).map { [$0] } ?? []
        return direct + view.subviews.flatMap { allButtons(in: $0) }
    }

    private func firstTextField(in view: NSView) -> NSTextField? {
        if let field = view as? NSTextField { return field }
        for subview in view.subviews {
            if let field = firstTextField(in: subview) { return field }
        }
        return nil
    }

    private func visibleRowCount(in view: NSView) -> Int {
        if String(describing: type(of: view)).contains("ListTableRowView") { return 1 }
        return view.subviews.map(visibleRowCount(in:)).reduce(0, +)
    }

    private func makeWindow<Content: View>(rootView: Content) -> (NSWindow, NSView) {
        let hostingView = NSHostingView(rootView: rootView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.makeKey()
        return (window, hostingView)
    }
}

private struct FilterHarness: View {
    let store: NotificationsStore
    @State private var selection: UUID?
    @State private var query = NotificationQuery()

    var body: some View {
        NotificationsInboxContentView(store: store, selection: $selection, query: $query)
        NotificationsFilterPanel(query: $query)
            .frame(width: 280)
    }
}

private struct SelectionHarness: View {
    let store: NotificationsStore
    let identifier: UUID
    @State private var selection: UUID?
    @State private var query = NotificationQuery()

    var body: some View {
        NotificationsInboxContentView(store: store, selection: $selection, query: $query)
        Button("Select Notification", action: selectNotification)
            .buttonStyle(.borderless)
    }

    private func selectNotification() {
        selection = identifier
    }
}
