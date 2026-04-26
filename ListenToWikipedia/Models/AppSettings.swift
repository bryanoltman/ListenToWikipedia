import Combine
import Foundation

/// Shared, persistent app settings. Inject into the SwiftUI environment via
/// `.environmentObject(AppSettings.shared)`.
@MainActor
class AppSettings: ObservableObject {
  static let shared = AppSettings()

  @Published var selectedLanguageCodes: Set<String>
  @Published var scaleType: ScaleType
  @Published var musicalKey: MusicalKey
  @Published var heptatonicMode: HeptatonicMode
  @Published var pentatonicMode: PentatonicMode
  @Published var isMuted: Bool
  /// Per-edit-type SF2 instrument selection.
  @Published var instrumentPrograms: [EditSoundType: InstrumentId]
  /// The octave at which the scale root note sits (0–8, default 1 matching HatnoteListen's B2).
  @Published var rootOctave: Int
  /// How many octaves the generated scale spans (1–4, default 3).
  @Published var octaveRange: Int

  private var cancellables = Set<AnyCancellable>()

  private enum Defaults {
    static let languageCodes: Set<String> = ["en"]
    static let scaleType: ScaleType = .pentatonic
    static let musicalKey: MusicalKey = .fSharp
    static let heptatonicMode: HeptatonicMode = .dorian
    static let pentatonicMode: PentatonicMode = .majorPentatonic
    static let isMuted = false
    static let rootOctave = 1
    static let octaveRange = 3
    static var instrumentPrograms: [EditSoundType: InstrumentId] {
      Dictionary(uniqueKeysWithValues: EditSoundType.allCases.map { ($0, $0.defaultInstrumentId) })
    }
  }

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
      defaults.stringArray(forKey: Keys.selectedLanguages)
      .map(Set.init) ?? Defaults.languageCodes
    selectedLanguageCodes = languageCodes

    let scaleTypeRaw = defaults.integer(forKey: Keys.scaleCardinality)
    scaleType =
      scaleTypeRaw == 0
      ? Defaults.scaleType
      : ScaleType(rawValue: scaleTypeRaw)
        ?? Defaults.scaleType

    let keyRaw =
      defaults.string(forKey: Keys.musicalKey) ?? Defaults.musicalKey.rawValue
    musicalKey = MusicalKey(rawValue: keyRaw) ?? Defaults.musicalKey

    let modeRaw =
      defaults.string(forKey: Keys.musicalMode)
      ?? Defaults.heptatonicMode.rawValue
    heptatonicMode = HeptatonicMode(rawValue: modeRaw) ?? Defaults.heptatonicMode

    let pentatonicModeRaw =
      defaults.string(forKey: Keys.pentatonicMode)
      ?? Defaults.pentatonicMode.rawValue
    pentatonicMode =
      PentatonicMode(rawValue: pentatonicModeRaw) ?? Defaults.pentatonicMode

    isMuted = defaults.bool(forKey: Keys.isMuted)

    instrumentPrograms = AppSettings.loadInstrumentPrograms(from: defaults)

    let loadedRootOctave =
      defaults.object(forKey: Keys.rootOctave) == nil
      ? Defaults.rootOctave : defaults.integer(forKey: Keys.rootOctave)
    rootOctave = min(max(loadedRootOctave, 0), 8)
    let loadedOctaveRange =
      defaults.object(forKey: Keys.octaveRange) == nil
      ? Defaults.octaveRange : defaults.integer(forKey: Keys.octaveRange)
    octaveRange = min(max(loadedOctaveRange, 1), 4)

    // Persist whenever any published property changes.
    objectWillChange
      .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
      .sink { [weak self] _ in self?.save() }
      .store(in: &cancellables)
  }

  private static func loadInstrumentPrograms(
    from defaults: UserDefaults
  ) -> [EditSoundType: InstrumentId] {
    if let dict = defaults.dictionary(forKey: Keys.instrumentPrograms)
      as? [String: [String: Int]]
    {
      var programs: [EditSoundType: InstrumentId] = [:]
      for type in EditSoundType.allCases {
        if let entry = dict[type.rawValue],
          let bank = entry["bank"],
          let program = entry["program"]
        {
          programs[type] = InstrumentId(bank: UInt16(clamping: bank), program: UInt8(clamping: program))
        } else {
          programs[type] = type.defaultInstrumentId
        }
      }
      return programs
    }

    return Defaults.instrumentPrograms
  }

  private func save() {
    let defaults = UserDefaults.standard
    defaults.set(Array(selectedLanguageCodes), forKey: Keys.selectedLanguages)
    defaults.set(musicalKey.rawValue, forKey: Keys.musicalKey)
    defaults.set(heptatonicMode.rawValue, forKey: Keys.musicalMode)
    defaults.set(scaleType.rawValue, forKey: Keys.scaleCardinality)
    defaults.set(pentatonicMode.rawValue, forKey: Keys.pentatonicMode)
    defaults.set(isMuted, forKey: Keys.isMuted)
    let encoded = instrumentPrograms.reduce(into: [String: [String: Int]]()) { dict, pair in
      dict[pair.key.rawValue] = ["bank": Int(pair.value.bank), "program": Int(pair.value.program)]
    }
    defaults.set(encoded, forKey: Keys.instrumentPrograms)
    defaults.set(min(max(rootOctave, 0), 8), forKey: Keys.rootOctave)
    defaults.set(min(max(octaveRange, 1), 4), forKey: Keys.octaveRange)
  }

  /// Resets all settings to their defaults.
  func resetToDefaults() {
    selectedLanguageCodes = Defaults.languageCodes
    scaleType = Defaults.scaleType
    musicalKey = Defaults.musicalKey
    heptatonicMode = Defaults.heptatonicMode
    pentatonicMode = Defaults.pentatonicMode
    isMuted = Defaults.isMuted
    instrumentPrograms = Defaults.instrumentPrograms
    rootOctave = Defaults.rootOctave
    octaveRange = Defaults.octaveRange
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
