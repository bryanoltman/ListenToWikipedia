import os

import Combine
import Foundation

enum ConnectionState: Equatable {
  case disconnected
  case connecting
  case connected
  case reconnecting(attempt: Int)
}

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

  /// Single published state summarizing all per-language connections.
  /// Derived from `languageStates` by `updateAggregateState()`:
  /// - `.disconnected` when no languages are tracked
  /// - `.connected` when every tracked language is `.connected`
  /// - `.reconnecting` when any language is reconnecting (reports the highest attempt count)
  /// - `.connecting` otherwise (at least one language is mid-handshake, none reconnecting)
  @Published private(set) var connectionState: ConnectionState = .disconnected

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

  /// Per-language connection state. The source of truth that `connectionState` is derived from.
  private var languageStates: [String: ConnectionState] = [:]
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
    languageStates[language] = .connecting
    updateAggregateState()
    performConnect(language: language)
  }

  private func performConnect(language: String) {
    guard let url = URL(string: "wss://wikimon.hatnote.com/v2/\(language)") else {
      Log.network.fault("Could not form WebSocket URL for language '\(language)'")
      languageStates.removeValue(forKey: language)
      updateAggregateState()
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
    languageStates.removeValue(forKey: language)
    updateAggregateState()
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
          // Reset reconnect delay on successful receive and mark connected.
          self.reconnectDelays[language] = Self.initialDelay
          self.languageStates[language] = .connected
          self.updateAggregateState()
          // Recursively schedule the next receive.
          self.scheduleNextReceive(language: language, task: task)

        case .failure(let error):
          // Connection dropped – clean up socket state.
          self.socketTasks.removeValue(forKey: language)
          self.connectedLanguages.remove(language)

          // Intentional cancellation — do not reconnect.
          if (error as? URLError)?.code == .cancelled {
            Log.network.info("Connection cancelled for \(language) (intentional)")
            self.languageStates.removeValue(forKey: language)
            self.updateAggregateState()
            return
          }

          // Unexpected failure — schedule reconnect with exponential backoff.
          Log.network.error("Connection error for \(language): \(error)")
          let currentDelay = self.reconnectDelays[language] ?? Self.initialDelay
          let attempt = Int(log2(currentDelay / Self.initialDelay)) + 1
          self.languageStates[language] = .reconnecting(attempt: attempt)
          self.updateAggregateState()

          self.reconnectTasks[language]?.cancel()
          self.reconnectTasks[language] = Task { [weak self] in
            do {
              try await Task.sleep(for: .seconds(currentDelay))
            } catch {
              return // Task cancelled — disconnect was called
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

  // MARK: - Aggregate state

  /// Recomputes `connectionState` from the per-language `languageStates` dictionary.
  /// Must be called after every mutation of `languageStates`.
  private func updateAggregateState() {
    if languageStates.isEmpty {
      connectionState = .disconnected
      return
    }
    if languageStates.values.allSatisfy({ $0 == .connected }) {
      connectionState = .connected
      return
    }
    if languageStates.values.contains(where: {
      if case .reconnecting = $0 { return true }; return false
    }) {
      let maxAttempt = languageStates.values.compactMap {
        if case .reconnecting(let a) = $0 { return a }; return nil
      }.max() ?? 0
      connectionState = .reconnecting(attempt: maxAttempt)
      return
    }
    connectionState = .connecting
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
    return WikipediaEvent.fromJsonString(jsonString, language: language)
  }
}
