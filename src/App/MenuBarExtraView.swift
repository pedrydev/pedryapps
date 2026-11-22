import AppKit
import SwiftUI

@MainActor
final class MenuBarAppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let store = TodosStore()

    private static let menuWidth = MenuBarTodoRowView.menuWidth

    private var statusItem: NSStatusItem?
    private var menu: NSMenu?
    private var openWindow: OpenWindowAction?
    private var clockTimer: Timer?
    private var openWindowObserver: NSObjectProtocol?
    private var currentItems: [Todo] = []
    private var currentAdditionalCount = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "PedryApps") {
            image.isTemplate = true
            statusItem.button?.image = image
        }

        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self
        statusItem.menu = menu

        self.statusItem = statusItem
        self.menu = menu
        rebuildMenu(menu)

        openWindowObserver = NotificationCenter.default.addObserver(
            forName: .openMainWindow,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.openMainWindow() }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopClock()
    }

    func registerOpenWindow(_ action: OpenWindowAction) {
        openWindow = action
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        rebuildMenu(menu)
    }

    func menuWillOpen(_ menu: NSMenu) {
        startClock()
    }

    func menuDidClose(_ menu: NSMenu) {
        stopClock()
    }

    @objc nonisolated private func openMainWindowAction() {
        Task { @MainActor in self.openMainWindow() }
    }

    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        openWindow?(id: "main")
    }

    private func rebuildMenu(_ menu: NSMenu) {
        let now = Date()
        let overview = TodosOverview.make(from: store.todos, now: now)

        menu.removeAllItems()
        currentItems = overview.items
        currentAdditionalCount = overview.additionalCount

        menu.addItem(
            textItem(
                "Today (\(overview.items.count))",
                font: .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
            )
        )

        if overview.items.isEmpty {
            menu.addItem(
                textItem(
                    "Nothing upcoming today",
                    font: .systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
                )
            )
        } else {
            for todo in overview.items {
                let view = MenuBarTodoRowView(dueDate: todo.doOnDate.date, title: todo.title)
                view.update(now: now)
                let item = NSMenuItem()
                item.view = view
                item.isEnabled = false
                menu.addItem(item)
            }

            if overview.additionalCount > 0 {
                menu.addItem(
                    textItem(
                        "\(overview.additionalCount) more today",
                        font: .systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
                    )
                )
            }
        }

        menu.addItem(.separator())

        let openItem = NSMenuItem(
            title: "Open PedryApps",
            action: #selector(openMainWindowAction),
            keyEquivalent: ""
        )
        openItem.target = self
        menu.addItem(openItem)
    }

    private func textItem(_ title: String, font: NSFont) -> NSMenuItem {
        let textField = NSTextField(labelWithString: title)
        textField.font = font
        textField.textColor = .controlTextColor
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.lineBreakMode = .byWordWrapping
        textField.maximumNumberOfLines = 0
        textField.cell?.wraps = true
        textField.cell?.isScrollable = false

        let height = ceil(
            textField
                .sizeThatFits(
                    NSSize(width: MenuBarTodoRowView.contentWidth, height: .greatestFiniteMagnitude)
                )
                .height
        )
        textField.frame = NSRect(
            x: MenuBarTodoRowView.horizontalInset,
            y: MenuBarTodoRowView.verticalPadding,
            width: MenuBarTodoRowView.contentWidth,
            height: height
        )

        let view = NSView(
            frame: NSRect(
                x: 0,
                y: 0,
                width: Self.menuWidth,
                height: height + MenuBarTodoRowView.verticalPadding * 2
            )
        )
        view.addSubview(textField)

        let item = NSMenuItem()
        item.view = view
        item.isEnabled = false
        return item
    }

    private func startClock() {
        stopClock()
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.current.add(timer, forMode: .eventTracking)
        clockTimer = timer
    }

    private func stopClock() {
        clockTimer?.invalidate()
        clockTimer = nil
    }

    private func tick() {
        guard let menu else { return }
        let now = Date()
        let overview = TodosOverview.make(from: store.todos, now: now)

        guard overview.items == currentItems, overview.additionalCount == currentAdditionalCount else {
            rebuildMenu(menu)
            return
        }

        for item in menu.items {
            (item.view as? MenuBarTodoRowView)?.update(now: now)
        }
    }
}

extension Notification.Name {
    static let openMainWindow = Notification.Name("openMainWindow")
}
