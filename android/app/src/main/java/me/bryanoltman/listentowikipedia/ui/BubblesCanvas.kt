package me.bryanoltman.listentowikipedia.ui

import android.graphics.Typeface
import android.os.SystemClock
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.input.pointer.pointerInput
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import me.bryanoltman.listentowikipedia.ui.theme.DotGreen
import me.bryanoltman.listentowikipedia.ui.theme.DotGreenDark
import me.bryanoltman.listentowikipedia.ui.theme.DotPurple
import me.bryanoltman.listentowikipedia.ui.theme.DotPurpleDark
import me.bryanoltman.listentowikipedia.ui.theme.DotWhite
import me.bryanoltman.listentowikipedia.ui.theme.DotWhiteDark
import me.bryanoltman.listentowikipedia.networking.WikipediaEvent
import java.net.URLEncoder
import java.util.UUID
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt

data class Bubble(
    val id: String = UUID.randomUUID().toString(),
    val creationTime: Long, // SystemClock.elapsedRealtime()
    val normalizedX: Float,
    val normalizedY: Float,
    val color: Color,
    val labelColor: Color,
    val labelShadowColor: Color,
    val size: Float,
    val title: String,
    val articleUrl: String?
)

object BubblePhysics {
    const val LIFESPAN: Double = 9.0
    private const val ENTRANCE_DURATION: Double = 0.3
    private const val FADE_DURATION: Double = 3.0
    private const val FADE_START: Double = LIFESPAN - FADE_DURATION

    const val RIPPLE_COUNT: Int = 2
    private const val RIPPLE_DELAY: Double = 0.3
    private const val RIPPLE_DURATION: Double = 1.0
    private const val RIPPLE_EXPANSION_FACTOR: Double = 0.4

    const val TAP_ANIMATION_DURATION: Double = 0.25
    const val TAP_RIPPLE_DURATION: Double = 0.4

    /** Ease-out cubic scale from 0→1 over 0.3s. */
    fun scale(age: Double): Double {
        if (age >= ENTRANCE_DURATION) return 1.0
        val t = age / ENTRANCE_DURATION
        return 1.0 - (1.0 - t).pow(3)
    }

    /** Opacity fade: full until 6s, then linear fade to 0 at 9s. */
    fun opacity(age: Double): Double {
        if (age > FADE_START) {
            return max(0.0, 1.0 - (age - FADE_START) / FADE_DURATION)
        }
        return 1.0
    }

    /**
     * Returns (radius, opacity, lineWidth) for the given ripple ring, or null if inactive.
     * Ease-out quadratic expansion, opacity=0.4*(1-t), lineWidth=2.0-1.5*t.
     */
    fun rippleState(
        index: Int,
        age: Double,
        baseRadius: Double
    ): Triple<Double, Double, Double>? {
        val ringStart = index.toDouble() * RIPPLE_DELAY
        val ringAge = age - ringStart
        if (ringAge !in 0.0..RIPPLE_DURATION) return null

        val t = ringAge / RIPPLE_DURATION
        // Ease-out quadratic
        val easedT = 1.0 - (1.0 - t) * (1.0 - t)

        val radius = baseRadius + easedT * (baseRadius * RIPPLE_EXPANSION_FACTOR)
        val opacity = 0.4 * (1.0 - t)
        val lineWidth = 2.0 - 1.5 * t

        return Triple(radius, opacity, lineWidth)
    }

    /**
     * Maps a Wikipedia edit's byte-change magnitude to a bubble diameter.
     * radius = max(sqrt(abs(changeSize)) * scaleFactor, minRadius), return diameter clamped to maxSize.
     */
    fun size(changeSize: Int, maxSize: Float): Float {
        val referenceMaxSize = 800.0
        val scale = maxSize / referenceMaxSize
        val scaleFactor = 5.0 * scale
        val minRadius = max(15.0 * scale, 15.0)
        val magnitude = abs(changeSize).toDouble()
        val radius = max(sqrt(magnitude) * scaleFactor, minRadius)
        return min(radius * 2.0, maxSize.toDouble()).toFloat()
    }

    /** Scale pop: quick swell and settle using a sine curve. */
    fun tapScale(tapAge: Double): Double {
        if (tapAge !in 0.0..<TAP_ANIMATION_DURATION) return 1.0
        val t = tapAge / TAP_ANIMATION_DURATION
        return 1.0 + 0.1 * sin(t * PI)
    }

    /** White flash overlay opacity that fades out quickly. */
    fun tapFlashOpacity(tapAge: Double): Double {
        if (tapAge !in 0.0..<TAP_ANIMATION_DURATION) return 0.0
        val t = tapAge / TAP_ANIMATION_DURATION
        return 0.05 * (1.0 - t * t)
    }

