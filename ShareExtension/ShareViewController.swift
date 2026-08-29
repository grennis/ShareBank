import Dependencies
import SQLiteData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Principal class of the share extension. Accepts a single web URL, stores it in the shared
/// SQLite database, updates the app icon badge, and briefly confirms before dismissing.
@MainActor
final class ShareViewController: UIViewController {
  private let model = ShareModel()

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .clear

    let host = UIHostingController(rootView: ShareConfirmationView(model: model))
    host.view.backgroundColor = .clear
    addChild(host)
    host.view.frame = view.bounds
    host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(host.view)
    host.didMove(toParent: self)

    prepareDependencies {
      try? $0.bootstrapDatabase()
    }

    Task { await handleSharedItem() }
  }

  private func handleSharedItem() async {
    guard let sharedLink = await extractLink() else {
      model.state = .failed("ShareBank only accepts links.")
      try? await Task.sleep(for: .seconds(1.6))
      finish()
      return
    }

    do {
      let metadata = await LinkMetadataFetcher.fetch(for: sharedLink.url)
      let link = try LinkStore.save(
        url: sharedLink.url,
        title: metadata?.title ?? sharedLink.title,
        content: sharedLink.content,
        thumbnailData: metadata?.thumbnailData
      )
      model.state = .saved(link)
      @Dependency(\.defaultSyncEngine) var syncEngine
      try? await syncEngine.sendChanges()
      await BadgeUpdater.refresh()
      try? await Task.sleep(for: .seconds(0.8))
    } catch {
      model.state = .failed(error.localizedDescription)
      try? await Task.sleep(for: .seconds(1.6))
    }
    finish()
  }

  private func extractLink() async -> (url: URL, title: String, content: String)? {
    guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { return nil }

    for item in items {
      let title = item.attributedTitle?.string
        .trimmingCharacters(in: .whitespacesAndNewlines)
        ?? ""
      let content = item.attributedContentText?.string
        .trimmingCharacters(in: .whitespacesAndNewlines)
        ?? ""

      for provider in item.attachments ?? [] {
        guard provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) else { continue }
        let loaded = try? await provider.loadItem(
          forTypeIdentifier: UTType.url.identifier,
          options: nil
        )
        if let url = loaded as? URL, url.scheme?.hasPrefix("http") == true {
          return (
            url: url,
            title: title,
            content: content == title || content == url.absoluteString ? "" : content
          )
        }
      }
    }
    return nil
  }

  private func finish() {
    extensionContext?.completeRequest(returningItems: nil)
  }
}
