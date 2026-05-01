import Foundation

struct WikipediaLanguage: Identifiable, Hashable, Comparable {
  let name: String
  let code: String

  var id: String { code }

  static func < (lhs: WikipediaLanguage, rhs: WikipediaLanguage) -> Bool {
    lhs.name < rhs.name
  }

  static let all: [WikipediaLanguage] = [
    WikipediaLanguage(name: "Arabic", code: "ar"),
    WikipediaLanguage(name: "Assamese", code: "as"),
    WikipediaLanguage(name: "Belarusian", code: "be"),
    WikipediaLanguage(name: "Bengali", code: "bn"),
    WikipediaLanguage(name: "Bulgarian", code: "bg"),
    WikipediaLanguage(name: "Chinese", code: "zh"),
    WikipediaLanguage(name: "Dutch", code: "nl"),
    WikipediaLanguage(name: "English", code: "en"),
    WikipediaLanguage(name: "Farsi", code: "fa"),
    WikipediaLanguage(name: "French", code: "fr"),
    WikipediaLanguage(name: "German", code: "de"),
    WikipediaLanguage(name: "Gujarati", code: "gu"),
    WikipediaLanguage(name: "Hebrew", code: "he"),
    WikipediaLanguage(name: "Hindi", code: "hi"),
    WikipediaLanguage(name: "Indonesian", code: "id"),
    WikipediaLanguage(name: "Italian", code: "it"),
    WikipediaLanguage(name: "Japanese", code: "ja"),
    WikipediaLanguage(name: "Kannada", code: "kn"),
    WikipediaLanguage(name: "Macedonian", code: "mk"),
    WikipediaLanguage(name: "Malayalam", code: "ml"),
    WikipediaLanguage(name: "Oriya", code: "or"),
    WikipediaLanguage(name: "Polish", code: "pl"),
    WikipediaLanguage(name: "Punjabi", code: "pa"),
    WikipediaLanguage(name: "Russian", code: "ru"),
    WikipediaLanguage(name: "Sanskrit", code: "sa"),
    WikipediaLanguage(name: "Serbian", code: "sr"),
    WikipediaLanguage(name: "Spanish", code: "es"),
    WikipediaLanguage(name: "Swedish", code: "sv"),
    WikipediaLanguage(name: "Tamil", code: "ta"),
    WikipediaLanguage(name: "Telugu", code: "te"),
    WikipediaLanguage(name: "Ukrainian", code: "uk"),
    WikipediaLanguage(name: "Marathi", code: "mr"),
  ]
}
