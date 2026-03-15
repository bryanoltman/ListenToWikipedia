import Foundation

struct SoundFontInstrument: Identifiable, Hashable {
  let name: String
  let bank: UInt16
  let program: UInt8

  var id: String { "\(bank)-\(program)" }
}
