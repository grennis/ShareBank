import Dependencies
import Foundation
import SQLiteData
import Testing

@testable import ShareBank

/// Runs `body` against a freshly migrated in-memory database with deterministic ids and dates.
///
/// `bootstrapDatabase` sees `context == .test` here, so it never touches the App Group container.
private func withTestDatabase<T>(_ body: () throws -> T) throws -> T {
  try withDependencies {
    $0.uuid = .incrementing
    $0.date = .constant(Date(timeIntervalSince1970: 1_700_000_000))
    try $0.bootstrapDatabase()
  } operation: {
    try body()
  }
}

private let pointFree = URL(string: "https://www.pointfree.co")!
private let apple = URL(string: "https://developer.apple.com")!

@Suite struct LinkStoreTests {
  @Test func savingStoresLink() throws {
    try withTestDatabase {
      let link = try LinkStore.save(url: pointFree, title: "Point-Free")

      #expect(link.url == pointFree)
      #expect(link.title == "Point-Free")
      #expect(link.archivedAt == nil)
      #expect(try LinkStore.unarchivedCount() == 1)
    }
  }

  @Test func savingSameURLTwiceDoesNotDuplicate() throws {
    try withTestDatabase {
      let first = try LinkStore.save(url: pointFree)
      let second = try LinkStore.save(url: pointFree, title: "Point-Free")

      #expect(first.id == second.id)
      #expect(second.title == "Point-Free")
      #expect(try LinkStore.unarchivedCount() == 1)
    }
  }

  @Test func archivingRemovesLinkFromActiveCount() throws {
    try withTestDatabase {
      @Dependency(\.defaultDatabase) var database
      let link = try LinkStore.save(url: pointFree)
      try LinkStore.save(url: apple)

      try LinkStore.archive(id: link.id)

      #expect(try LinkStore.unarchivedCount() == 1)
      let archived = try database.read { try Link.archived.fetchAll($0) }
      #expect(archived.map(\.id) == [link.id])
    }
  }

  @Test func unarchivingRestoresLink() throws {
    try withTestDatabase {
      @Dependency(\.defaultDatabase) var database
      let link = try LinkStore.save(url: pointFree)
      try LinkStore.archive(id: link.id)

      try LinkStore.unarchive(id: link.id)

      #expect(try LinkStore.unarchivedCount() == 1)
      #expect(try database.read { try Link.archived.fetchCount($0) } == 0)
    }
  }

  @Test func archivedURLCanBeSavedAgainAsNewLink() throws {
    try withTestDatabase {
      @Dependency(\.defaultDatabase) var database
      let first = try LinkStore.save(url: pointFree)
      try LinkStore.archive(id: first.id)

      let second = try LinkStore.save(url: pointFree)

      #expect(first.id != second.id)
      #expect(try LinkStore.unarchivedCount() == 1)
      #expect(try database.read { try Link.all.fetchCount($0) } == 2)
    }
  }

  @Test func deletingRemovesLink() throws {
    try withTestDatabase {
      @Dependency(\.defaultDatabase) var database
      let link = try LinkStore.save(url: pointFree)

      try LinkStore.delete(id: link.id)

      #expect(try database.read { try Link.all.fetchCount($0) } == 0)
    }
  }
}
