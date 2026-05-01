import Foundation

/// The number of notes in a scale per octave.
enum ScaleType: Int, CaseIterable, Identifiable, CustomStringConvertible {
  case pentatonic = 5
  case heptatonic = 7

  var id: Int { rawValue }

  var description: String {
    switch self {
    case .pentatonic: return "Pentatonic (5-note)"
    case .heptatonic: return "Heptatonic (7-note)"
    }
  }
}
