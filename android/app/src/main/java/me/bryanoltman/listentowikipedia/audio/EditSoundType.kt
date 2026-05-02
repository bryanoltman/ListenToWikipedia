package me.bryanoltman.listentowikipedia.audio

enum class EditSoundType(val displayName: String, val defaultProgram: Int) {
    ADDITION("Addition", 8),       // Celesta
    SUBTRACTION("Subtraction", 7), // Clavinet
    NEW_USER("New User", 89);      // Warm Pad

    val defaultMidiChannel: Int get() = ordinal // 0, 1, 2
}
