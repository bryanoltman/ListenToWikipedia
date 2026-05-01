import Combine
import Foundation
import os

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

  private var reconnectTasks: [String: Task<Void, Never>] = [:]
  private var reconnectDelays: [String: TimeInterval] = [:]

  private static let initialDelay: TimeInterval = 1.0
  private static let maxDelay: TimeInterval = 30.0

  /// Opens a WebSocket connection for the given Wikipedia language code.
  /// If a connection for that language already exists, this is a no-op.
  func connect(language: String) {
    guard socketTasks[language] == nil else { return }
    // Cancel any pending reconnect for this language.
    reconnectTasks[language]?.cancel()
    reconnectTasks.removeValue(forKey: language)
    performConnect(language: language)
  }

  private func performConnect(language: String) {
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
    reconnectTasks[language]?.cancel()
    reconnectTasks.removeValue(forKey: language)
    reconnectDelays.removeValue(forKey: language)
    socketTasks[language]?.cancel(with: .goingAway, reason: nil)
    socketTasks.removeValue(forKey: language)
    connectedLanguages.remove(language)
  }

  /// Closes all open WebSocket connections.
  func disconnectAll() {
    Log.network.info("Disconnecting all (\(self.connectedLanguages.count) connections)")
    for task in reconnectTasks.values { task.cancel() }
    reconnectTasks.removeAll()
    reconnectDelays.removeAll()
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
          // Reset reconnect delay on successful receive.
          self.reconnectDelays[language] = Self.initialDelay
          // Recursively schedule the next receive.
          self.scheduleNextReceive(language: language, task: task)

        case .failure(let error):
          // Connection dropped – clean up socket state.
          self.socketTasks.removeValue(forKey: language)
          self.connectedLanguages.remove(language)

          // Intentional cancellation — do not reconnect.
          if (error as? URLError)?.code == .cancelled {
            Log.network.info("Connection cancelled for \(language) (intentional)")
            return
          }

          // Unexpected failure — schedule reconnect with exponential backoff.
          Log.network.error("Connection error for \(language): \(error)")
          let currentDelay = self.reconnectDelays[language] ?? Self.initialDelay
          let attempt = Int(log2(currentDelay / Self.initialDelay)) + 1
          self.reconnectTasks[language]?.cancel()
          self.reconnectTasks[language] = Task { [weak self] in
            do {
              try await Task.sleep(for: .seconds(currentDelay))
            } catch {
              return  // Task cancelled — disconnect was called
            }
            guard let self else { return }
            Log.network.info("Reconnecting to \(language) (attempt \(attempt), delay \(currentDelay)s)")
            self.reconnectDelays[language] = min(currentDelay * 2, Self.maxDelay)
            self.performConnect(language: language)
          }
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
      guard let s = String(data: d, encoding: .utf8) else {
        Log.network.error("Failed to decode WebSocket data as UTF-8 (\(d.count) bytes, language: \(language))")
        return nil
      }
      jsonString = s
    @unknown default:
      return nil
    }

    return WikipediaEvent.fromJsonString(jsonString, language: language)
  }
}
