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

    @Test func markAllReadButtonMarksEveryNotificationRead() async throws {
        let directory = try TemporaryDirectory()
        let store = NotificationsStore(
            documentStore: JSONDocumentStore(directory: directory.url, filename: "notifications.json")
        )
        store.post(source: .todos, type: .information, title: "Information", body: "Body")
        store.post(source: .todos, type: .attentionRequest, title: "Attention", body: "Body")
        let (window, rootView) = makeWindow(rootView: MarkAllReadButton(store: store))
        defer { window.close() }
        rootView.layoutSubtreeIfNeeded()

        let button = try #require(allButtons(in: rootView).first)
        button.performClick(nil)
        try await Task.sleep(for: .milliseconds(100))

        #expect(store.notifications.allSatisfy { $0.isRead })
        #expect(store.unreadCount == 0)
    }

    private func allButtons(in view: NSView) -> [NSButton] {
        let direct = (view as? NSButton).map { [$0] } ?? []
        return direct + view.subviews.flatMap { allButtons(in: $0) }
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

private struct SelectionHarness: View {
    let store: NotificationsStore
    let identifier: UUID
    @State private var selection: UUID?

    var body: some View {
        NotificationsInboxContentView(store: store, selection: $selection)
        Button("Select Notification", action: selectNotification)
            .buttonStyle(.borderless)
    }

    private func selectNotification() {
        selection = identifier
    }
}
