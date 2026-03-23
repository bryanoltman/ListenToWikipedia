import os

import AVFoundation

/// Plays MIDI notes using the app's bundled SoundFont file.
///
/// Manages one `AVAudioUnitSampler` per `EditSoundType`, all attached to a
/// shared `AVAudioEngine`, so different event types can play different
/// instruments simultaneously.
class NotePlayer {
  private let engine = AVAudioEngine()
  private var samplers: [EditSoundType: AVAudioUnitSampler] = [:]

  /// Tracks in-flight stop tasks so a replayed note cancels the previous timeout.
  private var activeNotes: [NoteKey: Task<Void, Never>] = [:]

  private let soundFontURL: URL? = SoundFontParser.bundledSoundFontURL

  init(programs: [EditSoundType: InstrumentId]) {
    setupAudioSession()
    setupEngine(programs: programs)
  }

  private func setupAudioSession() {
    #if os(iOS)
      do {
        try AVAudioSession.sharedInstance().setCategory(
          .playback,
          mode: .default
        )
        try AVAudioSession.sharedInstance().setActive(true)
      } catch {
        Log.audio.error("Audio session setup failed: \(error)")
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
        "SoundFont load failed for \(type.rawValue, privacy: .public) \(String(describing: instrumentId), privacy: .public): \(error)"
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
}

// MARK: - NoteKey

extension NotePlayer {
  /// Identifies a currently-sounding note by instrument type and MIDI number.
  private struct NoteKey: Hashable {
    let type: EditSoundType
    let note: UInt8
  }
}
