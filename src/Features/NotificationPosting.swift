@MainActor
protocol NotificationPosting {
    func post(source: MiniApp, type: NotificationType, title: String, body: String)
}
