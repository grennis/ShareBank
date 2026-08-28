import SwiftUI

struct LinkRow: View {
  let link: Link

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(link.displayTitle)
        .font(.headline)
        .lineLimit(2)
      Text(link.url.absoluteString)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
      Text(link.createdAt, format: .relative(presentation: .named))
        .font(.caption2)
        .foregroundStyle(.tertiary)
    }
    .padding(.vertical, 4)
    .contentShape(.rect)
  }
}
