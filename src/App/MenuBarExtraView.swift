import AppKit
import SwiftUI
import UserNotifications

@MainActor
final class MenuBarAppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, UNUserNotificationCenterDelegate {
    let store = TodosStore()
    let todosSettingsStore = TodosSettingsStore()
    let dueCheckStateStore = TodosDueCheckStateStore()
    let miniAppSelectionStore = MiniAppSelectionStore()

    private static let menuWidth = MenuBarTodoRowView.menuWidth

    private var statusItem: NSStatusItem?
    private var menu: NSMenu?
    private var openMainWindowHandler: ((String) -> Void)?
    private var openSettings: OpenSettingsAction?
    private var clockTimer: Timer?
    private var openWindowObserver: NSObjectProtocol?
    private var shouldEnterFullScreenOnNextOpen = true
    private var currentItems: [Todo] = []
    private var currentAdditionalCount = 0
    private lazy var dueNotificationCoordinator = TodosDueNotificationCoordinator(
        todosStore: store,
        settingsStore: todosSettingsStore,
        stateStore: dueCheckStateStore,
        notificationCenter: SystemTodoDueNotificationCenter(),
        schedule: TimerTodoDueNotificationScheduler.schedule
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
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
        Task { @MainActor in await dueNotificationCoordinator.start() }
    }

    func handleNotificationResponse(actionIdentifier: String) {
        guard actionIdentifier == UNNotificationDefaultActionIdentifier else { return }
        openMainWindow()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping @Sendable () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        let completion = completionHandler
        Task { @MainActor in
            self.handleNotificationResponse(actionIdentifier: actionIdentifier)
            completion()
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopClock()
    }

    func registerOpenMainWindowHandler(_ handler: @escaping (String) -> Void) {
        openMainWindowHandler = handler
    }

    func registerOpenSettings(_ action: OpenSettingsAction) {
        openSettings = action
    }

    func consumeFullScreenRequest() -> Bool {
        defer { shouldEnterFullScreenOnNextOpen = false }
        return shouldEnterFullScreenOnNextOpen
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

    @objc nonisolated private func showSettingsAction() {
        Task { @MainActor in
            NSApp.activate(ignoringOtherApps: true)
            self.openSettings?()
        }
    }

    @objc nonisolated private func showAboutAction() {
        Task { @MainActor in NSApp.orderFrontStandardAboutPanel(nil) }
    }

    @objc nonisolated private func quitAction() {
        Task { @MainActor in NSApp.terminate(nil) }
    }

    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if !NSApp.windows.contains(where: { $0.identifier == .mainWindow }) {
            shouldEnterFullScreenOnNextOpen = true
        }
        openMainWindowHandler?("main")
    }

    private func rebuildMenu(_ menu: NSMenu) {
        let now = Date()
        let overview = TodosOverview.make(from: store.todos, categories: store.categories, now: now)

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
            keyEquivalent: " "
        )
        openItem.target = self
        openItem.keyEquivalentModifierMask = [.command, .option]
        menu.addItem(openItem)

        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(showSettingsAction),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        let aboutItem = NSMenuItem(
            title: "About PedryApps",
            action: #selector(showAboutAction),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit PedryApps",
            action: #selector(quitAction),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
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
        let overview = TodosOverview.make(from: store.todos, categories: store.categories, now: now)

        guard overview.items == currentItems, overview.additionalCount == currentAdditionalCount else {
            rebuildMenu(menu)
            return
        }

        for item in menu.items {
            (item.view as? MenuBarTodoRowView)?.update(now: now)
        }
    }
}
