package me.bryanoltman.listentowikipedia.model

/// Categorizes Wikipedia events for instrument selection.
/// Default program numbers are General MIDI (GM) instruments that approximate
/// the SF2 presets used by the iOS app.
enum class EditSoundType(val displayName: String, val defaultProgram: Int) {
    ADDITION("Addition", 8),       // Celesta
    SUBTRACTION("Subtraction", 7), // Clavinet
    NEW_USER("New User", 89),      // Warm Pad
}
