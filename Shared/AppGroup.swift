import Foundation

/// Identifiers and locations shared by the app and its share extension.
enum AppGroup {
  static let identifier = "group.com.innodroid.ShareBank"

  /// The App Group container, or `nil` when the entitlement is unavailable (previews, tests).
  static var containerURL: URL? {
    FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
  }

  /// The SQLite file both processes read and write.
  static var databaseURL: URL? {
    containerURL?.appending(path: "sharebank.sqlite")
  }

  static var userDefaults: UserDefaults {
    UserDefaults(suiteName: identifier) ?? .standard
  }
}