    /** Expanding ring emitted from a tapped bubble, or null if inactive. */
    fun tapRippleState(
        tapAge: Double,
        baseRadius: Double
    ): Triple<Double, Double, Double>? {
        if (tapAge !in 0.0..<TAP_RIPPLE_DURATION) return null
        val t = tapAge / TAP_RIPPLE_DURATION
        val easedT = 1.0 - (1.0 - t) * (1.0 - t)
        val radius = baseRadius + easedT * baseRadius * 0.5
        val opacity = 0.35 * (1.0 - t)
        val lineWidth = 2.0 - 1.5 * t
        return Triple(radius, opacity, lineWidth)
    }
}

private val ShadowBlack60 = Color.Black.copy(alpha = 0.6f)
private val ShadowBlack85 = Color.Black.copy(alpha = 0.85f)

class BubbleManager {
    val bubbles = mutableStateListOf<Bubble>()
    var tappedBubbleId: String? = null
        private set
    var tapTime: Long = 0L
        private set
    var viewWidth = 400f
    var viewHeight = 400f

    fun addBubble(edit: WikipediaEvent.ArticleEdit) {
        val currentTime = SystemClock.elapsedRealtime()
        val isDeletion = edit.changeSize < 0
        val (fill, label, shadow) = bubbleColors(edit.isBot, edit.isAnonymous, isDeletion)
        val maxSize = max(viewWidth, viewHeight) * 2f / 3f
        val newBubble = Bubble(
            creationTime = currentTime,
            normalizedX = (0.05f + Math.random().toFloat() * 0.90f),
            normalizedY = (0.05f + Math.random().toFloat() * 0.90f),
            color = fill,
            labelColor = label,
            labelShadowColor = shadow,
            size = BubblePhysics.size(edit.changeSize, maxSize),
            title = edit.pageTitle,
            articleUrl = articleUrl(edit.language, edit.pageTitle)
        )
        bubbles.add(newBubble)
        // Prune expired inline
        val lifespanMs = (BubblePhysics.LIFESPAN * 1000).toLong()
        bubbles.removeAll { currentTime - it.creationTime > lifespanMs }
    }

    fun bubbleAt(x: Float, y: Float, currentTime: Long): Bubble? {
        for (bubble in bubbles.reversed()) {
            val ageMs = currentTime - bubble.creationTime
            if (ageMs < 0) continue
            val age = ageMs / 1000.0

            val currentScale = BubblePhysics.scale(age)
            val posX = bubble.normalizedX * viewWidth
            val posY = bubble.normalizedY * viewHeight
            val radius = (bubble.size * currentScale / 2).toFloat()

            val dx = x - posX
            val dy = y - posY
            if (sqrt((dx * dx + dy * dy).toDouble()) <= radius) {
                return bubble
            }
        }
        return null
    }

    fun recordTap(bubble: Bubble) {
        tappedBubbleId = bubble.id
        tapTime = SystemClock.elapsedRealtime()
    }

    fun pruneExpired() {
        val currentTime = SystemClock.elapsedRealtime()
        val lifespanMs = (BubblePhysics.LIFESPAN * 1000).toLong()
        bubbles.removeAll { currentTime - it.creationTime > lifespanMs }
    }

    private fun bubbleColors(
        isBot: Boolean,
        isAnonymous: Boolean,
        isDeletion: Boolean
    ): Triple<Color, Color, Color> {
        if (isBot) {
            return if (isDeletion)
                Triple(DotPurpleDark, DotPurple, ShadowBlack60)
            else
                Triple(DotPurple, Color.White, ShadowBlack60)
        }
        if (isAnonymous) {
            return if (isDeletion)
                Triple(DotGreenDark, DotGreen, ShadowBlack60)
            else
                Triple(DotGreen, Color.White, ShadowBlack60)
        }
        return if (isDeletion)
            Triple(DotWhiteDark, DotWhite, ShadowBlack60)
        else
            Triple(DotWhite, Color.White, ShadowBlack85)
    }

    private fun articleUrl(language: String, pageTitle: String): String {
        val encodedTitle = URLEncoder.encode(
            pageTitle.replace(" ", "_"),
            "UTF-8"
        )
        return "https://$language.wikipedia.org/wiki/$encodedTitle"
    }
}

