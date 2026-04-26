import SwiftUI

struct AudioSettingsView: View {
  @EnvironmentObject private var settings: AppSettings

  private var instruments: [SoundFontInstrument] { SoundFontParser.bundledInstruments }
  private var instrumentsByBank: [(bank: UInt16, instruments: [SoundFontInstrument])] {
    SoundFontParser.bundledInstrumentsByBank
  }
  #if os(macOS)
    @State private var activeInstrumentPicker: EditSoundType?
  #endif

  var body: some View {
    #if os(iOS)
      iOSBody
    #elseif os(macOS)
      macOSBody
    #elseif os(tvOS)
      tvOSBody
    #endif
  }

  #if os(iOS)
    private var iOSBody: some View {
      Form {
        Section("Instruments") {
          ForEach(EditSoundType.allCases) { type in
            let selection = Binding<InstrumentId>(
              get: { settings.instrumentPrograms[type] ?? type.defaultInstrumentId },
              set: { settings.instrumentPrograms[type] = $0 }
            )
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
      .navigationTitle("Audio")
      .navigationBarTitleDisplayMode(.inline)
    }
  #endif

  #if os(macOS)
    private var macOSBody: some View {
      VStack(alignment: .leading, spacing: 16) {
        GroupBox("Instruments") {
          Form {
            ForEach(EditSoundType.allCases) { type in
              LabeledContent(type.displayName) {
                Button(instrumentName(for: type)) {
                  activeInstrumentPicker = type
                }
                .popover(
                  isPresented: Binding(
                    get: { activeInstrumentPicker == type },
                    set: { if !$0 { activeInstrumentPicker = nil } }
                  )
                ) {
                  InstrumentPickerView(
                    selection: Binding<InstrumentId>(
                      get: { settings.instrumentPrograms[type] ?? type.defaultInstrumentId },
                      set: { settings.instrumentPrograms[type] = $0 }
                    ),
                    instrumentsByBank: instrumentsByBank
                  )
                  .frame(width: 300, height: 500)
                }
              }
            }
          }
          .padding(.vertical, 4)
        }

        GroupBox("Scale") {
          Form {
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
          .padding(.vertical, 4)
        }
      }
      .padding([.bottom, .trailing, .leading], 20)
      .padding([.top], 10)
      .fixedSize(horizontal: false, vertical: true)
    }
  #endif

  private var tvOSBody: some View {
    Form {
      Section("Instruments") {
        ForEach(EditSoundType.allCases) { type in
          let selection = Binding<InstrumentId>(
            get: { settings.instrumentPrograms[type] ?? type.defaultInstrumentId },
            set: { settings.instrumentPrograms[type] = $0 }
          )
          NavigationLink {
            InstrumentPickerView(
              selection: selection,
              instrumentsByBank: instrumentsByBank
            )
            .navigationTitle(type.displayName)
          } label: {
            LabeledContent(type.displayName) {
              Text(instrumentName(for: type))
                .foregroundStyle(.secondary)
            }
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

//        Stepper(
//          "Root octave: \(settings.rootOctave)",
//          value: $settings.rootOctave,
//          in: 0...8
//        )
//
//        Stepper(
//          "Octave range: \(settings.octaveRange)",
//          value: $settings.octaveRange,
//          in: 1...4
//        )
      }
    }
    .navigationTitle("Audio")
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
    AudioSettingsView()
      .environmentObject(AppSettings.shared)
  }
}
