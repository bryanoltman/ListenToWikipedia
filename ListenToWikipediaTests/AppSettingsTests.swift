import Testing

@testable import ListenToWikipedia

@MainActor
struct AppSettingsTests {
  @Test func resetToDefaults() {
    let settings = AppSettings.shared
    // Mutate settings
    settings.isMuted = true
    settings.scaleType = .heptatonic
    settings.musicalKey = .a
    settings.rootOctave = 5
    settings.octaveRange = 1

    settings.resetToDefaults()

    #expect(settings.isMuted == false)
    #expect(settings.scaleType == .pentatonic)
    #expect(settings.musicalKey == .fSharp)
    #expect(settings.heptatonicMode == .dorian)
    #expect(settings.pentatonicMode == .majorPentatonic)
    #expect(settings.rootOctave == 1)
    #expect(settings.octaveRange == 3)
    #expect(settings.selectedLanguageCodes == ["en"])
  }

  @Test func currentScaleProducesNotes() {
    let settings = AppSettings.shared
    settings.resetToDefaults()
    let scale = settings.currentScale
    #expect(!scale.isEmpty)
    #expect(scale.allSatisfy { $0 <= 127 })
  }

  @Test func currentScaleChangesWithKey() {
    let settings = AppSettings.shared
    settings.resetToDefaults()
    let scaleA = settings.currentScale

    settings.musicalKey = .c
    let scaleB = settings.currentScale

    #expect(scaleA != scaleB)

    // Restore to avoid polluting other tests
    settings.resetToDefaults()
  }

  @Test func currentScaleChangesWithMode() {
    let settings = AppSettings.shared
    settings.resetToDefaults()
    let scalePent = settings.currentScale

    settings.scaleType = .heptatonic
    let scaleHept = settings.currentScale

    #expect(scalePent != scaleHept)

    // Restore to avoid polluting other tests
    settings.resetToDefaults()
  }
}
