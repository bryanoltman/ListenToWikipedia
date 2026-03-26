import AVFoundation
import os

/// Plays MIDI notes using the app's bundled SoundFont file.
///
/// Manages one `AVAudioUnitSampler` per `EditSoundType`, all attached to a
/// shared `AVAudioEngine`, so different event types can play different
/// instruments simultaneously.
@MainActor class NotePlayer {
  private let engine = AVAudioEngine()
  private var samplers: [EditSoundType: AVAudioUnitSampler] = [:]

  /// Tracks in-flight stop tasks so a replayed note cancels the previous timeout.
  private var activeNotes: [NoteKey: Task<Void, Never>] = [:]

  /// Notification observers for audio session interruption and route changes.
  private var interruptionObserver: (any NSObjectProtocol)?
  private var routeChangeObserver: (any NSObjectProtocol)?

  private let soundFontURL: URL? = SoundFontParser.bundledSoundFontURL

  init(programs: [EditSoundType: InstrumentId]) {
    setupAudioSession()
    setupEngine(programs: programs)
  }

  private func setupAudioSession() {
    // macOS does not use AVAudioSession
    #if !os(macOS)
      do {
        try AVAudioSession.sharedInstance().setCategory(
          .playback,
          mode: .default,
          options: [.mixWithOthers]
        )
        try AVAudioSession.sharedInstance().setActive(true)
      } catch {
        Log.audio.error("Audio session setup failed: \(error)")
      }
      setupInterruptionHandling()
    #endif
  }

  private func setupInterruptionHandling() {
    // macOS does not use AVAudioSession
    #if !os(macOS)
      interruptionObserver = NotificationCenter.default.addObserver(
        forName: AVAudioSession.interruptionNotification,
        object: AVAudioSession.sharedInstance(),
        queue: nil
      ) { [weak self] notification in
        guard
          let info = notification.userInfo,
          let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        if type == .ended {
          let options = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
          if AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume) {
            Task { @MainActor in self?.restartEngine() }
          }
        }
      }

      routeChangeObserver = NotificationCenter.default.addObserver(
        forName: AVAudioSession.routeChangeNotification,
        object: AVAudioSession.sharedInstance(),
        queue: nil
      ) { [weak self] notification in
        guard
          let info = notification.userInfo,
          let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
          let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
        else { return }

        if reason == .oldDeviceUnavailable {
          Task { @MainActor in self?.restartEngine() }
        }
      }
    #endif
  }

  private func setupEngine(programs: [EditSoundType: InstrumentId]) {
    for type in EditSoundType.allCases {
      let sampler = AVAudioUnitSampler()
      engine.attach(sampler)
      engine.connect(sampler, to: engine.mainMixerNode, format: nil)
      samplers[type] = sampler
    }

    do {
      try engine.start()
    } catch {
      Log.audio.fault("Engine start failed: \(error)")
      return
    }

    for (type, instrumentId) in programs {
      loadInstrument(instrumentId, for: type)
    }
  }

  /// Switches the instrument for the given `EditSoundType` to the SF2 preset
  /// identified by `instrumentId`.
  func loadInstrument(_ instrumentId: InstrumentId, for type: EditSoundType) {
    guard let url = soundFontURL else {
      Log.audio.fault("Bundled SoundFont not found in bundle")
      return
    }
    guard let sampler = samplers[type] else { return }
    do {
      try sampler.loadSoundBankInstrument(
        at: url,
        program: instrumentId.program,
        bankMSB: instrumentId.bankMSB,
        bankLSB: instrumentId.bankLSB
      )
    } catch {
      Log.audio.error(
        "SoundFont load failed for \(type.rawValue) \(String(describing: instrumentId)): \(error)"
      )
    }
  }

  /// Plays a MIDI note on the sampler for `type`, stopping it after 5 seconds.
  /// If the same note is already sounding, it is restarted from the beginning.
  func play(note: UInt8, velocity: UInt8 = 100, type: EditSoundType) {
    guard let sampler = samplers[type] else { return }

    let key = NoteKey(type: type, note: note)

    // Cancel the previous timeout and stop the note so the sampler
    // re-attacks cleanly instead of layering a second voice.
    if let existing = activeNotes.removeValue(forKey: key) {
      existing.cancel()
      sampler.stopNote(note, onChannel: 0)
    }

    sampler.startNote(note, withVelocity: velocity, onChannel: 0)

    activeNotes[key] = Task { [weak self] in
      try? await Task.sleep(nanoseconds: 5_000_000_000)
      guard !Task.isCancelled else { return }
      sampler.stopNote(note, onChannel: 0)
      self?.activeNotes.removeValue(forKey: key)
    }
  }

  /// Stops all active notes and shuts down the audio engine.
  func stop() {
    for (_, task) in activeNotes {
      task.cancel()
    }
    activeNotes.removeAll()
    engine.stop()
  }

  private func restartEngine() {
    guard !engine.isRunning else { return }
    do {
      try engine.start()
    } catch {
      Log.audio.error("Engine restart failed: \(error)")
    }
  }

  deinit {
    for task in activeNotes.values {
      task.cancel()
    }
    if let observer = interruptionObserver {
      NotificationCenter.default.removeObserver(observer)
    }
    if let observer = routeChangeObserver {
      NotificationCenter.default.removeObserver(observer)
    }
    engine.stop()
  }
}

// MARK: - NoteKey

extension NotePlayer {
  /// Identifies a currently-sounding note by instrument type and MIDI number.
  private struct NoteKey: Hashable {
    let type: EditSoundType
    let note: UInt8
  }
}
