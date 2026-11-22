import AppKit
import Carbon.HIToolbox

@MainActor
final class HotkeyManager {
    struct Shortcut {
        let keyCode: UInt32
        let modifiers: UInt32

        static let showWindow = Shortcut(
            keyCode: UInt32(kVK_Space),
            modifiers: UInt32(cmdKey | optionKey)
        )
    }

    static let shared = HotkeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    private init() {}

    func register(_ shortcut: Shortcut = .showWindow, handler: @escaping @MainActor () -> Void) {
        if hotKeyRef != nil {
            unregister()
        }

        activeHandler = handler

        if handlerRef == nil {
            var eventType = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )
            let status = InstallEventHandler(
                GetApplicationEventTarget(),
                hotKeyEventHandler,
                1,
                &eventType,
                nil,
                &handlerRef
            )
            guard status == noErr else { return }
        }

        let id = EventHotKeyID(signature: OSType(0x4D41_434F), id: 1)
        RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            id,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        self.hotKeyRef = nil
        activeHandler = nil

        if let handlerRef {
            RemoveEventHandler(handlerRef)
        }
        self.handlerRef = nil
    }
}

// Carbon delivers hotkeys through a C callback, so the handler is bridged through process-global state.
nonisolated(unsafe) private var activeHandler: (@MainActor () -> Void)?

nonisolated private func hotKeyEventHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let activeHandler else { return noErr }
    Task { @MainActor in activeHandler() }
    return noErr
}
