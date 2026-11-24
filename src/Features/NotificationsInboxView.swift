import SwiftUI

struct NotificationsInboxView: View {
    let store: NotificationsStore

    @State private var selection: UUID?
    @State private var query = NotificationQuery()

    var body: some View {
        NotificationsInboxContentView(store: store, selection: $selection, query: $query)
    }
}

struct NotificationsInboxContentView: View {
    let store: NotificationsStore
    @Binding var selection: UUID?
    @Binding var query: NotificationQuery

    @State private var now = Date()
    @State private var isFilterPresented = false

    private var visibleNotifications: [InboxNotification] {
        query.applied(to: store.notifications)
    }

    var body: some View {
        ZStack {
            List(visibleNotifications, id: \.id, selection: $selection) { notification in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(notification.title)
                            .font(notification.type.isEmphasized ? .headline.weight(.bold) : .headline)
                        Spacer(minLength: 8)
                        Text(NotificationRelativeAge.text(from: notification.postedAt, now: now))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(notification.body)
                        .font(.body)
                    HStack(spacing: 8) {
                        Label(
                            notification.type.label,
                            systemImage: notification.type.isEmphasized
                                ? "exclamationmark.triangle.fill"
                                : "info.circle"
                        )
                        .font(notification.type.isEmphasized ? .caption.weight(.semibold) : .caption)
                        .foregroundStyle(
                            notification.type.isEmphasized
                                ? Color(nsColor: .systemOrange)
                                : Color.secondary
                        )
                        Text(notification.source.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
            .onChange(of: selection) { _, identifier in
                guard let identifier else { return }
                store.markRead(id: identifier)
            }

            if visibleNotifications.isEmpty {
                ContentUnavailableView {
                    Label(
                        store.notifications.isEmpty
                            ? "No Notifications"
                            : "No Notifications match this filter",
                        systemImage: "bell"
                    )
                } description: {
                    Text(
                        store.notifications.isEmpty
                            ? "Notifications posted by mini-apps appear here."
                            : "Change the search text or type filter to see other Notifications."
                    )
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isFilterPresented = true
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                }
                .popover(isPresented: $isFilterPresented, arrowEdge: .top) {
                    NotificationsFilterPanel(query: $query)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                ToolbarActionButton(
                    title: "Mark All Read",
                    systemImage: "checkmark.circle",
                    action: store.markAllRead,
                    isDisabled: store.unreadCount == 0
                )
            }
        }
        .frame(minWidth: 420, minHeight: 360)
    }
}

struct NotificationsFilterPanel: View {
    @Binding var query: NotificationQuery

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Filter by name or description", text: $query.searchText)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Filter by name or description")
            VStack(alignment: .leading, spacing: 6) {
                ForEach(NotificationFilter.allCases) { filter in
                    Button {
                        selectType(filter)
                    } label: {
                        Label(
                            filter.label,
                            systemImage: query.type == filter ? "checkmark.circle.fill" : "circle"
                        )
                    }
                    .buttonStyle(.borderless)
                }
            }
            .accessibilityLabel("Notification type filter")
        }
        .frame(width: 280)
        .padding(12)
    }

    private func selectType(_ filter: NotificationFilter) {
        query.type = filter
    }
}
