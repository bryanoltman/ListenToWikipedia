import Foundation

/// Parses the preset headers from a SoundFont 2 (.sf2) file.
/// Ported from HatnoteListen's HATSoundFont.m.
enum SoundFontParser {
  // SoundFont 2.01 SFPresetHeader is exactly 38 bytes (packed):
  //   char     presetName[20]
  //   uint16_t preset          ← MIDI program number
  //   uint16_t bank
  //   uint16_t presetBagNdx
  //   uint32_t library
  //   uint32_t genre
  //   uint32_t morphology
  private static let headerSize = 38
  private static let nameLength = 20

  /// Returns all instruments found in the given SF2 file, sorted by name.
  static func instruments(at url: URL) -> [SoundFontInstrument] {
    guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else {
      return []
    }

    // Locate the 'phdr' chunk marker.
    let marker = Data([0x70, 0x68, 0x64, 0x72])  // 'p','h','d','r'
    guard let markerRange = data.range(of: marker) else { return [] }

    // The 4 bytes after the marker contain the chunk size (little-endian UInt32).
    let sizeStart = markerRange.upperBound
    guard sizeStart + 4 <= data.count else { return [] }
    let chunkSize = readUInt32LE(data, at: sizeStart)

    let presetCount = Int(chunkSize) / headerSize
    let dataStart = sizeStart + 4  // skip 4-byte size field

    var instruments: [SoundFontInstrument] = []

    for i in 0..<presetCount {
      let offset = dataStart + i * headerSize
      guard offset + headerSize <= data.count else { break }

      // Read the null-terminated preset name from the first 20 bytes.
      var chars = [CChar](repeating: 0, count: nameLength + 1)
      for j in 0..<nameLength {
        chars[j] = CChar(bitPattern: data[offset + j])
      }
      let name = String(cString: chars)

      // Every SF2 ends with a sentinel record named "EOP" (End Of Presets).
      guard name != "EOP" else { continue }

      // Bytes 20–21: program (MIDI preset number), little-endian UInt16.
      let program = readUInt16LE(data, at: offset + 20)

      // Bytes 22–23: bank, little-endian UInt16.
      let bank = readUInt16LE(data, at: offset + 22)

      instruments.append(
        SoundFontInstrument(name: name, bank: bank, program: UInt8(program & 0x7F))
      )
    }

    return instruments.sorted { $0.name < $1.name }
  }

  // MARK: - Unaligned little-endian readers
  // Using byte-by-byte assembly avoids the alignment requirement of
  // UnsafeRawPointer.load(as:), which caused a fatal error on Data slices
  // that didn't happen to start at a naturally-aligned address.

  private static func readUInt16LE(_ data: Data, at offset: Int) -> UInt16 {
    UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
  }

  private static func readUInt32LE(_ data: Data, at offset: Int) -> UInt32 {
    UInt32(data[offset])
      | (UInt32(data[offset + 1]) << 8)
      | (UInt32(data[offset + 2]) << 16)
      | (UInt32(data[offset + 3]) << 24)
  }
}
