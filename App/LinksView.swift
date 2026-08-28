import CasePaths
import Dependencies
import IssueReporting
import SQLiteData
import Sharing
import SwiftUI
import SwiftUINavigation

struct LinksView: View {
  @CasePathable
  enum Destination: Hashable {
    case archive
  }

  @FetchAll(Link.active.order { $0.createdAt.desc() }) private var links
  @State private var destination: Destination?
  @Environment(\.scenePhase) private var scenePhase

  @Shared(.appStorage("didRequestBadgeAuthorization", store: AppGroup.userDefaults))
  private var didRequestBadgeAuthorization = false

  var body: some View {
    NavigationStack {
      Group {
        if links.isEmpty {
          emptyState
        } else {
          list
        }
      }
      .navigationTitle("ShareBank")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            destination = .archive
          } label: {
            Label("Archive", systemImage: "archivebox")
          }
        }
      }
    }
    .sheet(isPresented: Binding($destination.archive)) {
      ArchiveView()
    }
    .task(id: scenePhase) {
      guard scenePhase == .active else { return }
      await requestBadgeAuthorizationIfNeeded()
      // Links saved by the share extension land in the database from another process, which
      // GRDB's observation cannot see, so re-run the query whenever the app comes forward.
      await reload()
      await BadgeUpdater.refresh()
    }
  }

  private var list: some View {
    List {
      ForEach(links) { link in
        // `ShareLink` opens the system share sheet straight from the row tap.
        ShareLink(item: link.url) {
          LinkRow(link: link)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
          Button {
            archive(link)
          } label: {
            Label("Archive", systemImage: "archivebox")
          }
          .tint(.orange)
        }
      }
    }
    .listStyle(.plain)
  }

  private var emptyState: some View {
    ContentUnavailableView {
      Label("No Links Yet", systemImage: "link")
    } description: {
      Text("Share a link from any app and choose ShareBank to save it here.")
    }
  }

  private func archive(_ link: Link) {
    withErrorReporting {
      try LinkStore.archive(id: link.id)
    }
    Task { await BadgeUpdater.refresh() }
  }

  private func reload() async {
    await withErrorReporting {
      try await $links.load(
        Link.active.order { $0.createdAt.desc() },
        animation: .default
      )
    }
  }

  private func requestBadgeAuthorizationIfNeeded() async {
    guard !didRequestBadgeAuthorization else { return }
    await BadgeUpdater.requestAuthorization()
    // Recorded only once the prompt has actually been answered, so a dismissed prompt is
    // retried on the next launch.
    $didRequestBadgeAuthorization.withLock { $0 = true }
  }
}

#Preview(
  traits: .dependencies {
    try $0.bootstrapDatabase()
    try $0.defaultDatabase.write { db in
      try db.seed {
        Link(
          id: UUID(),
          url: URL(string: "https://www.pointfree.co")!,
          title: "Point-Free",
          createdAt: Date()
        )
        Link(
          id: UUID(),
          url: URL(string: "https://developer.apple.com/xcode")!,
          title: "Xcode",
          createdAt: Date().addingTimeInterval(-3600)
        )
      }
    }
  }
) {
  LinksView()
}
