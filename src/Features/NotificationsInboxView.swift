import SwiftUI

struct NotificationsInboxView: View {
    let store: NotificationsStore

    @State private var now = Date()

    var body: some View {
        List(store.notifications) { notification in
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(notification.title)
                        .font(.headline)
                    Spacer(minLength: 8)
                    Text(NotificationRelativeAge.text(from: notification.postedAt, now: now))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(notification.body)
                    .font(.body)
                Text(notification.source.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
            .help(notification.postedAt.formatted(date: .abbreviated, time: .shortened))
            .accessibilityElement(children: .combine)
        }
        .task {
            for await _ in Timer.publish(every: 60, on: .main, in: .common).autoconnect().values {
                now = Date()
            }
        }
        .frame(minWidth: 420, minHeight: 360)
        .overlay {
            if store.notifications.isEmpty {
                ContentUnavailableView {
                    Label("No Notifications", systemImage: "bell")
                } description: {
                    Text("Notifications posted by mini-apps appear here.")
                }
            }
        }
    }
}
