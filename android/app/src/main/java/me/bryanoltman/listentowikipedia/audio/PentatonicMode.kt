package me.bryanoltman.listentowikipedia.audio

enum class PentatonicMode(val displayName: String, val intervals: List<Int>) {
    MAJOR_PENTATONIC("Major Pentatonic", listOf(2, 2, 3, 2, 3)),
    EGYPTIAN("Egyptian", listOf(2, 3, 2, 3, 2)),
    BLUES_MINOR("Blues Minor", listOf(3, 2, 3, 2, 2)),
    BLUES_MAJOR("Blues Major", listOf(2, 3, 2, 2, 3)),
    MINOR_PENTATONIC("Minor Pentatonic", listOf(3, 2, 2, 3, 2))
}
