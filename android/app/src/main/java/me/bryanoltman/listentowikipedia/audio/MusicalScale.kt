package me.bryanoltman.listentowikipedia.audio

import kotlin.math.abs
import kotlin.math.ln
import kotlin.math.roundToInt

object MusicalScale {
    fun notes(root: Int, intervals: List<Int>, octaves: Int = 2): List<Int> {
        val result = mutableListOf(root)
        var current = root
        repeat(octaves) {
            for (interval in intervals) {
                current += interval
                if (current > 127) return result
                result.add(current)
            }
        }
        return result
    }

    fun noteForEdit(changeSize: Int, scale: List<Int>): Int? {
        if (scale.isEmpty()) return null
        val minBytes = 1.0
        val maxBytes = 100_000.0
        val magnitude = abs(changeSize.toDouble()).coerceIn(minBytes, maxBytes)
        val normalized = ln(magnitude) / ln(maxBytes)
        val scalePos = ((1.0 - normalized) * (scale.size - 1)).roundToInt()
        return scale[scalePos]
    }
}
