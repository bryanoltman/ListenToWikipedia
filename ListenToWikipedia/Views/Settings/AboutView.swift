import SwiftUI

struct AboutView: View {
  @Environment(\.openURL) private var openURL

  var body: some View {
    #if os(iOS)
      ScrollView {
        bodyContent
      }
    #else
      bodyContent
    #endif
  }

  private var bodyContent: some View {
    VStack(alignment: .leading, spacing: 32) {

      VStack(alignment: .leading, spacing: 12) {
        Text("How It Works")
          .font(.title2.bold())

        Text(
          "This app shows edits to Wikipedia as they happen in real time. "
            + "Each bubble represents a single edit to an article."
        )
        .font(.body)

        VStack(alignment: .leading, spacing: 8) {
          legendRow(color: .white, label: "Registered user edit")
          legendRow(color: .dotGreen, label: "Anonymous edit")
          legendRow(color: .dotPurple, label: "Bot edit")
        }

        Text(
          "Larger bubbles represent larger edits. Light bubbles are additions; dark bubbles are removals."
        )
        .font(.body)

        Text(
          "Tap a bubble to see the article title, then tap the toast to open the article."
        )
        .font(.body)
      }

      Divider()

      VStack(alignment: .leading, spacing: 8) {
        Text("Credits")
          .font(.title2.bold())

        Text("Developed by Bryan Oltman")
          .font(.body)

        Button {
          if let url = URL(string: "http://listen.hatnote.com") {
            openURL(url)
          }
        } label: {
          Text("Inspired by Hatnote's Listen to Wikipedia")
            .font(.body)
            .underline()
        }
        .buttonStyle(.plain)

        Button {
          if let url = URL(string: "https://www.schristiancollins.com/generaluser") {
            openURL(url)
          }
        } label: {
          Text(
            "\"GeneralUser GS\" SoundFont by S. Christian Collins, GeneralUser GS License v2.0"
          )
          .font(.body)
          .underline()
        }
        .buttonStyle(.plain)
      }
    }
    .padding(24)
    .frame(width: 400)
    .fixedSize(horizontal: false, vertical: true)
  }

  private func legendRow(color: Color, label: String) -> some View {
    HStack(spacing: 10) {
      Circle()
        .fill(color)
        .frame(width: 16, height: 16)
        .overlay(Circle().stroke(Color.secondary.opacity(0.4), lineWidth: 0.5))
      Text(label)
        .font(.subheadline)
    }
  }
}

#Preview {
  NavigationStack {
    AboutView()
  }
}
