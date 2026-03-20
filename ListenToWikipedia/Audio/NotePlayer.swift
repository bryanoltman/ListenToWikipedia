import AVFoundation

/// Plays MIDI notes using the app's bundled SoundFont file.
class NotePlayer {
  private let engine = AVAudioEngine()
  private let sampler = AVAudioUnitSampler()

  private let soundFontURL: URL? = SoundFontParser.bundledSoundFontURL

  // Default to Acoustic Guitar (Nylon)
  init(program: UInt8 = 24) {
    setupAudioSession()
    setupEngine(program: program)
  }

  private func setupAudioSession() {
    #if os(iOS)
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("[NotePlayer] Audio session setup failed: \(error)")
    }
    #endif
  }

  private func setupEngine(program: UInt8) {
    engine.attach(sampler)
    engine.connect(sampler, to: engine.mainMixerNode, format: nil)

    do {
      try engine.start()
    } catch {
      print("[NotePlayer] Engine start failed: \(error)")
      return
    }

    loadInstrument(program: program)
  }

  /// Switches to the instrument identified by `program` in the bundled SoundFont.
  func loadInstrument(program: UInt8) {
    guard let url = soundFontURL else {
      print("[NotePlayer] Bundled SoundFont not found in bundle")
      return
    }
    do {
      try sampler.loadSoundBankInstrument(
        at: url,
        program: program,
        bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
        bankLSB: UInt8(kAUSampler_DefaultBankLSB)
      )
    } catch {
      print("[NotePlayer] SoundFont load failed for program \(program): \(error)")
    }
  }

  /// Plays a specific MIDI note, then stops it after 5 seconds.
  func play(note: UInt8, velocity: UInt8 = 100) {
    sampler.startNote(note, withVelocity: velocity, onChannel: 0)
    Task {
      try? await Task.sleep(nanoseconds: 5_000_000_000)
      self.sampler.stopNote(note, onChannel: 0)
    }
  }
}
