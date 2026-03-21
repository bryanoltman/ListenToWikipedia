import Foundation

// Categorizes Wikipedia events for instrument selection.
enum EditSoundType: String, CaseIterable, Identifiable, Codable {
  case addition
  case subtraction
  case newUser

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .addition: return "Addition"
    case .subtraction: return "Subtraction"
    case .newUser: return "New User"
    }
  }

  /// Default SF2 presets from the bundled GeneralUser-GS.sf2 (all bank 0).
  /// These match the instrument families used by listen.hatnote.com:
  ///   - Program 8 "Celeste" — the celesta sounds used for additions
  ///   - Program 7 "Clavinet" — the clav sounds used for subtractions
  ///   - Program 89 "Warm Pad" — approximates the mp3 swell files used for new-user events
  var defaultInstrumentId: InstrumentId {
    switch self {
    case .addition: return InstrumentId(bank: 0, program: 8)
    case .subtraction: return InstrumentId(bank: 0, program: 7)
    case .newUser: return InstrumentId(bank: 0, program: 89)
    }
  }
}
