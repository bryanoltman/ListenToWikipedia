import SwiftUI

@main
struct ListenToWikipediaApp: App {
  var body: some Scene {
    WindowGroup {
      BubblesView()
        .environmentObject(AppSettings.shared)
    }

    #if os(macOS)
      Settings {
        SettingsView()
          .environmentObject(AppSettings.shared)
      }
    #endif
  }
}
