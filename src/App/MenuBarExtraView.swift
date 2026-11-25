import AppKit
import Observation
import SwiftUI
import UserNotifications

@MainActor
final class MenuBarAppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, UNUserNotificationCenterDelegate {
    let store = TodosStore()
    let todosSettingsStore = TodosSettingsStore()
    let mcpSettingsStore: MCPSettingsStore
    let dueCheckStateStore = TodosDueCheckStateStore()
    let notificationsStore: NotificationsStore
    let miniAppSelectionStore: MiniAppSelectionStore

    lazy var diagnosticsProbeStore = DiagnosticsProbeStore { [store] in
        TodosProbedComponentAdapter(store: store).probedComponent
    }

    private static let menuWidth = MenuBarTodoRowView.menuWidth

    private let injectedMCPServerController: (any MCPServerControlling)?

    override init() {
        mcpSettingsStore = MCPSettingsStore()
        injectedMCPServerController = nil
        notificationsStore = NotificationsStore()
        miniAppSelectionStore = MiniAppSelectionStore()
        super.init()
    }

    init(
        selectionStore: MiniAppSelectionStore,
        notificationsStore: NotificationsStore,
        mcpSettingsStore: MCPSettingsStore = MCPSettingsStore(),
        mcpServerController: (any MCPServerControlling)? = nil
    ) {
        self.notificationsStore = notificationsStore
        self.miniAppSelectionStore = selectionStore
        self.mcpSettingsStore = mcpSettingsStore
        injectedMCPServerController = mcpServerController
        super.init()
    }

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
        alertPoster: systemAlertPoster,
        notificationPoster: notificationsStore,
        schedule: TimerTodoDueNotificationScheduler.schedule
    )
    private lazy var systemAlertCenter = SystemUserNotificationCenter()
    private lazy var systemAlertPoster = SystemAlertPoster(center: systemAlertCenter)
    private lazy var defaultMCPServerController = MCPServerController(
        posting: MCPNotificationPosting(store: notificationsStore, alertPoster: systemAlertPoster)
    )
    private var mcpServerController: any MCPServerControlling {
        injectedMCPServerController ?? defaultMCPServerController
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "PedryApps") {
            image.isTemplate = true
            statusItem.button?.image = image
        }
        statusItem.button?.setAccessibilityLabel("PedryApps")

        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self
        statusItem.menu = menu

        self.statusItem = statusItem
        self.menu = menu
        notificationsStore.startExpiryScheduling()
        rebuildMenu(menu)
        observeNotificationsStore()
        installMCPPortChangeHandler()

        openWindowObserver = NotificationCenter.default.addObserver(
            forName: .openMainWindow,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.openMainWindow() }
        }
        Task { @MainActor in
            await dueNotificationCoordinator.start()
            await mcpServerController.start(port: mcpSettingsStore.settings.port)
        }
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
        mcpServerController.stop()
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

    @objc nonisolated private func openNotificationsAction() {
        Task { @MainActor in self.openNotificationsFromMenuBar() }
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

    func openNotificationsFromMenuBar() {
        miniAppSelectionStore.select(.notifications)
        openMainWindow()
    }

    private func rebuildMenu(_ menu: NSMenu) {
        let now = Date()
        let todosOverview = TodosOverview.make(from: store.todos, categories: store.categories, now: now)
        let notificationsOverview = MenuBarNotificationsOverview.make(
            from: notificationsStore.notifications,
            now: now
        )

        menu.removeAllItems()
        currentItems = todosOverview.items
        currentAdditionalCount = todosOverview.additionalCount
        updateBadge(notificationsOverview.unreadCount)
        addNotificationsSection(to: menu, overview: notificationsOverview)

        menu.addItem(
            textItem(
                "Today (\(todosOverview.items.count))",
                font: .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
            )
        )

        if todosOverview.items.isEmpty {
            menu.addItem(
                textItem(
                    "Nothing upcoming today",
                    font: .systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
                )
            )
        } else {
            for todo in todosOverview.items {
                let view = MenuBarTodoRowView(dueDate: todo.doOnDate.date, title: todo.title)
                view.update(now: now)
                let item = NSMenuItem()
                item.view = view
                item.isEnabled = false
                menu.addItem(item)
            }

            if todosOverview.additionalCount > 0 {
                menu.addItem(
                    textItem(
                        "\(todosOverview.additionalCount) more today",
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

    private func addNotificationsSection(to menu: NSMenu, overview: MenuBarNotificationsOverview) {
        menu.addItem(
            textItem(
                "Notifications (\(overview.unreadCount))",
                font: .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
            )
        )

        if overview.unread.isEmpty {
            menu.addItem(
                disabledItem(
                    "No unread notifications",
                    font: .systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
                )
            )
        } else {
            for row in overview.unread {
                let item = NSMenuItem(title: "", action: #selector(openNotificationsAction), keyEquivalent: "")
                item.attributedTitle = notificationTitle(row)
                item.target = self
                menu.addItem(item)
            }
        }

        let showAllItem = NSMenuItem(
            title: "Show All",
            action: #selector(openNotificationsAction),
            keyEquivalent: ""
        )
        showAllItem.target = self
        showAllItem.isEnabled = true
        menu.addItem(showAllItem)
        menu.addItem(.separator())
    }

    private func updateBadge(_ unreadCount: Int) {
        guard let button = statusItem?.button else { return }
        button.attributedTitle =
            MenuBarUnreadBadge.attributedTitle(for: unreadCount) ?? NSAttributedString(string: "")
        button.toolTip = unreadCount > 0 ? "\(unreadCount) unread notifications" : nil
        button.setAccessibilityLabel(
            unreadCount > 0 ? "PedryApps, \(unreadCount) unread notifications" : "PedryApps"
        )
    }

    func installMCPPortChangeHandler() {
        mcpSettingsStore.onPortChange = { [weak self] port in
            guard let self else { return }
            Task { @MainActor in
                await self.mcpServerController.restart(port: port)
            }
        }
    }

    private func observeNotificationsStore() {
        withObservationTracking {
            _ = notificationsStore.notifications
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                if let menu = self.menu {
                    self.rebuildMenu(menu)
                }
                self.observeNotificationsStore()
            }
        }
    }

    private func notificationTitle(_ row: MenuBarNotificationsOverview.Row) -> NSAttributedString {
        let fontSize = NSFont.menuFont(ofSize: 0).pointSize
        let isAttentionRequest = row.type.isEmphasized
        let attributed = NSMutableAttributedString(
            string: row.title,
            attributes: [
                .font: NSFont.systemFont(ofSize: fontSize, weight: isAttentionRequest ? .bold : .medium),
                .foregroundColor: isAttentionRequest ? NSColor.systemOrange : NSColor.controlTextColor,
            ]
        )
        attributed.append(NSAttributedString(string: "\n"))
        attributed.append(
            NSAttributedString(
                string: "\(row.type.label)  ·  ",
                attributes: [
                    .font: NSFont.systemFont(
                        ofSize: fontSize - 2,
                        weight: isAttentionRequest ? .semibold : .regular
                    ),
                    .foregroundColor: isAttentionRequest ? NSColor.systemOrange : NSColor.secondaryLabelColor,
                ]
            )
        )
        attributed.append(
            NSAttributedString(
                string: "\(row.source)  ·  \(row.relativeAge)",
                attributes: [
                    .font: NSFont.systemFont(ofSize: fontSize - 2),
                    .foregroundColor: NSColor.secondaryLabelColor,
                ]
            )
        )
        return attributed
    }

    private func disabledItem(_ title: String, font: NSFont) -> NSMenuItem {
        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        item.attributedTitle = NSAttributedString(
            string: title,
            attributes: [.font: font, .foregroundColor: NSColor.disabledControlTextColor]
        )
        item.isEnabled = false
        return item
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

private struct MenuBarUnreadBadge {
    static func attributedTitle(for count: Int) -> NSAttributedString? {
        guard count > 0 else { return nil }

        let text = "\(count)"
        let font = NSFont.boldSystemFont(ofSize: 10)
        let diameter: CGFloat = 16
        let textWidth = ceil((text as NSString).size(withAttributes: [.font: font]).width)
        let width = max(diameter, textWidth + 8)
        let image = NSImage(size: NSSize(width: width, height: diameter), flipped: false) { rect in
            NSColor.systemRed.setFill()
            NSBezierPath(roundedRect: rect, xRadius: diameter / 2, yRadius: diameter / 2).fill()
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            (text as NSString).draw(
                in: rect,
                withAttributes: [.font: font, .foregroundColor: NSColor.white, .paragraphStyle: style]
            )
            return true
        }

        let attachment = NSTextAttachment()
        attachment.image = image
        let overlap: CGFloat = 6
        attachment.bounds = NSRect(x: -overlap, y: -3, width: width - overlap, height: diameter)
        let attributed = NSMutableAttributedString(attachment: attachment)
        attributed.addAttribute(
            .baselineOffset,
            value: 1,
            range: NSRange(location: 0, length: attributed.length)
        )
        return attributed
    }
}
