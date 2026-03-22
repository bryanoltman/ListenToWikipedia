import SwiftUI

/// Banner shown at the top of the screen when a new Wikipedia user registers.
struct NewUserBannerView: View {
  let user: WikipediaNewUser
  var onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 6) {
        Image(systemName: "person.fill")
          .font(.subheadline.bold())
          .foregroundColor(.white)
        Text("Welcome, **\(user.username)**")
          .font(.subheadline)
          .foregroundColor(.white)
        Image(systemName: "arrow.up.right")
          .font(.caption.bold())
          .foregroundColor(.white.opacity(0.7))
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(
        RoundedRectangle(cornerRadius: 20)
          .fill(Color.newUserBanner)
          .shadow(color: .black.opacity(0.4), radius: 5, y: 3)
      )
    }
    .buttonStyle(.plain)
    .transition(.move(edge: .top).combined(with: .opacity))
  }
}

#Preview {
  ZStack {
    Spacer()
  }
  .overlay(alignment: .top) {
    NewUserBannerView(user: WikipediaNewUser(language: "en", username: "test"), onTap: {})
  }
}
