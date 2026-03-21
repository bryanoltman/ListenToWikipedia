import Combine
import SwiftUI

/// Root view. Owns all coordination between the websocket service, audio, and UI.
struct ContentView: View {
  @StateObject private var manager = BubbleManager()
  @StateObject private var service = WikipediaWebSocketService()
  @EnvironmentObject private var settings: AppSettings
  @State private var isShowingSettings = false
  @State private var tappedBubble: Bubble?
  @State private var tapClearTask: Task<Void, Never>?
  @Environment(\.openURL) private var openURL
  @State private var notePlayer = NotePlayer(programs: AppSettings.shared.instrumentPrograms)

  var body: some View {
    BubblesView(manager: manager) { bubble in
      showToast(for: bubble)
    }
    .background(
      Color(red: 0x1B / 255.0, green: 0x20 / 255.0, blue: 0x24 / 255.0)
        .ignoresSafeArea()
    )
    .overlay(alignment: .topTrailing) {
      HStack(spacing: 8) {
        Button(action: { isShowingSettings = true }) {
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
      for (type, program) in programs {
        notePlayer.loadInstrument(program: program, for: type)
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
      case .newUser:
        if !settings.isMuted, let note = settings.currentScale.randomElement() {
          notePlayer.play(note: note, type: .newUser)
        }
      }
    }
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
}

#Preview {
  ContentView()
    .environmentObject(AppSettings.shared)
}
