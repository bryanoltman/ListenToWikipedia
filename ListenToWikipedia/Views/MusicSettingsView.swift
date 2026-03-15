import SwiftUI

struct MusicSettingsView: View {
  @EnvironmentObject private var settings: AppSettings

  @State private var instruments: [SoundFontInstrument] = []

  private var selectedInstrument: SoundFontInstrument? {
    instruments.first { $0.program == settings.selectedInstrumentProgram }
  }

  var body: some View {
    Form {
      Section("Playback") {
        Toggle("Mute", isOn: $settings.isMuted)
      }

      Section("Instrument") {
        if instruments.isEmpty {
          Text("Loading instruments…")
            .foregroundStyle(.secondary)
        } else {
          Picker("Instrument", selection: $settings.selectedInstrumentProgram) {
            ForEach(instruments) { instrument in
              Text(instrument.name).tag(instrument.program)
            }
          }
          #if os(iOS)
            .pickerStyle(.navigationLink)
          #endif
        }
      }

      Section("Scale") {
        Picker("Key", selection: $settings.musicalKey) {
          ForEach(MusicalKey.allCases) { key in
            Text(key.rawValue).tag(key)
          }
        }

        Picker("Mode", selection: $settings.musicalMode) {
          ForEach(MusicalMode.allCases) { mode in
            Text(mode.rawValue).tag(mode)
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
