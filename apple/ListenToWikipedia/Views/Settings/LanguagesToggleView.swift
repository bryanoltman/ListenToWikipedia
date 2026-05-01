import SwiftUI

struct LanguagesToggleView: View {
  @EnvironmentObject private var settings: AppSettings

  var body: some View {
    List {
      ForEach(WikipediaLanguage.all) { language in
        Toggle(language.name, isOn: languageToggleBinding(for: language))
      }
    }
    .navigationTitle("Languages")
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
