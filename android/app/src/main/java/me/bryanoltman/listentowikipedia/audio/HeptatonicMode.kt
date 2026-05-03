package me.bryanoltman.listentowikipedia.audio

enum class HeptatonicMode(val displayName: String, val intervals: List<Int>) {
    IONIAN("Ionian (Major)", listOf(2, 2, 1, 2, 2, 2, 1)),
    DORIAN("Dorian", listOf(2, 1, 2, 2, 2, 1, 2)),
    PHRYGIAN("Phrygian", listOf(1, 2, 2, 2, 1, 2, 2)),
    LYDIAN("Lydian", listOf(2, 2, 2, 1, 2, 2, 1)),
    MIXOLYDIAN("Mixolydian", listOf(2, 2, 1, 2, 2, 1, 2)),
    AEOLIAN("Aeolian (Minor)", listOf(2, 1, 2, 2, 1, 2, 2)),
    LOCRIAN("Locrian", listOf(1, 2, 2, 1, 2, 2, 2))
}
