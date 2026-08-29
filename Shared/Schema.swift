import Dependencies
import Foundation
import OSLog
import SQLiteData

@Table
struct Link: Identifiable, Hashable {
  let id: UUID
  var url: URL
  var title = ""
  var content = ""
  var thumbnailData: Data?
  var createdAt: Date
  var archivedAt: Date?

  var isArchived: Bool { archivedAt != nil }

  /// A short, human-readable label for the link, falling back to the host when no title was
  /// offered by the sharing app.
  var displayTitle: String {
    title.isEmpty ? (url.host() ?? url.absoluteString) : title
  }
}

extension DependencyValues {
  mutating func bootstrapDatabase() throws {
    @Dependency(\.context) var context

    var configuration = Configuration()
    configuration.prepareDatabase { db in
      #if DEBUG
        db.trace(options: .profile) {
          guard !$0.expandedDescription.hasPrefix("--") else { return }
          switch context {
          case .live: logger.debug("\($0.expandedDescription)")
          case .preview: print($0.expandedDescription)
          case .test: break
          }
        }
      #endif
    }

    // Only the live app and extension share the App Group file; previews and tests stay in memory.
    let path = context == .live ? AppGroup.databaseURL?.path : nil
    let database = try SQLiteData.defaultDatabase(path: path, configuration: configuration)

    if let path {
      // The extension may need to write while the device is locked.
      try? FileManager.default.setAttributes(
        [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
        ofItemAtPath: path
      )
    }

    var migrator = DatabaseMigrator()
    #if DEBUG
      migrator.eraseDatabaseOnSchemaChange = true
    #endif
    migrator.registerMigration("Create 'links' table") { db in
      try #sql(
        """
        CREATE TABLE "links" (
          "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
          "url" TEXT NOT NULL,
          "title" TEXT NOT NULL DEFAULT '',
          "content" TEXT NOT NULL DEFAULT '',
          "thumbnailData" BLOB,
          "createdAt" TEXT NOT NULL,
          "archivedAt" TEXT
        ) STRICT
        """
      )
      .execute(db)

      try #sql(
        """
        CREATE INDEX "index_links_on_archivedAt" ON "links"("archivedAt")
        """
      )
      .execute(db)
    }
    try migrator.migrate(database)

    defaultDatabase = database

    // CloudKit is only reachable from a real app process; previews and tests stay local.
    if context == .live {
      defaultSyncEngine = try SyncEngine(
        for: database,
        tables: Link.self,
        containerIdentifier: AppGroup.cloudKitContainerIdentifier
      )
    }
  }
}

private let logger = Logger(subsystem: "com.innodroid.ShareBank", category: "Database")
