import Dependencies
import IssueReporting
import SQLiteData
import SwiftUI

struct ArchiveView: View {
  @FetchAll(Link.archived.order { $0.archivedAt.desc() }) private var links
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Group {
        if links.isEmpty {
          ContentUnavailableView {
            Label("Nothing Archived", systemImage: "archivebox")
          } description: {
            Text("Links you archive are kept here.")
          }
        } else {
          List {
            ForEach(links) { link in
              LinkRow(
                title: link.displayTitle,
                url: link.url,
                createdAt: link.createdAt,
                thumbnailData: link.thumbnailData
              )
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                  Button(role: .destructive) {
                    delete(link)
                  } label: {
                    Label("Delete", systemImage: "trash")
                  }
                  Button {
                    unarchive(link)
                  } label: {
                    Label("Unarchive", systemImage: "tray.and.arrow.up")
                  }
                  .tint(.blue)
                }
            }
          }
          .listStyle(.plain)
        }
      }
      .navigationTitle("Archive")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
  }

  private func unarchive(_ link: Link) {
    withErrorReporting {
      try LinkStore.unarchive(id: link.id)
    }
    Task { await BadgeUpdater.refresh() }
  }

  private func delete(_ link: Link) {
    withErrorReporting {
      try LinkStore.delete(id: link.id)
    }
    Task { await BadgeUpdater.refresh() }
  }
}
