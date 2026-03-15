import Foundation

/// An article edit received from the Wikipedia recent-changes stream.
struct WikipediaArticleEdit {
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
struct WikipediaNewUser {
  let language: String
  let username: String
}

/// A parsed event from the wikimon WebSocket stream.
enum WikipediaEvent {
  case articleEdit(WikipediaArticleEdit)
  case newUser(WikipediaNewUser)
}
