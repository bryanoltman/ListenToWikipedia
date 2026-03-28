package me.bryanoltman.listentowikipedia.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Paint
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.android.awaitFrame
import kotlin.math.PI
import kotlin.math.sin
import kotlin.math.sqrt

@Composable
fun BubblesCanvas(
    bubbles: List<Bubble>,
    onBubbleTap: (Bubble) -> Unit,
    tappedBubbleId: String?,
    tapTimeNanos: Long,
    modifier: Modifier = Modifier
) {
    val textMeasurer = rememberTextMeasurer()

    // Continuously request animation frames to re-read System.nanoTime()
    val currentNanos by produceState(System.nanoTime()) {
        while (true) {
            awaitFrame()
            value = System.nanoTime()
        }
    }

    Canvas(
        modifier = modifier
            .fillMaxSize()
            .pointerInput(bubbles) {
                detectTapGestures { offset ->
                    val canvasW = size.width.toFloat()
                    val canvasH = size.height.toFloat()
                    val now = System.nanoTime()
                    // Hit-test in reverse order (topmost first)
                    for (bubble in bubbles.asReversed()) {
                        val age = (now - bubble.creationTimeNanos) / 1_000_000_000.0
                        if (age < 0) continue
                        val scale = BubblePhysics.entranceScale(age)
                        val cx = BubblePhysics.positionX(bubble.normalizedX, canvasW)
                        val cy = BubblePhysics.positionY(bubble.normalizedY, canvasH)
                        val radius = (bubble.size * scale) / 2f
                        val dx = offset.x - cx
                        val dy = offset.y - cy
                        if (sqrt(dx * dx + dy * dy) <= radius) {
                            onBubbleTap(bubble)
                            break
                        }
                    }
                }
            }
    ) {
        val canvasW = size.width
        val canvasH = size.height

        for (bubble in bubbles) {
            val age = (currentNanos - bubble.creationTimeNanos) / 1_000_000_000.0
            if (age < 0) continue

            val opacity = BubblePhysics.opacity(age)
            if (opacity <= 0f) continue

            val scale = BubblePhysics.entranceScale(age)
            val cx = BubblePhysics.positionX(bubble.normalizedX, canvasW)
            val cy = BubblePhysics.positionY(bubble.normalizedY, canvasH)
            var drawSize = bubble.size * scale

            // Tap effects
            val isTapped = tappedBubbleId == bubble.id
            var tapFlashAlpha = 0f
            var tapRingProgress: Float? = null
            if (isTapped) {
                val tapAge = (currentNanos - tapTimeNanos) / 1_000_000_000.0
                // Scale pop (0–0.25s)
                if (tapAge in 0.0..BubblePhysics.TAP_SCALE_DURATION) {
                    val popFactor = 1f + BubblePhysics.TAP_SCALE_AMOUNT *
                        sin(tapAge / BubblePhysics.TAP_SCALE_DURATION * PI).toFloat()
                    drawSize *= popFactor
                }
                // White flash (0–0.25s)
                if (tapAge in 0.0..BubblePhysics.TAP_FLASH_DURATION) {
                    tapFlashAlpha = BubblePhysics.TAP_FLASH_OPACITY *
                        (1f - (tapAge / BubblePhysics.TAP_FLASH_DURATION).toFloat())
                }
                // Expanding ring (0–0.4s)
                if (tapAge in 0.0..BubblePhysics.TAP_RING_DURATION) {
                    tapRingProgress = (tapAge / BubblePhysics.TAP_RING_DURATION).toFloat()
                }
            }

            val radius = drawSize / 2f

            // Draw ripple rings before the filled circle
            for (ringIndex in 0 until BubblePhysics.RIPPLE_COUNT) {
                val progress = BubblePhysics.rippleProgress(ringIndex, age) ?: continue
                val eased = BubblePhysics.easeOutQuad(progress)
                val ringRadius = radius * (1f + BubblePhysics.RIPPLE_EXPANSION * eased)
                val ringOpacity = BubblePhysics.RIPPLE_START_OPACITY * (1f - eased) * opacity
                val ringWidth = BubblePhysics.RIPPLE_START_LINE_WIDTH +
                    (BubblePhysics.RIPPLE_END_LINE_WIDTH - BubblePhysics.RIPPLE_START_LINE_WIDTH) * eased
                drawCircle(
                    color = bubble.fillColor.copy(alpha = ringOpacity),
                    radius = ringRadius,
                    center = Offset(cx, cy),
                    style = Stroke(width = ringWidth)
                )
            }

            // Draw filled circle with subtle shadow matching iOS
            // (.shadow(color: .black.opacity(0.3), radius: 4))
            drawIntoCanvas { canvas ->
                val paint = Paint().also { p ->
                    p.color = bubble.fillColor.copy(alpha = opacity)
                    p.asFrameworkPaint().setShadowLayer(
                        4f * density,  // blur radius in px (4dp)
                        0f,
                        0f,
                        android.graphics.Color.argb((0.3f * opacity * 255).toInt(), 0, 0, 0)
                    )
                }
                canvas.drawCircle(Offset(cx, cy), radius, paint)
            }

            // White flash overlay for tap
            if (tapFlashAlpha > 0f) {
                drawCircle(
                    color = Color.White.copy(alpha = tapFlashAlpha),
                    radius = radius,
                    center = Offset(cx, cy)
                )
            }

            // Expanding ring for tap
            if (tapRingProgress != null) {
                val eased = BubblePhysics.easeOutQuad(tapRingProgress)
                val tapRingRadius = radius * (1f + 0.5f * eased)
                val tapRingOpacity = opacity * (1f - eased)
                drawCircle(
                    color = bubble.fillColor.copy(alpha = tapRingOpacity),
                    radius = tapRingRadius,
                    center = Offset(cx, cy),
                    style = Stroke(width = 2f * (1f - eased).coerceAtLeast(0.1f))
                )
            }

            // Draw title text with shadow
            val style = TextStyle(
                color = bubble.labelColor.copy(alpha = opacity),
                fontSize = 9.sp,
                fontWeight = FontWeight.SemiBold
            )
            val shadowStyle = TextStyle(
                color = bubble.labelShadowColor.copy(alpha = opacity),
                fontSize = 9.sp,
                fontWeight = FontWeight.SemiBold
            )
            val textLayout = textMeasurer.measure(
                text = bubble.title,
                style = style,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                constraints = androidx.compose.ui.unit.Constraints(
                    maxWidth = drawSize.toInt().coerceAtLeast(1)
                )
            )
            val shadowLayout = textMeasurer.measure(
                text = bubble.title,
                style = shadowStyle,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                constraints = androidx.compose.ui.unit.Constraints(
                    maxWidth = drawSize.toInt().coerceAtLeast(1)
                )
            )
            val textX = cx - textLayout.size.width / 2f
            val textY = cy - textLayout.size.height / 2f

            // Shadow: draw offset copies at ±1px in each direction
            for (dx in listOf(-1f, 0f, 1f)) {
                for (dy in listOf(-1f, 0f, 1f)) {
                    if (dx == 0f && dy == 0f) continue
                    drawText(
                        textLayoutResult = shadowLayout,
                        topLeft = Offset(textX + dx, textY + dy)
                    )
                }
            }

            // Label text
            drawText(
                textLayoutResult = textLayout,
                topLeft = Offset(textX, textY)
            )
        }
    }
}