@Composable
fun BubblesCanvas(manager: BubbleManager, onBubbleTap: (Bubble) -> Unit) {
    // Frame clock: drives continuous Canvas redraws for animation.
    // Reading `currentTimeMs` inside the Canvas draw scope subscribes the
    // draw phase to this state, so every frame update triggers a re-draw.
    var currentTimeMs by remember { mutableLongStateOf(SystemClock.elapsedRealtime()) }

    LaunchedEffect(Unit) {
        while (isActive) {
            withFrameNanos { _ -> currentTimeMs = SystemClock.elapsedRealtime() }
        }
    }

    // Prune timer
    LaunchedEffect(Unit) {
        while (isActive) {
            delay(1000)
            manager.pruneExpired()
        }
    }

    val textPaint = remember {
        android.graphics.Paint().apply {
            isAntiAlias = true
            textAlign = android.graphics.Paint.Align.CENTER
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }
    }

    Canvas(
        modifier = Modifier
            .fillMaxSize()
            .pointerInput(Unit) {
                detectTapGestures { offset ->
                    val now = SystemClock.elapsedRealtime()
                    manager.viewWidth = size.width.toFloat()
                    manager.viewHeight = size.height.toFloat()
                    val bubble = manager.bubbleAt(offset.x, offset.y, now)
                    if (bubble != null) {
                        manager.recordTap(bubble)
                        onBubbleTap(bubble)
                    }
                }
            }
    ) {
        manager.viewWidth = size.width
        manager.viewHeight = size.height

        // Read the frame-driven state to subscribe this draw scope to updates
        val frameTime = currentTimeMs
        val density = this@Canvas

        // Scale text size for density (~9sp equivalent like iOS caption2)
        val scaledTextSize = 9f * density.density * density.fontScale
        for (bubble in manager.bubbles) {
            val ageMs = frameTime - bubble.creationTime
            if (ageMs < 0) continue
            val age = ageMs / 1000.0

            val opacity = BubblePhysics.opacity(age)
            if (opacity <= 0) continue

            val scale = BubblePhysics.scale(age)
            val posX = bubble.normalizedX * size.width
            val posY = bubble.normalizedY * size.height
            val center = Offset(posX, posY)

            val baseRadius = (bubble.size * scale / 2).toFloat()

            // --- Ripple rings ---
            for (ringIndex in 0 until BubblePhysics.RIPPLE_COUNT) {
                val ring = BubblePhysics.rippleState(ringIndex, age, baseRadius.toDouble())
                    ?: continue

                val (ringRadius, ringOpacity, ringLineWidth) = ring
                drawCircle(
                    color = bubble.color.copy(alpha = (ringOpacity * opacity).toFloat()),
                    radius = ringRadius.toFloat(),
                    center = center,
                    style = Stroke(width = ringLineWidth.toFloat())
                )
            }

            // --- Tap response ---
            var tapScaleMultiplier = 1.0
            var tapFlash = 0.0
            var tapAgeSeconds: Double? = null
            if (bubble.id == manager.tappedBubbleId) {
                val elapsed = (frameTime - manager.tapTime) / 1000.0
                tapAgeSeconds = elapsed
                tapScaleMultiplier = BubblePhysics.tapScale(elapsed)
                tapFlash = BubblePhysics.tapFlashOpacity(elapsed)
            }

            // --- Filled circle with shadow ---
            val drawSize = (bubble.size * scale * tapScaleMultiplier).toFloat()
            val drawRadius = drawSize / 2f

            // Shadow behind bubble
            drawCircle(
                color = Color.Black.copy(alpha = (0.3f * opacity).toFloat()),
                radius = drawRadius + 2f,
                center = center.copy(y = center.y + 1f)
            )

            // Main filled circle
            drawCircle(
                color = bubble.color.copy(alpha = opacity.toFloat()),
                radius = drawRadius,
                center = center
            )

            // --- Tap flash overlay ---
            if (tapFlash > 0) {
                drawCircle(
                    color = Color.White.copy(alpha = (tapFlash * opacity).toFloat()),
                    radius = drawRadius,
                    center = center
                )
            }

            // --- Tap ripple ---
            if (tapAgeSeconds != null) {
                val tapRing = BubblePhysics.tapRippleState(tapAgeSeconds, baseRadius.toDouble())
                if (tapRing != null) {
                    val (tapRingRadius, tapRingOpacity, tapRingLineWidth) = tapRing
                    drawCircle(
                        color = Color.White.copy(alpha = (tapRingOpacity * opacity).toFloat()),
                        radius = tapRingRadius.toFloat(),
                        center = center,
                        style = Stroke(width = tapRingLineWidth.toFloat())
                    )
                }
            }

            // --- Title label with shadow ---
            drawContext.canvas.nativeCanvas.let { canvas ->
                textPaint.textSize = scaledTextSize
                textPaint.color = android.graphics.Color.argb(
                    (bubble.labelColor.alpha * opacity).toFloat(),
                    bubble.labelColor.red,
                    bubble.labelColor.green,
                    bubble.labelColor.blue
                )


                // Draw text with shadow layer for glow effect
                textPaint.setShadowLayer(
                    3f * density.density,
                    0f,
                    0f,
                    android.graphics.Color.argb(
                        (bubble.labelShadowColor.alpha * opacity).toFloat(),
                        bubble.labelShadowColor.red,
                        bubble.labelShadowColor.green,
                        bubble.labelShadowColor.blue
                    )
                )
                canvas.drawText(bubble.title, posX, posY + scaledTextSize / 3f, textPaint)
            }
        }
    }
}
