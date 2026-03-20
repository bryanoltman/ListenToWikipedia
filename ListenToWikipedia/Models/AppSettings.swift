import Combine
import Foundation

/// Shared, persistent app settings. Inject into the SwiftUI environment via
/// `.environmentObject(AppSettings.shared)`.
class AppSettings: ObservableObject {
  static let shared = AppSettings()

  @Published var selectedLanguageCodes: Set<String>
  @Published var scaleType: ScaleType
  @Published var musicalKey: MusicalKey
  @Published var heptatonicMode: HeptatonicMode
  @Published var pentatonicMode: PentatonicMode
  @Published var isMuted: Bool
  /// Per-edit-type MIDI program numbers. Keys are `EditSoundType` cases,
  /// values are SF2 program numbers from the bundled GeneralUser-GS.sf2.
  @Published var instrumentPrograms: [EditSoundType: UInt8]
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
    static let pentatonicMode = "pentatonicMode"
    static let isMuted = "isMuted"
    static let instrumentPrograms = "instrumentPrograms"
    static let rootOctave = "rootOctave"
    static let octaveRange = "octaveRange"
  }

  private init() {
    let defaults = UserDefaults.standard

    let languageCodes =
      defaults.stringArray(forKey: Keys.selectedLanguages) ?? ["en"]
    selectedLanguageCodes = Set(languageCodes)

    let scaleTypeRaw = defaults.integer(forKey: Keys.scaleCardinality)
    scaleType =
      scaleTypeRaw == 0
      ? ScaleType.pentatonic
      : ScaleType(rawValue: scaleTypeRaw)
        ?? ScaleType.pentatonic

    let keyRaw =
      defaults.string(forKey: Keys.musicalKey) ?? MusicalKey.b.rawValue
    musicalKey = MusicalKey(rawValue: keyRaw) ?? .b

    let modeRaw =
      defaults.string(forKey: Keys.musicalMode)
      ?? HeptatonicMode.dorian.rawValue
    heptatonicMode = HeptatonicMode(rawValue: modeRaw) ?? .dorian

    let pentatonicModeRaw =
      defaults.string(forKey: Keys.pentatonicMode)
      ?? PentatonicMode.majorPentatonic.rawValue
    pentatonicMode =
      PentatonicMode(rawValue: pentatonicModeRaw) ?? .majorPentatonic

    isMuted = defaults.bool(forKey: Keys.isMuted)

    instrumentPrograms = AppSettings.loadInstrumentPrograms(from: defaults)

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

  private static func loadInstrumentPrograms(
    from defaults: UserDefaults
  ) -> [EditSoundType: UInt8] {
    // Try the new per-type dictionary first.
    if let dict = defaults.dictionary(forKey: Keys.instrumentPrograms)
      as? [String: Int]
    {
      var programs: [EditSoundType: UInt8] = [:]
      for type in EditSoundType.allCases {
        if let value = dict[type.rawValue] {
          programs[type] = UInt8(clamping: value)
        } else {
          programs[type] = type.defaultProgram
        }
      }
      return programs
    }

    return [
      .addition: EditSoundType.addition.defaultProgram,
      .subtraction: EditSoundType.subtraction.defaultProgram,
      .newUser: EditSoundType.newUser.defaultProgram,
    ]
  }

  private func save() {
    let defaults = UserDefaults.standard
    defaults.set(Array(selectedLanguageCodes), forKey: Keys.selectedLanguages)
    defaults.set(musicalKey.rawValue, forKey: Keys.musicalKey)
    defaults.set(heptatonicMode.rawValue, forKey: Keys.musicalMode)
    defaults.set(scaleType.rawValue, forKey: Keys.scaleCardinality)
    defaults.set(pentatonicMode.rawValue, forKey: Keys.pentatonicMode)
    defaults.set(isMuted, forKey: Keys.isMuted)
    let encoded = instrumentPrograms.reduce(into: [String: Int]()) { dict, pair in
      dict[pair.key.rawValue] = Int(pair.value)
    }
    defaults.set(encoded, forKey: Keys.instrumentPrograms)
    defaults.set(rootOctave, forKey: Keys.rootOctave)
    defaults.set(octaveRange, forKey: Keys.octaveRange)
  }

  /// The MIDI notes that should be used when playing an edit sound.
  var currentScale: [UInt8] {
    let intervals: [Int]
    switch scaleType {
    case .pentatonic:
      intervals = pentatonicMode.intervals
    case .heptatonic:
      intervals = heptatonicMode.intervals
    }
    return MusicalScale.notes(
      root: musicalKey.midiNote(octave: rootOctave),
      intervals: intervals,
      octaves: octaveRange
    )
  }
}
