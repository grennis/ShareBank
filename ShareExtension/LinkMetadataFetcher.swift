import Foundation
import LinkPresentation
import UIKit
import UniformTypeIdentifiers

struct FetchedLinkMetadata {
  var title: String?
  var thumbnailData: Data?
}

@MainActor
enum LinkMetadataFetcher {
  static func fetch(for url: URL) async -> FetchedLinkMetadata? {
    let provider = LPMetadataProvider()
    provider.timeout = 6

    guard let metadata = try? await provider.startFetchingMetadata(for: url) else { return nil }

    let title = metadata.title?
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .nilIfEmpty
    let imageData = await loadImageData(from: metadata.imageProvider ?? metadata.iconProvider)

    return FetchedLinkMetadata(
      title: title,
      thumbnailData: imageData.flatMap(UIImage.init(data:)).flatMap(makeThumbnailData)
    )
  }

  private static func loadImageData(from provider: NSItemProvider?) async -> Data? {
    guard
      let provider,
      let typeIdentifier = provider.registeredTypeIdentifiers.first(where: {
        UTType($0)?.conforms(to: .image) == true
      })
    else { return nil }

    return await withCheckedContinuation { continuation in
      provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, _ in
        continuation.resume(returning: data)
      }
    }
  }

  private static func makeThumbnailData(from image: UIImage) -> Data? {
    let maximumDimension: CGFloat = 180
    let longestSide = max(image.size.width, image.size.height)
    guard longestSide > 0 else { return nil }

    let scale = min(1, maximumDimension / longestSide)
    let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let thumbnail = UIGraphicsImageRenderer(size: size, format: format).image { _ in
      image.draw(in: CGRect(origin: .zero, size: size))
    }
    return thumbnail.pngData()
  }
}

private extension String {
  var nilIfEmpty: String? {
    isEmpty ? nil : self
  }
}
