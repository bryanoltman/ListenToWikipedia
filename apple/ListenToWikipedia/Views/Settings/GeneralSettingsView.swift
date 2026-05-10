import SwiftUI

struct GeneralSettingsView: View {
  @EnvironmentObject private var settings: AppSettings
  @State private var isShowingResetConfirmation = false

  var body: some View {
    Form {
      Section("Playback") {
        Toggle("Mute", isOn: $settings.isMuted)
      }

      Section {
        Button("Reset to Defaults", role: .destructive) {
          isShowingResetConfirmation = true
        }
        .confirmationDialog(
          "Reset all settings to their defaults?",
          isPresented: $isShowingResetConfirmation,
          titleVisibility: .visible
        ) {
          Button("Reset", role: .destructive) {
            settings.resetToDefaults()
          }
        }
      }
    }
    .formStyle(.grouped)
  }
}

#Preview {
  GeneralSettingsView()
    .environmentObject(AppSettings.shared)
}
