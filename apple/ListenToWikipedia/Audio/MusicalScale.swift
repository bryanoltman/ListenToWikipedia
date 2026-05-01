import Foundation

enum HeptatonicMode: String, CaseIterable, Identifiable {
  case ionian = "Ionian (Major)"
  case dorian = "Dorian"
  case phrygian = "Phrygian"
  case lydian = "Lydian"
  case mixolydian = "Mixolydian"
  case aeolian = "Aeolian (Minor)"
  case locrian = "Locrian"

  var id: String { rawValue }

  var intervals: [Int] {
    switch self {
    case .ionian: return [2, 2, 1, 2, 2, 2, 1]
    case .dorian: return [2, 1, 2, 2, 2, 1, 2]
    case .phrygian: return [1, 2, 2, 2, 1, 2, 2]
    case .lydian: return [2, 2, 2, 1, 2, 2, 1]
    case .mixolydian: return [2, 2, 1, 2, 2, 1, 2]
    case .aeolian: return [2, 1, 2, 2, 1, 2, 2]
    case .locrian: return [1, 2, 2, 1, 2, 2, 2]
    }
  }
}

enum MusicalKey: String, CaseIterable, Identifiable {
  case c = "C"
  case cSharp = "C#"
  case d = "D"
  case dSharp = "D#"
  case e = "E"
  case f = "F"
  case fSharp = "F#"
  case g = "G"
  case gSharp = "G#"
  case a = "A"
  case aSharp = "A#"
  case b = "B"

  var id: String { rawValue }

  /// Semitone offset within an octave (C = 0 ... B = 11).
  var semitone: Int {
    switch self {
    case .c: return 0
    case .cSharp: return 1
    case .d: return 2
    case .dSharp: return 3
    case .e: return 4
    case .f: return 5
    case .fSharp: return 6
    case .g: return 7
    case .gSharp: return 8
    case .a: return 9
    case .aSharp: return 10
    case .b: return 11
    }
  }

  /// MIDI note number for this key at a given octave.
  func midiNote(octave: Int) -> UInt8 {
    UInt8(max(0, min(127, (octave + 1) * 12 + semitone)))
  }
}

enum MusicalScale {
  /// Generates MIDI note values for a given root, mode, and number of octaves.
  static func notes(root: UInt8, intervals: [Int], octaves: Int = 2) -> [UInt8] {
    var notes: [UInt8] = [root]
    var current = Int(root)
    for _ in 0..<octaves {
      for interval in intervals {
        current += interval
        guard current <= 127 else { return notes }
        notes.append(UInt8(current))
      }
    }
    return notes
  }

  /// Selects a note from `scale` based on the magnitude of `changeSize`.
  ///
  /// Larger edits -> lower-pitched notes (scale[0], the root).
  /// Smaller edits -> higher-pitched notes (scale[last]).
  static func noteForEdit(changeSize: Int, in scale: [UInt8]) -> UInt8? {
    guard !scale.isEmpty else { return nil }

    // Clamp magnitude to a reasonable byte-size range, then normalize
    // logarithmically so that both tiny and massive edits map meaningfully.
    let minBytes = 1.0
    let maxBytes = 100_000.0
    let magnitude = max(minBytes, min(maxBytes, abs(Double(changeSize))))
    let normalized = log(magnitude) / log(maxBytes)  // 0...1
    let scalePos = Int(round((1.0 - normalized) * Double(scale.count - 1)))
    return scale[scalePos]
  }
}
