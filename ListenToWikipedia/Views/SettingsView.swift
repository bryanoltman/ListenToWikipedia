import SwiftUI

struct SettingsView: View {
  @Environment(\.dismiss) var dismiss

  var body: some View {
    NavigationStack {
      Form {
        Section(header: Text("Bubble Settings")) {
          Text("Settings options go here...")
        }
      }
      .navigationTitle("Settings")
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
    #if os(macOS)
      .frame(width: 350, height: 250)
      .padding()
    #endif
  }
}
