# In-app notifications expire and stay separate from system alerts

Notifications now provide an in-app Inbox whose badge on the existing menu bar item shows unread activity from mini-apps. Notifications are independent of macOS system notifications: Todos keeps delivering its existing system alerts and also posts Information Notifications into the Inbox. A Notification leaves the Inbox six hours after its posted-at time, including on launch before the badge is shown, because a stale unread count is more misleading than a short history. Information and Attention request only highlight importance and support filtering; reading any Notification marks it read and "Mark All Read" clears all of them.

## Consequences

- The Inbox has no history beyond six hours and no migration path for older Notifications.
- Attention request does not imply a separate handled state or workflow.
- System alert delivery and Inbox delivery can diverge without breaking either.
