import Foundation

enum PentatonicMode: String, CaseIterable, Identifiable {
    case majorPentatonic = "Major Pentatonic"
    case egyptian = "Egyptian"
    case bluesMinor = "Blues Minor"
    case bluesMajor = "Blues Major"
    case minorPentatonic = "Minor Pentatonic"

    var id: String { rawValue }

    var intervals: [Int] {
        switch self {
        case .majorPentatonic: return [2, 2, 3, 2, 3]
        case .egyptian:        return [2, 3, 2, 3, 2]
        case .bluesMinor:      return [3, 2, 3, 2, 2]
        case .bluesMajor:      return [2, 3, 2, 2, 3]
        case .minorPentatonic: return [3, 2, 2, 3, 2]
        }
    }
}
