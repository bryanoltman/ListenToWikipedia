import Combine
import Foundation

/// Shared, persistent app settings. Inject into the SwiftUI environment via
/// `.environmentObject(AppSettings.shared)`.
class AppSettings: ObservableObject {
  static let shared = AppSettings()

  @Published var selectedLanguageCodes: Set<String>
  @Published var scaleCardinality: ScaleCardinality
  @Published var musicalKey: MusicalKey
  @Published var musicalMode: MusicalMode
  @Published var isMuted: Bool
  /// MIDI program number of the currently selected SF2 instrument (default 24 = Acoustic Guitar).
  @Published var selectedInstrumentProgram: UInt8
  /// The octave at which the scale root note sits (0–8, default 2 matching HatnoteListen's B2).
  @Published var rootOctave: Int
  /// How many octaves the generated scale spans (1–4, default 2).
  @Published var octaveRange: Int

  private var cancellables = Set<AnyCancellable>()

  private enum Keys {
    static let scaleCardinality = "scaleCardinality"
    static let selectedLanguages = "selectedLanguages"
    static let musicalKey = "musicalKey"
    static let musicalMode = "musicalMode"
    static let isMuted = "isMuted"
    static let selectedInstrumentProgram = "selectedInstrumentProgram"
    static let rootOctave = "rootOctave"
    static let octaveRange = "octaveRange"
  }

  private init() {
    let defaults = UserDefaults.standard

    let languageCodes =
      defaults.stringArray(forKey: Keys.selectedLanguages) ?? ["en"]
    selectedLanguageCodes = Set(languageCodes)

    let scaleCardinalityRaw = defaults.integer(forKey: Keys.scaleCardinality)
    scaleCardinality =
      scaleCardinalityRaw == 0
      ? ScaleCardinality.pentatonic
      : ScaleCardinality(rawValue: scaleCardinalityRaw)
        ?? ScaleCardinality.pentatonic

    let keyRaw =
      defaults.string(forKey: Keys.musicalKey) ?? MusicalKey.b.rawValue
    musicalKey = MusicalKey(rawValue: keyRaw) ?? .b

    let modeRaw =
      defaults.string(forKey: Keys.musicalMode) ?? MusicalMode.dorian.rawValue
    musicalMode = MusicalMode(rawValue: modeRaw) ?? .dorian

    isMuted = defaults.bool(forKey: Keys.isMuted)

    let savedProgram = defaults.integer(forKey: Keys.selectedInstrumentProgram)
    selectedInstrumentProgram = savedProgram == 0 ? 24 : UInt8(savedProgram)

    rootOctave =
      defaults.object(forKey: Keys.rootOctave) == nil
      ? 2 : defaults.integer(forKey: Keys.rootOctave)
    octaveRange =
      defaults.object(forKey: Keys.octaveRange) == nil
      ? 2 : defaults.integer(forKey: Keys.octaveRange)

    // Persist whenever any published property changes.
    objectWillChange
      .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
      .sink { [weak self] _ in self?.save() }
      .store(in: &cancellables)
  }

  private func save() {
    let defaults = UserDefaults.standard
    defaults.set(Array(selectedLanguageCodes), forKey: Keys.selectedLanguages)
    defaults.set(musicalKey.rawValue, forKey: Keys.musicalKey)
    defaults.set(musicalMode.rawValue, forKey: Keys.musicalMode)
    defaults.set(isMuted, forKey: Keys.isMuted)
    defaults.set(
      Int(selectedInstrumentProgram),
      forKey: Keys.selectedInstrumentProgram
    )
    defaults.set(rootOctave, forKey: Keys.rootOctave)
    defaults.set(octaveRange, forKey: Keys.octaveRange)
  }

  /// The MIDI notes that should be used when playing an edit sound.
  var currentScale: [UInt8] {
    MusicalScale.notes(
      root: musicalKey.midiNote(octave: rootOctave),
      mode: musicalMode,
      scaleCardinality: scaleCardinality,
      octaves: octaveRange
    )
  }
}
