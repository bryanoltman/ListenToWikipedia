package me.bryanoltman.listentowikipedia.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.android.awaitFrame
import kotlin.math.sqrt

@Composable
fun BubblesCanvas(
    bubbles: List<Bubble>,
    onBubbleTap: (Bubble) -> Unit,
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
                        val scale = BubblePhysics.scale(age)
                        val cx = bubble.normalizedX * canvasW
                        val cy = BubblePhysics.positionY(bubble.normalizedY, age, canvasH)
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

            val scale = BubblePhysics.scale(age)
            val cx = bubble.normalizedX * canvasW
            val cy = BubblePhysics.positionY(bubble.normalizedY, age, canvasH)
            val drawSize = bubble.size * scale
            val radius = drawSize / 2f

            // Draw circle
            drawCircle(
                color = bubble.fillColor.copy(alpha = opacity),
                radius = radius,
                center = Offset(cx, cy)
            )

            // Draw title text centered in bubble
            val style = TextStyle(
                color = bubble.labelColor.copy(alpha = opacity),
                fontSize = 9.sp,
                fontWeight = FontWeight.SemiBold
            )
            val textLayout = textMeasurer.measure(
                text = bubble.title,
                style = style,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                constraints = androidx.compose.ui.unit.Constraints(maxWidth = drawSize.toInt().coerceAtLeast(1))
            )
            drawText(
                textLayoutResult = textLayout,
                topLeft = Offset(
                    cx - textLayout.size.width / 2f,
                    cy - textLayout.size.height / 2f
                )
            )
        }
    }
}
