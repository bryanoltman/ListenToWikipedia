import Foundation

/// Identifies an SF2 preset by its bank and program number.
struct InstrumentId: Hashable, Codable {
  let bank: UInt16
  let program: UInt8

  /// The bank MSB for `AVAudioUnitSampler.loadSoundBankInstrument`.
  /// SF2 banks 0–127 are melodic; 128+ are percussion (DLS convention).
  var bankMSB: UInt8 {
    bank < 128 ? 0x79 : 0x78
  }

  /// The bank LSB for `AVAudioUnitSampler.loadSoundBankInstrument`.
  var bankLSB: UInt8 {
    UInt8(bank < 128 ? bank : bank - 128)
  }
}

struct SoundFontInstrument: Identifiable, Hashable {
  let name: String
  let bank: UInt16
  let program: UInt8

  var id: InstrumentId { InstrumentId(bank: bank, program: program) }
}
