package me.bryanoltman.listentowikipedia.audio

enum class MusicalKey(val displayName: String, val semitone: Int) {
    C("C", 0),
    C_SHARP("C#", 1),
    D("D", 2),
    D_SHARP("D#", 3),
    E("E", 4),
    F("F", 5),
    F_SHARP("F#", 6),
    G("G", 7),
    G_SHARP("G#", 8),
    A("A", 9),
    A_SHARP("A#", 10),
    B("B", 11);

    fun midiNote(octave: Int): Int = ((octave + 1) * 12 + semitone).coerceIn(0, 127)
}
