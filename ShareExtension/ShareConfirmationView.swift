import SwiftUI

struct ShareConfirmationView: View {
  let model: ShareModel

  var body: some View {
    ZStack {
      Color.black.opacity(0.2).ignoresSafeArea()

      VStack(spacing: 12) {
        switch model.state {
        case .saving:
          ProgressView()
            .controlSize(.large)
          Text("Saving…")
            .font(.headline)

        case .saved(let link):
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 44))
            .foregroundStyle(.green)
          Text("Saved to ShareBank")
            .font(.headline)
          Text(link.displayTitle)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .multilineTextAlignment(.center)

        case .failed(let message):
          Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 44))
            .foregroundStyle(.orange)
          Text("Couldn’t Save Link")
            .font(.headline)
          Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
      }
      .padding(24)
      .frame(maxWidth: 300)
      .background(.regularMaterial, in: .rect(cornerRadius: 20))
      .shadow(radius: 20)
      .animation(.default, value: isSaving)
    }
  }

  private var isSaving: Bool {
    if case .saving = model.state { return true }
    return false
  }
}
