package me.bryanoltman.listentowikipedia.ui

import androidx.compose.ui.graphics.Color
import me.bryanoltman.listentowikipedia.model.WikipediaArticleEdit
import me.bryanoltman.listentowikipedia.ui.theme.*
import java.net.URLEncoder
import java.util.UUID
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.exp
import kotlin.math.log10
import kotlin.math.min

data class Bubble(
    val id: String = UUID.randomUUID().toString(),
    val creationTimeNanos: Long,   // System.nanoTime()
    val normalizedX: Float,        // 0.05..0.95
    val normalizedY: Float,        // 0.05..0.95
    val fillColor: Color,
    val labelColor: Color,
    val size: Float,               // diameter in px
    val title: String,
    val articleUrl: String?
)

object BubblePhysics {
    const val INITIAL_UPWARD_SPEED = 15f
    const val UPWARD_ACCELERATION = 45f
    const val LIFESPAN = 4.0  // seconds

    /** Damped cosine bounce scale over the first 0.4s. */
    fun scale(age: Double): Float {
        val bounceDuration = 0.4
        if (age > bounceDuration) return 1f
        val t = age / bounceDuration
        return (1.0 - cos(t * Math.PI * 3.0) * exp(-t * 5.0)).toFloat()
    }

    /** Vertical position: starts at normalizedY, moves upward via kinematics. */
    fun positionY(startNormalizedY: Float, age: Double, canvasHeight: Float): Float {
        val startY = startNormalizedY * canvasHeight
        val dist = (INITIAL_UPWARD_SPEED * age + 0.5 * UPWARD_ACCELERATION * age * age).toFloat()
        return startY - dist
    }

    /** Maps edit magnitude to bubble diameter, log scale, clamped to maxSize. */
    fun bubbleSize(changeSize: Int, maxSize: Float): Float {
        val magnitude = abs(changeSize).toFloat()
        val scaled = 20f + 50f * log10(1f + magnitude)
        return min(scaled, maxSize)
    }

    /** Opacity: full until last 1.5s, then linear fade to 0. */
    fun opacity(age: Double): Float {
        val fadeDuration = 1.5
        val fadeStart = LIFESPAN - fadeDuration
        return if (age > fadeStart) {
            maxOf(0f, (1.0 - (age - fadeStart) / fadeDuration).toFloat())
        } else {
            1f
        }
    }
}

/** Returns (fillColor, labelColor) for a bubble based on edit type. */
fun bubbleColors(edit: WikipediaArticleEdit): Pair<Color, Color> {
    val isDeletion = edit.changeSize < 0
    return when {
        edit.isBot -> if (isDeletion) Pair(BubbleDarkPurple, BubblePurple) else Pair(BubblePurple, BubbleDarkPurple)
        edit.isAnonymous -> if (isDeletion) Pair(BubbleDarkGreen, BubbleGreen) else Pair(BubbleGreen, BubbleDarkGreen)
        else -> if (isDeletion) Pair(BubbleDarkWhite, BubbleWhite) else Pair(BubbleWhite, BubbleDarkWhite)
    }
}

/** Constructs the Wikipedia article URL for the given edit. */
fun articleUrl(language: String, pageTitle: String): String {
    val encoded = URLEncoder.encode(pageTitle.replace(" ", "_"), "UTF-8")
    return "https://$language.wikipedia.org/wiki/$encoded"
}
