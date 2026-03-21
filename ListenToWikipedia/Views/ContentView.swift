import Combine
import SwiftUI

/// Root view. Owns all coordination between the websocket service, audio, and UI.
struct ContentView: View {
  @StateObject private var manager = BubbleManager()
  @StateObject private var service = WikipediaWebSocketService()
  @EnvironmentObject private var settings: AppSettings
  @State private var isShowingSettings = false
  #if os(macOS)
    @Environment(\.openSettings) private var openSettings
  #endif
  @State private var tappedBubble: Bubble?
  @State private var tapClearTask: Task<Void, Never>?
  @State private var newUser: WikipediaNewUser?
  @State private var newUserClearTask: Task<Void, Never>?
  @Environment(\.openURL) private var openURL
  @State private var notePlayer = NotePlayer(programs: AppSettings.shared.instrumentPrograms)

  var body: some View {
    BubblesView(manager: manager) { bubble in
      showToast(for: bubble)
    }
    .background(
      Color.appBackground
        .ignoresSafeArea()
    )
    .overlay(alignment: .topLeading) {
      HStack(spacing: 8) {
        Button(action: openSettingsAction) {
          Image(systemName: "gearshape.fill")
            .font(.title2)
            .foregroundColor(.white)
            .padding()
            .background(Circle().fill(Color.black.opacity(0.5)))
        }
        .buttonStyle(.plain)
      }
      .padding()
    }
    .overlay(alignment: .bottom) {
      if let bubble = tappedBubble {
        ArticleToastView(bubble: bubble) {
          if let url = bubble.articleURL {
            openURL(url)
          }
        }
      }
    }
    .overlay(alignment: .top) {
      if let newUser {
        NewUserBannerView(user: newUser) {
          if let url = userTalkPageURL(for: newUser) {
            openURL(url)
          }
        }
      }
    }
    .animation(
      .spring(response: 0.3, dampingFraction: 0.7),
      value: newUser?.username
    )
    .animation(
      .spring(response: 0.3, dampingFraction: 0.7),
      value: tappedBubble?.id
    )
    .sheet(isPresented: $isShowingSettings) {
      SettingsView()
    }
    .onAppear {
      syncConnections(to: settings.selectedLanguageCodes)
    }
    .onDisappear {
      service.disconnectAll()
    }
    .onReceive(settings.$selectedLanguageCodes) { codes in
      syncConnections(to: codes)
    }
    .onReceive(settings.$instrumentPrograms) { programs in
      for (type, instrumentId) in programs {
        notePlayer.loadInstrument(instrumentId, for: type)
      }
    }
    .onReceive(service.eventPublisher) { event in
      switch event {
      case .articleEdit(let edit):
        manager.addBubble(from: edit)
        if !settings.isMuted,
          let note = MusicalScale.noteForEdit(changeSize: edit.changeSize, in: settings.currentScale)
        {
          let type: EditSoundType = edit.changeSize > 0 ? .addition : .subtraction
          notePlayer.play(note: note, type: type)
        }
      case .newUser(let user):
        showBanner(for: user)
        if !settings.isMuted, let note = settings.currentScale.randomElement() {
          notePlayer.play(note: note, type: .newUser)
        }
      }
    }
  }

  private func openSettingsAction() {
    #if os(macOS)
      openSettings()
    #else
      isShowingSettings = true
    #endif
  }

  private func showToast(for bubble: Bubble) {
    tappedBubble = bubble
    tapClearTask?.cancel()
    tapClearTask = Task {
      try? await Task.sleep(nanoseconds: 3_000_000_000)
      guard !Task.isCancelled else { return }
      tappedBubble = nil
    }
  }

  private func showBanner(for user: WikipediaNewUser) {
    newUser = user
    newUserClearTask?.cancel()
    newUserClearTask = Task {
      try? await Task.sleep(for: .seconds(8))
      guard !Task.isCancelled else { return }
      newUser = nil
    }
  }

  /// Connects to languages that are selected but not yet connected,
  /// and disconnects languages that are connected but no longer selected.
  private func syncConnections(to selected: Set<String>) {
    for lang in service.connectedLanguages where !selected.contains(lang) {
      service.disconnect(language: lang)
    }
    for lang in selected where !service.connectedLanguages.contains(lang) {
      service.connect(language: lang)
    }
  }

  /// Builds the URL for welcoming a new user on their talk page
  private func userTalkPageURL(for user: WikipediaNewUser) -> URL? {
    guard
      let encodedName = user.username
        .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    else { return nil }
    return URL(
      string: "https://\(user.language).wikipedia.org/w/index.php?title=User_talk:\(encodedName)&action=edit&section=new"
    )
  }
}

#Preview {
  ContentView()
    .environmentObject(AppSettings.shared)
}
