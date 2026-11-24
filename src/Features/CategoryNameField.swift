import AppKit
import SwiftUI

struct CategoryNameField: NSViewRepresentable {
    @Binding var name: String
    let selectsOnAppear: Bool
    let commit: (String) -> Void
    let cancel: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField(string: name)
        field.bezelStyle = .roundedBezel
        field.font = .systemFont(ofSize: NSFont.systemFontSize)
        field.delegate = context.coordinator
        field.target = context.coordinator
        field.action = #selector(Coordinator.commit(_:))
        return field
    }

    func updateNSView(_ field: NSTextField, context: Context) {
        context.coordinator.name = $name
        context.coordinator.commit = commit
        context.coordinator.cancel = cancel
        if field.stringValue != name {
            field.stringValue = name
            context.coordinator.lastCommitted = name
        }
        if selectsOnAppear && !context.coordinator.didSelect {
            context.coordinator.didSelect = true
            DispatchQueue.main.async {
                field.window?.makeFirstResponder(field)
                field.selectText(nil)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(name: $name)
    }

    @MainActor
    final class Coordinator: NSObject, NSTextFieldDelegate {
        var name: Binding<String>
        var commit: ((String) -> Void)?
        var cancel: (() -> Void)?
        var lastCommitted: String
        var didSelect = false

        init(name: Binding<String>) {
            self.name = name
            lastCommitted = name.wrappedValue
        }

        @objc func commit(_ sender: NSTextField) {
            commitField(sender)
        }

        func controlTextDidEndEditing(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            commitField(field)
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            name.wrappedValue = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            guard commandSelector == #selector(NSResponder.cancelOperation(_:)) else { return false }
            lastCommitted = name.wrappedValue
            cancel?()
            return true
        }

        private func commitField(_ field: NSTextField) {
            guard field.stringValue != lastCommitted else { return }
            lastCommitted = field.stringValue
            commit?(field.stringValue)
        }
    }
}
