package me.bryanoltman.listentowikipedia.model

import kotlin.math.abs
import kotlin.math.ln
import kotlin.math.roundToInt

enum class MusicalMode(val displayName: String, val intervals: List<Int>) {
    IONIAN("Ionian (Major)", listOf(2, 2, 1, 2, 2, 2, 1)),
    DORIAN("Dorian", listOf(2, 1, 2, 2, 2, 1, 2)),
    PHRYGIAN("Phrygian", listOf(1, 2, 2, 2, 1, 2, 2)),
    LYDIAN("Lydian", listOf(2, 2, 2, 1, 2, 2, 1)),
    MIXOLYDIAN("Mixolydian", listOf(2, 2, 1, 2, 2, 1, 2)),
    AEOLIAN("Aeolian (Minor)", listOf(2, 1, 2, 2, 1, 2, 2)),
    LOCRIAN("Locrian", listOf(1, 2, 2, 1, 2, 2, 2)),
}

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

object MusicalScale {
    fun notes(root: Int, mode: MusicalMode, octaves: Int = 2): List<Int> {
        val result = mutableListOf(root)
        var current = root
        for (octave in 0 until octaves) {
            for (interval in mode.intervals) {
                current += interval
                if (current > 127) return result
                result.add(current)
            }
        }
        return result
    }

    fun noteForEdit(changeSize: Int, scale: List<Int>): Int? {
        if (scale.isEmpty()) return null
        val magnitude = abs(changeSize).coerceIn(1, 100000).toDouble()
        val normalized = ln(magnitude) / ln(100000.0)
        val scalePos = ((1.0 - normalized) * (scale.size - 1)).roundToInt()
        return scale[scalePos]
    }
}
