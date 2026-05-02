package me.bryanoltman.listentowikipedia.audio

enum class ScaleType(val noteCount: Int, val displayName: String) {
    PENTATONIC(5, "Pentatonic (5-note)"),
    HEPTATONIC(7, "Heptatonic (7-note)")
}
