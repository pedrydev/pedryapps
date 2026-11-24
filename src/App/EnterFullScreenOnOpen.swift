import AppKit
import SwiftUI

extension NSUserInterfaceItemIdentifier {
    static let mainWindow = NSUserInterfaceItemIdentifier("MainWindow")
}

struct EnterFullScreenOnOpen: NSViewRepresentable {
    let shouldEnterFullScreen: @MainActor () -> Bool

    func makeNSView(context: Context) -> NSView {
        FullScreenTriggerView(shouldEnterFullScreen: shouldEnterFullScreen)
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class FullScreenTriggerView: NSView {
        private let shouldEnterFullScreen: @MainActor () -> Bool

        init(shouldEnterFullScreen: @escaping @MainActor () -> Bool) {
            self.shouldEnterFullScreen = shouldEnterFullScreen
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            window.identifier = .mainWindow
            guard shouldEnterFullScreen(), !window.styleMask.contains(.fullScreen) else { return }
            DispatchQueue.main.async { [weak window] in
                guard let window, !window.styleMask.contains(.fullScreen) else { return }
                window.makeKeyAndOrderFront(nil)
                window.collectionBehavior.insert(.fullScreenPrimary)
                window.toggleFullScreen(nil)
            }
        }
    }
}
