import SwiftUI

/// Toast shown at the bottom of the screen when the user taps a bubble.
struct ArticleToastView: View {
  //  let bubble: Bubble
  let title: String
  let articleURL: URL?
  var onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 6) {
        Text(title)
          .font(.subheadline.bold())
          .foregroundColor(.white)
          .multilineTextAlignment(.center)
        if articleURL != nil {
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
    .transition(.move(edge: .bottom).combined(with: .opacity))
  }
}

#Preview {
  ZStack {
    Spacer()
  }
  .overlay(alignment: .bottom) {
    ArticleToastView(title: "Patrick Swayze", articleURL: URL(string: "https://en.wikipedia.org/wiki/Patrick_Swayze")) {
    }
  }
}
