import Foundation
import UserNotifications

/// Keeps the app icon badge in sync with the number of unarchived links.
///
/// The badge is written from two processes: the app (on launch, on foreground, and after any
/// archive/unarchive/delete) and the share extension (right after saving a link).
enum BadgeUpdater {
  /// Asks for badge permission once. Without it the badge silently stays at zero.
  static func requestAuthorization() async {
    _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.badge])
  }

  static func refresh() async {
    let count = (try? LinkStore.unarchivedCount()) ?? 0
    await apply(count)
  }

  private static func apply(_ count: Int) async {
    do {
      try await UNUserNotificationCenter.current().setBadgeCount(count)
    } catch {
      // `setBadgeCount` can be rejected in an app-extension process; falling back to a
      // content-free notification is the supported way to move the containing app's badge.
      await deliverBadgeOnlyNotification(count)
    }
  }

  private static func deliverBadgeOnlyNotification(_ count: Int) async {
    let content = UNMutableNotificationContent()
    content.badge = NSNumber(value: count)
    let request = UNNotificationRequest(
      identifier: "sharebank.badge",
      content: content,
      trigger: nil
    )
    try? await UNUserNotificationCenter.current().add(request)
  }
}
