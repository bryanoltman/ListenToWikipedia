import SwiftUI

struct SettingsView: View {
  @EnvironmentObject private var settings: AppSettings
  @Environment(\.dismiss) private var dismiss
  @State private var isShowingResetConfirmation = false

  var body: some View {
    #if os(macOS)
      macOSBody
    #else
      formBody
    #endif
  }

  #if os(macOS)
    private var macOSBody: some View {
      TabView {
        VStack(spacing: 16) {
          GroupBox("Playback") {
            Form {
              Toggle("Mute", isOn: $settings.isMuted)
            }
          }
          GroupBox {
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
        .frame(width: 300)
        .fixedSize(horizontal: false, vertical: true)
        .padding(20)
        .tabItem { Label("General", systemImage: "gearshape") }

        GroupBox("Languages") {
          LanguagesToggleView()
        }
        .frame(width: 350, height: 400)
        .tabItem { Label("Languages", systemImage: "globe") }

        AudioSettingsView()
          .frame(width: 350, height: 400)
          .tabItem { Label("Audio", systemImage: "music.note") }

        AboutView()
          .tabItem { Label("About", systemImage: "info.circle") }
      }
    }
  #endif

  private var formBody: some View {
    NavigationStack {
      Form {
        NavigationLink("Languages") { LanguagesToggleView() }
        NavigationLink("Audio") { AudioSettingsView() }
        NavigationLink("About") { AboutView() }
        Toggle("Mute", isOn: $settings.isMuted)

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
      .navigationTitle("Settings")
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
  }
}

#Preview {
  Color.clear
    .sheet(isPresented: .constant(true)) {
      SettingsView()
    }
    .environmentObject(AppSettings.shared)
}
