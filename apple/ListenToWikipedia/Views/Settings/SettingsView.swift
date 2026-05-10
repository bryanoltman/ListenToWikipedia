import SwiftUI

#if os(macOS)
  /// Sidebar sections for the macOS master-detail settings layout.
  private enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case languages
    case audio
    case about

    var id: String { rawValue }

    var title: String {
      switch self {
      case .general: return "General"
      case .languages: return "Languages"
      case .audio: return "Audio"
      case .about: return "About"
      }
    }

    var icon: String {
      switch self {
      case .general: return "gearshape"
      case .languages: return "globe"
      case .audio: return "music.note"
      case .about: return "info.circle"
      }
    }
  }
#endif

struct SettingsView: View {
  @EnvironmentObject private var settings: AppSettings
  @Environment(\.dismiss) private var dismiss
  @State private var isShowingResetConfirmation = false

  #if os(macOS)
    @State private var selectedSection = SettingsSection.general
  #endif

  var body: some View {
    #if os(macOS)
      macOSBody
    #else
      formBody
    #endif
  }

  #if os(macOS)
    private var macOSBody: some View {
      HStack(spacing: 0) {
        VStack(alignment: .leading, spacing: 2) {
          ForEach(SettingsSection.allCases) { section in
            Button {
              selectedSection = section
            } label: {
              Label(section.title, systemImage: section.icon)
                .foregroundStyle(selectedSection == section ? .white : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(
                  RoundedRectangle(cornerRadius: 5)
                    .fill(selectedSection == section ? Color.accentColor : Color.clear)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
          }
          Spacer()
        }
        .padding(8)
        .frame(width: 180)

        Divider()

        detailContent(for: selectedSection)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      }
      .frame(width: 600, height: 450)
    }

    @ViewBuilder
    private func detailContent(for section: SettingsSection) -> some View {
      switch section {
      case .general:
        GeneralSettingsView()
      case .languages:
        LanguagesToggleView()
      case .audio:
        AudioSettingsView()
      case .about:
        AboutView()
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
