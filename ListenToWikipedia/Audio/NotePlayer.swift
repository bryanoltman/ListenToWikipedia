import AVFoundation

/// Plays MIDI notes using the app's bundled SoundFont file.
///
/// Manages one `AVAudioUnitSampler` per `EditSoundType`, all attached to a
/// shared `AVAudioEngine`, so different event types can play different
/// instruments simultaneously.
class NotePlayer {
  private let engine = AVAudioEngine()
  private var samplers: [EditSoundType: AVAudioUnitSampler] = [:]

  private let soundFontURL: URL? = SoundFontParser.bundledSoundFontURL

  init(programs: [EditSoundType: UInt8]) {
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
        print("[NotePlayer] Audio session setup failed: \(error)")
      }
    #endif
  }

  private func setupEngine(programs: [EditSoundType: UInt8]) {
    for type in EditSoundType.allCases {
      let sampler = AVAudioUnitSampler()
      engine.attach(sampler)
      engine.connect(sampler, to: engine.mainMixerNode, format: nil)
      samplers[type] = sampler
    }

    do {
      try engine.start()
    } catch {
      print("[NotePlayer] Engine start failed: \(error)")
      return
    }

    for (type, program) in programs {
      loadInstrument(program: program, for: type)
    }
  }

  /// Switches the instrument for the given `EditSoundType` to the SF2 preset
  /// identified by `program`.
  func loadInstrument(program: UInt8, for type: EditSoundType) {
    guard let url = soundFontURL else {
      print("[NotePlayer] Bundled SoundFont not found in bundle")
      return
    }
    guard let sampler = samplers[type] else { return }
    do {
      try sampler.loadSoundBankInstrument(
        at: url,
        program: program,
        bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
        bankLSB: UInt8(kAUSampler_DefaultBankLSB)
      )
    } catch {
      print(
        "[NotePlayer] SoundFont load failed for \(type) program \(program): \(error)"
      )
    }
  }

  /// Plays a specific MIDI note on the sampler for `type`, then stops it after
  /// 5 seconds.
  func play(note: UInt8, velocity: UInt8 = 100, type: EditSoundType) {
    guard let sampler = samplers[type] else { return }
    sampler.startNote(note, withVelocity: velocity, onChannel: 0)
    Task {
      try? await Task.sleep(nanoseconds: 5_000_000_000)
      sampler.stopNote(note, onChannel: 0)
    }
  }
}
