import Foundation

/// An article edit received from the Wikipedia recent-changes stream.
struct WikipediaArticleEdit: Equatable {
  /// The Wikipedia language code (e.g. "en", "de").
  let language: String
  /// The title of the edited article.
  let pageTitle: String
  /// In bytes. positive = addition, negative = removal.
  let changeSize: Int
  let isAnonymous: Bool
  let isBot: Bool
  /// URL to the article on Wikipedia.
  let url: URL?
}

/// A new-account registration event.
struct WikipediaNewUser: Equatable {
  let language: String
  let username: String
}

/// A parsed event from the wikimon WebSocket stream.
enum WikipediaEvent: Equatable {
  case articleEdit(WikipediaArticleEdit)
  case newUser(WikipediaNewUser)
}

extension WikipediaEvent {
  /// Parses a raw JSON string from the wikimon WebSocket into a WikipediaEvent.
  /// Returns nil for unparseable, non-main-namespace, or unknown events.
  static func fromJsonString(_ jsonString: String, language: String) -> WikipediaEvent? {
    guard
      let data = jsonString.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return nil }

    let pageTitle = json["page_title"] as? String ?? ""

    if pageTitle == "Special:Log/newusers" {
      guard let username = json["user"] as? String else { return nil }
      return .newUser(WikipediaNewUser(language: language, username: username))
    }

    guard
      let namespace = json["ns"] as? String,
      namespace.caseInsensitiveCompare("main") == .orderedSame
    else { return nil }

    let changeSize = json["change_size"] as? Int ?? 0
    let isAnon = json["is_anon"] as? Bool ?? false
    let isBot = json["is_bot"] as? Bool ?? false
    let url = (json["url"] as? String).flatMap { URL(string: $0) }

    return .articleEdit(
      WikipediaArticleEdit(
        language: language,
        pageTitle: pageTitle,
        changeSize: changeSize,
        isAnonymous: isAnon,
        isBot: isBot,
        url: url
      )
    )
  }
}
