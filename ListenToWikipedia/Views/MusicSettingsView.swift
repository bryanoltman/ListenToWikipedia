import SwiftUI

struct MusicSettingsView: View {
  @EnvironmentObject private var settings: AppSettings

  @State private var instruments: [SoundFontInstrument] = []

  /// Instruments grouped by bank, sorted by bank number then instrument name.
  private var instrumentsByBank: [(bank: UInt16, instruments: [SoundFontInstrument])] {
    let grouped = Dictionary(grouping: instruments, by: \.bank)
    return grouped.keys.sorted().map { bank in
      (bank: bank, instruments: grouped[bank]!)
    }
  }

  var body: some View {
    Form {
      Section("Instruments") {
        if instruments.isEmpty {
          Text("Loading instruments…")
            .foregroundStyle(.secondary)
        } else {
          ForEach(EditSoundType.allCases) { type in
            Picker(
              type.displayName,
              selection: Binding<InstrumentId>(
                get: { settings.instrumentPrograms[type] ?? type.defaultInstrumentId },
                set: { settings.instrumentPrograms[type] = $0 }
              )
            ) {
              ForEach(instrumentsByBank, id: \.bank) { group in
                Section(bankDisplayName(group.bank)) {
                  ForEach(group.instruments) { instrument in
                    Text(instrument.name).tag(instrument.id)
                  }
                }
              }
            }
            #if os(iOS)
              .pickerStyle(.navigationLink)
            #endif
          }
        }
      }

      Section("Scale") {
        Picker("Key", selection: $settings.musicalKey) {
          ForEach(MusicalKey.allCases) { key in
            Text(key.rawValue).tag(key)
          }
        }

        Picker("Scale type", selection: $settings.scaleType) {
          ForEach(ScaleType.allCases) { scaleType in
            Text(scaleType.description).tag(scaleType)
          }
        }

        if settings.scaleType == .pentatonic {
          Picker("Mode", selection: $settings.pentatonicMode) {
            ForEach(PentatonicMode.allCases) { mode in
              Text(mode.rawValue).tag(mode)
            }
          }
        } else {
          Picker("Mode", selection: $settings.heptatonicMode) {
            ForEach(HeptatonicMode.allCases) { mode in
              Text(mode.rawValue).tag(mode)
            }
          }
        }

        Stepper(
          "Root octave: \(settings.rootOctave)",
          value: $settings.rootOctave,
          in: 0...8
        )

        Stepper(
          "Octave range: \(settings.octaveRange)",
          value: $settings.octaveRange,
          in: 1...4
        )
      }
    }
    .navigationTitle("Music")
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
    .task {
      guard instruments.isEmpty,
        let url = SoundFontParser.bundledSoundFontURL
      else { return }
      instruments = SoundFontParser.instruments(at: url)
    }
  }

  private func bankDisplayName(_ bank: UInt16) -> String {
    switch bank {
    case 0: return "General MIDI"
    case 128: return "GM Percussion"
    default: return "Bank \(bank)"
    }
  }
}

#Preview {
  NavigationStack {
    MusicSettingsView()
      .environmentObject(AppSettings.shared)
  }
}
