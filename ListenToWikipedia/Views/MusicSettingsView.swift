import SwiftUI

struct MusicSettingsView: View {
  @EnvironmentObject private var settings: AppSettings

  @State private var instruments: [SoundFontInstrument] = []

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
              selection: Binding<UInt8>(
                get: { settings.instrumentPrograms[type] ?? type.defaultProgram },
                set: { settings.instrumentPrograms[type] = $0 }
              )
            ) {
              ForEach(instruments) { instrument in
                Text(instrument.name).tag(instrument.program)
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
}

#Preview {
  NavigationStack {
    MusicSettingsView()
      .environmentObject(AppSettings.shared)
  }
}
