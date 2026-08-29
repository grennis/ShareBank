import Dependencies
import Foundation
import SQLiteData

/// All reads and writes of `Link` rows, shared by the app and the share extension.
enum LinkStore {
  enum Failure: Error, LocalizedError {
    case saveFailed

    var errorDescription: String? {
      switch self {
      case .saveFailed: "The link could not be saved."
      }
    }
  }

  /// Saves a link. If the same URL is already waiting (not archived), its timestamp is refreshed
  /// instead of storing a duplicate.
  @discardableResult
  static func save(
    url: URL,
    title: String = "",
    content: String = "",
    thumbnailData: Data? = nil
  ) throws -> Link {
    @Dependency(\.defaultDatabase) var database
    @Dependency(\.date.now) var now
    @Dependency(\.uuid) var uuid

    return try database.write { db in
      let existing = try Link
        .where { $0.url.eq(url) && $0.archivedAt.is(nil) }
        .fetchOne(db)

      let id: Link.ID
      if let existing {
        id = existing.id
        try Link
          .find(id)
          .update {
            $0.createdAt = #bind(now)
            if !title.isEmpty {
              $0.title = #bind(title)
            }
            if !content.isEmpty {
              $0.content = #bind(content)
            }
            if let thumbnailData {
              $0.thumbnailData = #bind(thumbnailData)
            }
          }
          .execute(db)
      } else {
        id = uuid()
        try Link
          .insert {
            Link.Draft(
              id: id,
              url: url,
              title: title,
              content: content,
              thumbnailData: thumbnailData,
              createdAt: now,
              archivedAt: nil
            )
          }
          .execute(db)
      }

      guard let link = try Link.find(id).fetchOne(db) else { throw Failure.saveFailed }
      return link
    }
  }

  static func archive(id: Link.ID) throws {
    @Dependency(\.defaultDatabase) var database
    @Dependency(\.date.now) var now
    try database.write { db in
      try Link.find(id).update { $0.archivedAt = #bind(now) }.execute(db)
    }
  }

  static func unarchive(id: Link.ID) throws {
    @Dependency(\.defaultDatabase) var database
    try database.write { db in
      try Link.find(id).update { $0.archivedAt = #bind(Date?.none) }.execute(db)
    }
  }

  static func delete(id: Link.ID) throws {
    @Dependency(\.defaultDatabase) var database
    try database.write { db in
      try Link.find(id).delete().execute(db)
    }
  }

  /// The number of links still waiting to be read — this is what the app icon badge shows.
  static func unarchivedCount() throws -> Int {
    @Dependency(\.defaultDatabase) var database
    return try database.read { db in
      try Link.where { $0.archivedAt.is(nil) }.fetchCount(db)
    }
  }
}

extension Link {
  /// Links waiting to be read, newest first.
  static var active: Where<Link> {
    Link.where { $0.archivedAt.is(nil) }
  }

  /// Archived links, most recently archived first.
  static var archived: Where<Link> {
    Link.where { $0.archivedAt.isNot(nil) }
  }
}
