import AppKit

final class MenuBarTodoRowView: NSView {
    static let menuWidth: CGFloat = 360
    static let horizontalInset: CGFloat = 12
    static let verticalPadding: CGFloat = 4
    static let contentWidth: CGFloat = menuWidth - horizontalInset * 2

    private let dueDate: Date
    private let title: String
    private let textView = NSTextField(frame: .zero)

    init(dueDate: Date, title: String) {
        self.dueDate = dueDate
        self.title = title
        super.init(frame: NSRect(x: 0, y: 0, width: Self.menuWidth, height: 0))

        textView.isBezeled = false
        textView.drawsBackground = false
        textView.isEditable = false
        textView.isSelectable = false
        textView.lineBreakMode = .byWordWrapping
        textView.maximumNumberOfLines = 0
        textView.cell?.wraps = true
        textView.cell?.isScrollable = false
        addSubview(textView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(now: Date) {
        let timeLeft = TimeLeftLabel.text(from: now, to: dueDate)
            .replacingOccurrences(of: " ", with: "\u{00A0}")
        let fontSize = NSFont.menuFont(ofSize: 0).pointSize
        let attributed = NSMutableAttributedString()

        attributed.append(
            NSAttributedString(
                string: timeLeft,
                attributes: [
                    .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold),
                    .foregroundColor: NSColor.controlTextColor,
                ]
            )
        )
        attributed.append(NSAttributedString(string: "\u{00A0}\u{00A0}"))
        attributed.append(
            NSAttributedString(
                string: title,
                attributes: [
                    .font: NSFont.systemFont(ofSize: fontSize, weight: .medium),
                    .foregroundColor: NSColor.controlTextColor,
                ]
            )
        )

        textView.attributedStringValue = attributed
        textView.setAccessibilityLabel("\(timeLeft) \(title)")

        let height = ceil(
            textView
                .sizeThatFits(NSSize(width: Self.contentWidth, height: .greatestFiniteMagnitude))
                .height
        )
        textView.frame = NSRect(
            x: Self.horizontalInset,
            y: Self.verticalPadding,
            width: Self.contentWidth,
            height: height
        )
        frame = NSRect(
            x: frame.minX,
            y: frame.minY,
            width: Self.menuWidth,
            height: height + Self.verticalPadding * 2
        )
    }
}
