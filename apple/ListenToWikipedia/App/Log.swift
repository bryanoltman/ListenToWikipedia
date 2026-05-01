import Foundation
import os

enum LogLevel: Int, Comparable {
  case debug = 0
  case info = 1
  case error = 2
  case fault = 3

  static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

struct LeveledLogger {
  private let logger: Logger

  init(subsystem: String, category: String) {
    logger = Logger(subsystem: subsystem, category: category)
  }

  func debug(_ message: String) {
    guard Log.minimumLevel <= .debug else { return }
    logger.debug("\(message)")
  }

  func info(_ message: String) {
    guard Log.minimumLevel <= .info else { return }
    logger.info("\(message)")
  }

  func error(_ message: String) {
    guard Log.minimumLevel <= .error else { return }
    logger.error("\(message)")
  }

  func fault(_ message: String) {
    guard Log.minimumLevel <= .fault else { return }
    logger.fault("\(message)")
  }
}

/// Centralized loggers for the app, organized by functional area.
/// Usage: `Log.audio.error("Engine failed: \(error)")`
enum Log {
  /// Minimum log level. Messages below this level are silently dropped.
  /// Change this value and rebuild to adjust log verbosity.
  static let minimumLevel: LogLevel = .info

  private static let subsystem = Bundle.main.bundleIdentifier ?? "HatnoteListen"

  /// Audio engine, sampler, SoundFont loading, MIDI playback.
  static let audio = LeveledLogger(subsystem: subsystem, category: "audio")

  /// WebSocket connections: open, close, errors.
  static let network = LeveledLogger(subsystem: subsystem, category: "network")
}
