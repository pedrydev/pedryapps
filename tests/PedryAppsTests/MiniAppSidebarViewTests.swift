import AppKit
import SwiftUI
import Testing

@testable import PedryApps

@MainActor
struct MiniAppSidebarViewTests {
    @Test func focusFollowsSelection() async throws {
        var selection: MiniApp = .todos
        let hostingView = NSHostingView(
            rootView: MiniAppSidebarView(
                selection: Binding(
                    get: { selection },
                    set: { selection = $0 }
                )))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 56, height: 300),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        defer { window.close() }
        window.contentView = hostingView
        window.makeKey()
        hostingView.layoutSubtreeIfNeeded()

        let buttons = hostingView.subviews.compactMap { $0 as? NSButton }
        #expect(buttons.count == MiniApp.allCases.count)

        buttons[0].performClick(nil)
        try await Task.sleep(for: .milliseconds(100))
        #expect(window.firstResponder === buttons[0])

        buttons[1].performClick(nil)
        try await Task.sleep(for: .milliseconds(100))
        #expect(window.firstResponder === buttons[1])
        #expect(selection == .notifications)
    }
}
