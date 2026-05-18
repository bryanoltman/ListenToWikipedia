import SwiftUI

struct LanguagesToggleView: View {
  @EnvironmentObject private var settings: AppSettings

  private var languageToggles: some View {
    ForEach(WikipediaLanguage.all) { language in
      Toggle(language.name, isOn: languageToggleBinding(for: language))
    }
  }

  var body: some View {
    #if os(macOS)
      Form {
        Section {
          languageToggles
        }
      }
      .formStyle(.grouped)
    #else
      List {
        languageToggles
      }
      .navigationTitle("Languages")
    #endif
  }

  private func languageToggleBinding(for language: WikipediaLanguage) -> Binding<Bool> {
    Binding(
      get: { settings.selectedLanguageCodes.contains(language.code) },
      set: { isOn in
        if isOn {
          settings.selectedLanguageCodes.insert(language.code)
        } else {
          settings.selectedLanguageCodes.remove(language.code)
        }
      }
    )
  }
}

#Preview {
  LanguagesToggleView()
}
