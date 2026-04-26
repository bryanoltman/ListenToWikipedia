import SwiftUI

/// Toast shown at the bottom of the screen when the user taps a bubble.
struct ArticleToastView: View {
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
          .lineLimit(2)
        if articleURL != nil {
          Image(systemName: "arrow.up.right")
            .font(.subheadline.bold())
            .foregroundColor(.white.opacity(0.7))
        }
      }
      .padding()
      .toastBackground()
    }
    .frame(maxWidth: 500)
    .buttonStyle()
    .accessibilityLabel("Article: \(title)")
    .accessibilityHint(articleURL != nil ? "Opens article in browser" : "")
    .transition(.move(edge: .bottom).combined(with: .opacity))
  }
}

extension View {
  @ViewBuilder
  fileprivate func buttonStyle() -> some View {
    if #available(iOS 26, macOS 26, tvOS 26, *) {
      self.buttonStyle(.glass)
    } else {
      self.buttonStyle(.plain)
    }
  }

  @ViewBuilder
  fileprivate func toastBackground() -> some View {
    if #available(iOS 26, macOS 26, tvOS 26, *) {
      self
    } else {
      self.background {
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.toastBackground)
          .shadow(color: .black.opacity(0.5), radius: 5, y: 3)
      }
    }
  }
}

#Preview {
  Color(.black)
    .ignoresSafeArea()
    .overlay(alignment: .bottom) {
      ArticleToastView(
        title: "Patrick Swayze",
        articleURL: URL(string: "https://en.wikipedia.org/wiki/Patrick_Swayze")
      ) {
      }
    }
}
