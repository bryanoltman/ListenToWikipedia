package me.bryanoltman.listentowikipedia.ui

import androidx.compose.ui.graphics.Color
import me.bryanoltman.listentowikipedia.model.WikipediaArticleEdit
import me.bryanoltman.listentowikipedia.ui.theme.*
import java.net.URLEncoder
import java.util.UUID
import kotlin.math.abs
import kotlin.math.ln
import kotlin.math.sqrt

data class Bubble(
    val id: String = UUID.randomUUID().toString(),
    val creationTimeNanos: Long,   // System.nanoTime()
    val normalizedX: Float,        // 0.05..0.95
    val normalizedY: Float,        // 0.05..0.95
    val fillColor: Color,
    val labelColor: Color,
    val labelShadowColor: Color,
    val size: Float,               // diameter in px
    val title: String,
    val articleUrl: String?
)

object BubblePhysics {
    const val LIFESPAN = 9.0  // seconds

    // Ripple ring parameters
    const val RIPPLE_COUNT = 2
    const val RIPPLE_STAGGER = 0.3    // seconds between rings
    const val RIPPLE_DURATION = 1.0   // seconds per ring
    const val RIPPLE_EXPANSION = 0.4f  // fraction of bubble radius
    const val RIPPLE_START_OPACITY = 0.4f
    const val RIPPLE_START_LINE_WIDTH = 2f
    const val RIPPLE_END_LINE_WIDTH = 0.5f

    // Tap feedback parameters
    const val TAP_SCALE_DURATION = 0.25  // seconds
    const val TAP_SCALE_AMOUNT = 0.10f   // +10%
    const val TAP_FLASH_DURATION = 0.25  // seconds
    const val TAP_FLASH_OPACITY = 0.05f
    const val TAP_RING_DURATION = 0.4    // seconds

    /// Ease-out cubic entrance: 0→1 over 0.3s
    fun entranceScale(age: Double): Float {
        val duration = 0.3
        if (age >= duration) return 1f
        val t = (age / duration).toFloat()
        return 1f - (1f - t) * (1f - t) * (1f - t)  // ease-out cubic
    }

    /// Static position — no drift. Returns normalizedX * canvasWidth (or Y).
    fun positionX(normalizedX: Float, canvasWidth: Float): Float = normalizedX * canvasWidth
    fun positionY(normalizedY: Float, canvasHeight: Float): Float = normalizedY * canvasHeight

    /// Full opacity 0–6s, linear fade 6–9s.
    fun opacity(age: Double): Float {
        val fadeStart = LIFESPAN - 3.0  // 6.0
        return if (age <= fadeStart) 1f
        else maxOf(0f, (1.0 - (age - fadeStart) / 3.0).toFloat())
    }

    /// Maps edit magnitude to bubble diameter.
    ///
    /// Uses logarithmic scaling so small-to-medium edits still produce
    /// visually meaningful bubbles. The range [1, 100_000] bytes maps
    /// linearly (in log space) to [minRadiusPx, maxDiameter / 2].
    /// Returns diameter, capped at maxDiameter.
    fun bubbleSize(changeSize: Int, maxDiameter: Float, minRadiusPx: Float): Float {
        val maxRadius = maxDiameter / 2f
        val magnitude = abs(changeSize).coerceIn(1, 100_000).toDouble()
        val normalized = ln(magnitude) / ln(100_000.0) // 0..1
        val radius = (minRadiusPx + normalized.toFloat() * (maxRadius - minRadiusPx))
        return minOf(radius * 2f, maxDiameter)
    }

    /// Ripple ring progress for ring index (0 or 1) at given bubble age.
    /// Returns null if the ring hasn't started or has finished.
    fun rippleProgress(ringIndex: Int, age: Double): Float? {
        val ringStart = ringIndex * RIPPLE_STAGGER
        val ringAge = age - ringStart
        if (ringAge < 0 || ringAge > RIPPLE_DURATION) return null
        return (ringAge / RIPPLE_DURATION).toFloat()
    }

    /// Ease-out quadratic: t -> 1 - (1-t)^2
    fun easeOutQuad(t: Float): Float {
        return 1f - (1f - t) * (1f - t)
    }
}

/** Returns (fillColor, labelColor, labelShadowColor) for a bubble based on edit type. */
fun bubbleColors(edit: WikipediaArticleEdit): Triple<Color, Color, Color> {
    val isDeletion = edit.changeSize < 0
    val (fillColor, labelColor) = when {
        edit.isBot -> if (isDeletion) Pair(BubbleDarkPurple, BubblePurple) else Pair(BubblePurple, BubbleDarkPurple)
        edit.isAnonymous -> if (isDeletion) Pair(BubbleDarkGreen, BubbleGreen) else Pair(BubbleGreen, BubbleDarkGreen)
        else -> if (isDeletion) Pair(BubbleDarkWhite, BubbleWhite) else Pair(BubbleWhite, BubbleDarkWhite)
    }
    return Triple(fillColor, labelColor, fillColor.copy(alpha = 0.5f))
}

/** Constructs the Wikipedia article URL for the given edit. */
fun articleUrl(language: String, pageTitle: String): String {
    val encoded = URLEncoder.encode(pageTitle.replace(" ", "_"), "UTF-8")
    return "https://$language.wikipedia.org/wiki/$encoded"
}
