import SwiftUI

@main
struct ListenToWikipediaApp: App {
  #if os(iOS)
  @Environment(\.scenePhase) private var scenePhase
  #endif

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(AppSettings.shared)
    }
    #if os(iOS)
    .onChange(of: scenePhase) { _, phase in
      UIApplication.shared.isIdleTimerDisabled = (phase == .active)
    }
    #endif

    #if os(macOS)
      Settings {
        SettingsView()
          .environmentObject(AppSettings.shared)
      }
    #endif
  }
}
