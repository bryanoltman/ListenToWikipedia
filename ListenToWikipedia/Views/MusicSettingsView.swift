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
            let selection = Binding<InstrumentId>(
              get: { settings.instrumentPrograms[type] ?? type.defaultInstrumentId },
              set: { settings.instrumentPrograms[type] = $0 }
            )
            #if os(iOS)
              NavigationLink {
                InstrumentPickerView(
                  selection: selection,
                  instrumentsByBank: instrumentsByBank
                )
                .navigationTitle(type.displayName)
                .navigationBarTitleDisplayMode(.inline)
              } label: {
                LabeledContent(type.displayName) {
                  Text(instrumentName(for: type))
                    .foregroundStyle(.secondary)
                }
              }
            #else
              Picker(type.displayName, selection: selection) {
                ForEach(instrumentsByBank, id: \.bank) { group in
                  Section(bankDisplayName(group.bank)) {
                    ForEach(group.instruments) { instrument in
                      Text(instrument.name).tag(instrument.id)
                    }
                  }
                }
              }
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

  /// Display name of the currently selected instrument for `type`.
  private func instrumentName(for type: EditSoundType) -> String {
    let id = settings.instrumentPrograms[type] ?? type.defaultInstrumentId
    return instruments.first { $0.id == id }?.name ?? "Unknown"
  }
}

private func bankDisplayName(_ bank: UInt16) -> String {
  switch bank {
  case 0: return "General MIDI"
  case 128: return "GM Percussion"
  default: return "Bank \(bank)"
  }
}

// MARK: -

/// A List-based picker that groups instruments by bank with proper section headers.
/// Replaces `Picker(.navigationLink)` which flattens sections on iOS.
private struct InstrumentPickerView: View {
  @Binding var selection: InstrumentId
  let instrumentsByBank: [(bank: UInt16, instruments: [SoundFontInstrument])]

  var body: some View {
    List {
      ForEach(instrumentsByBank, id: \.bank) { group in
        Section(bankDisplayName(group.bank)) {
          ForEach(group.instruments) { instrument in
            Button {
              selection = instrument.id
            } label: {
              HStack {
                Text(instrument.name)
                  .foregroundStyle(.primary)
                Spacer()
                if instrument.id == selection {
                  Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
                    .fontWeight(.semibold)
                }
              }
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    MusicSettingsView()
      .environmentObject(AppSettings.shared)
  }
}
