import SwiftUI

struct SettingsView: View {
  @EnvironmentObject private var settings: AppSettings
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    #if os(macOS)
      macOSBody
    #else
      iOSBody
    #endif
  }

  #if os(macOS)
    private var macOSBody: some View {
      TabView {
        languageList
          .tabItem { Label("Languages", systemImage: "globe") }

        MusicSettingsView()
          .tabItem { Label("Music", systemImage: "music.note") }

        AboutView()
          .tabItem { Label("About", systemImage: "info.circle") }
      }
      .frame(width: 450, height: 520)
    }

    private var languageList: some View {
      List {
        ForEach(WikipediaLanguage.all) { language in
          Toggle(language.name, isOn: languageToggleBinding(for: language))
        }
      }
    }
  #endif

  private var iOSBody: some View {
    NavigationStack {
      Form {
        Section("Settings") {
          NavigationLink("Music") { MusicSettingsView() }
        }

        Section {
          NavigationLink("About") { AboutView() }
        }

        Section("Languages") {
          ForEach(WikipediaLanguage.all) { language in
            Toggle(language.name, isOn: languageToggleBinding(for: language))
          }
        }
      }
      .navigationTitle("Settings")
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
  }

  private func languageToggleBinding(for language: WikipediaLanguage)
    -> Binding<Bool>
  {
    Binding(
      get: { settings.selectedLanguageCodes.contains(language.code) },
      set: { isOn in
        if isOn {
          settings.selectedLanguageCodes.insert(language.code)
        } else {
          guard settings.selectedLanguageCodes.count > 1 else { return }
          settings.selectedLanguageCodes.remove(language.code)
        }
      }
    )
  }
}

#Preview {
  SettingsView()
    .environmentObject(AppSettings.shared)
}
