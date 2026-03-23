import os

import Combine
import Foundation

/// Manages WebSocket connections to the wikimon recent-changes stream
/// (wss://wikimon.hatnote.com/v2/{languageCode}) and publishes parsed events.
///
/// Usage from SwiftUI:
/// ```swift
/// @StateObject private var service = WikipediaWebSocketService()
///
/// // Connect to one or more language streams
/// service.connect(language: "en")
/// service.connect(language: "de")
///
/// // Observe events with .onReceive
/// .onReceive(service.eventPublisher) { event in … }
///
/// // Or observe the most-recent event via @Published
/// // service.lastEvent
/// ```
@MainActor
final class WikipediaWebSocketService: ObservableObject {

  /// The set of language codes that are currently connected.
  @Published private(set) var connectedLanguages: Set<String> = []

  /// The most recently received event. Useful for simple `.onChange` observers.
  @Published private(set) var lastEvent: WikipediaEvent?

  /// A Combine publisher that emits every parsed event as it arrives.
  var eventPublisher: AnyPublisher<WikipediaEvent, Never> {
    eventSubject.eraseToAnyPublisher()
  }

  private let session = URLSession(configuration: .default)
  /// Maps language codes to web socket Tasks
  private var socketTasks: [String: URLSessionWebSocketTask] = [:]
  private let eventSubject = PassthroughSubject<WikipediaEvent, Never>()

  /// Opens a WebSocket connection for the given Wikipedia language code.
  /// If a connection for that language already exists, this is a no-op.
  func connect(language: String) {
    guard socketTasks[language] == nil else { return }
    guard let url = URL(string: "wss://wikimon.hatnote.com/v2/\(language)") else {
      Log.network.fault("Could not form WebSocket URL for language '\(language)'")
      return
    }

    let task = session.webSocketTask(with: url)
    socketTasks[language] = task
    connectedLanguages.insert(language)
    task.resume()
    Log.network.info("Connecting to \(language)")
    scheduleNextReceive(language: language, task: task)
  }

  /// Closes the WebSocket connection for the given language code.
  func disconnect(language: String) {
    Log.network.info("Disconnecting from \(language)")
    socketTasks[language]?.cancel(with: .goingAway, reason: nil)
    socketTasks.removeValue(forKey: language)
    connectedLanguages.remove(language)
  }

  /// Closes all open WebSocket connections.
  func disconnectAll() {
    Log.network.info("Disconnecting all (\(self.connectedLanguages.count) connections)")
    for language in Array(socketTasks.keys) {
      disconnect(language: language)
    }
  }

  private func scheduleNextReceive(language: String, task: URLSessionWebSocketTask) {
    task.receive { [weak self] result in
      // Always hop back to MainActor so we can safely read/write state.
      Task { @MainActor [weak self] in
        guard let self else { return }
        // Ignore results from tasks that have been superseded or cancelled.
        guard self.socketTasks[language] === task else { return }

        switch result {
        case .success(let message):
          if let event = self.parse(message, language: language) {
            Log.network.debug("Received event for \(language)")
            self.lastEvent = event
            self.eventSubject.send(event)
          }
          // Recursively schedule the next receive.
          self.scheduleNextReceive(language: language, task: task)

        case .failure(let error):
          // Connection dropped – clean up and let callers observe the change.
          Log.network.error("Connection error for \(language): \(error)")
          self.socketTasks.removeValue(forKey: language)
          self.connectedLanguages.remove(language)
        }
      }
    }
  }

  // MARK: - JSON parsing

  private func parse(_ message: URLSessionWebSocketTask.Message, language: String)
    -> WikipediaEvent?
  {
    let jsonString: String
    switch message {
    case .string(let s):
      jsonString = s
    case .data(let d):
      guard let s = String(data: d, encoding: .utf8) else { return nil }
      jsonString = s
    @unknown default:
      return nil
    }

    guard
      let data = jsonString.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return nil }

    let pageTitle = json["page_title"] as? String ?? ""

    // New-user registration event
    if pageTitle == "Special:Log/newusers" {
      guard let username = json["user"] as? String else { return nil }
      return .newUser(WikipediaNewUser(language: language, username: username))
    }

    // Article edit – main namespace only
    guard
      let namespace = json["ns"] as? String,
      namespace.caseInsensitiveCompare("main") == .orderedSame
    else {
      Log.network.debug("Skipped non-main-namespace event for \(language)")
      return nil
    }

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
