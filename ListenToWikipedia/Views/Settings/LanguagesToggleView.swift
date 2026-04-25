import SwiftUI

struct LanguagesToggleView: View {
  @EnvironmentObject private var settings: AppSettings

  var body: some View {
    List {
      ForEach(WikipediaLanguage.all) { language in
        Toggle(language.name, isOn: languageToggleBinding(for: language))
          .disabled(
            settings.selectedLanguageCodes.contains(language.code)
            && settings.selectedLanguageCodes.count == 1
          )
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
        } else if settings.selectedLanguageCodes.count > 1 {
          settings.selectedLanguageCodes.remove(language.code)
        }
      }
    )
  }
}

#Preview {
  LanguagesToggleView()
}
