import Foundation
import os

/// Centralized loggers for the app, organized by functional area.
/// Usage: `Log.audio.error("Engine failed: \(error)")`
enum Log {
  /// Subsystem derived from the app's bundle identifier.
  private static let subsystem = Bundle.main.bundleIdentifier ?? "HatnoteListen"

  /// Audio engine, sampler, SoundFont loading, MIDI playback.
  static let audio = Logger(subsystem: subsystem, category: "audio")

  /// WebSocket connections: open, close, errors.
  static let network = Logger(subsystem: subsystem, category: "network")
}
