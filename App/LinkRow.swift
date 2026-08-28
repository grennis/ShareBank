import SwiftUI
import UIKit

struct LinkRow: View {
  let title: String
  let url: URL
  let createdAt: Date
  let thumbnailData: Data?

  var body: some View {
    HStack(spacing: 12) {
      LinkThumbnail(data: thumbnailData)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.headline)
          .lineLimit(1)
        Text(url.absoluteString)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
        Text(createdAt, format: .relative(presentation: .named))
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }
    }
    .padding(.vertical, 4)
    .contentShape(.rect)
  }
}

private struct LinkThumbnail: View {
  let data: Data?
  @State private var image: UIImage?

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 10)
        .fill(.quaternary)

      if let image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
      } else {
        Image(systemName: "link")
          .font(.title3)
          .foregroundStyle(.secondary)
      }
    }
    .frame(width: 52, height: 52)
    .clipShape(.rect(cornerRadius: 10))
    .task(id: data) {
      image = data.flatMap(UIImage.init(data:))
    }
  }
}
