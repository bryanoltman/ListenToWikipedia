import SwiftUI

/// Toast shown at the bottom of the screen when the user taps a bubble.
struct ArticleToastView: View {
  let bubble: Bubble
  var onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 6) {
        Text(bubble.title)
          .font(.subheadline.bold())
          .foregroundColor(.white)
          .multilineTextAlignment(.center)
        if bubble.articleURL != nil {
          Image(systemName: "arrow.up.right")
            .font(.caption.bold())
            .foregroundColor(.white.opacity(0.7))
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.toastBackground)
          .shadow(color: .black.opacity(0.5), radius: 5, y: 3)
      )
    }
    .buttonStyle(.plain)
    .padding(.bottom, 40)
    .transition(.move(edge: .bottom).combined(with: .opacity))
  }
}
