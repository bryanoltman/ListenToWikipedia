package me.bryanoltman.listentowikipedia

import me.bryanoltman.listentowikipedia.ui.BubblePhysics
import org.junit.Assert.*
import org.junit.Test

class BubblePhysicsTest {

    private val epsilon = 0.001f

    // --- entranceScale ---

    @Test
    fun `entranceScale at age 0 is 0`() {
        assertEquals(0f, BubblePhysics.entranceScale(0.0), epsilon)
    }

    @Test
    fun `entranceScale at age 0_3 is 1`() {
        assertEquals(1f, BubblePhysics.entranceScale(0.3), epsilon)
    }

    @Test
    fun `entranceScale after entrance duration is 1`() {
        assertEquals(1f, BubblePhysics.entranceScale(0.5), epsilon)
        assertEquals(1f, BubblePhysics.entranceScale(5.0), epsilon)
    }

    @Test
    fun `entranceScale at midpoint is between 0 and 1`() {
        val mid = BubblePhysics.entranceScale(0.15)
        assertTrue("Mid-entrance scale should be >0: $mid", mid > 0f)
        assertTrue("Mid-entrance scale should be <1: $mid", mid < 1f)
    }

    @Test
    fun `entranceScale is monotonically increasing`() {
        var prev = 0f
        for (i in 0..30) {
            val age = i * 0.01
            val scale = BubblePhysics.entranceScale(age)
            assertTrue("Scale should be >= previous: $scale >= $prev at age $age", scale >= prev - epsilon)
            prev = scale
        }
    }

    // --- opacity ---

    @Test
    fun `opacity is 1 during first 6 seconds`() {
        assertEquals(1f, BubblePhysics.opacity(0.0), epsilon)
        assertEquals(1f, BubblePhysics.opacity(3.0), epsilon)
        assertEquals(1f, BubblePhysics.opacity(6.0), epsilon)
    }

    @Test
    fun `opacity fades linearly from 6 to 9 seconds`() {
        val mid = BubblePhysics.opacity(7.5) // halfway through fade
        assertEquals(0.5f, mid, epsilon)
    }

    @Test
    fun `opacity is 0 at lifespan end`() {
        assertEquals(0f, BubblePhysics.opacity(9.0), epsilon)
    }

    @Test
    fun `opacity is 0 after lifespan`() {
        assertEquals(0f, BubblePhysics.opacity(10.0), epsilon)
    }

    // --- bubbleSize ---

    @Test
    fun `bubbleSize returns minimum for tiny edits`() {
        // Very small edit: sqrt(1) * scaleFactor may be < minRadius
        val size = BubblePhysics.bubbleSize(1, 400f)
        assertTrue("Size should be positive: $size", size > 0f)
    }

    @Test
    fun `bubbleSize caps at maxSize`() {
        // Huge edit should not exceed maxSize
        val size = BubblePhysics.bubbleSize(1000000, 200f)
        assertTrue("Size should not exceed maxSize: $size <= 200", size <= 200f)
    }

    @Test
    fun `bubbleSize scales with edit magnitude`() {
        val small = BubblePhysics.bubbleSize(10, 400f)
        val medium = BubblePhysics.bubbleSize(1000, 400f)
        val large = BubblePhysics.bubbleSize(100000, 400f)
        assertTrue("Larger edits should make bigger bubbles", small <= medium)
        assertTrue("Larger edits should make bigger bubbles", medium <= large)
    }

    @Test
    fun `bubbleSize negative changeSize uses absolute value`() {
        val pos = BubblePhysics.bubbleSize(500, 400f)
        val neg = BubblePhysics.bubbleSize(-500, 400f)
        assertEquals(pos, neg, epsilon)
    }

    @Test
    fun `bubbleSize respects density scale`() {
        val defaultSize = BubblePhysics.bubbleSize(1, 400f, densityScale = 1f)
        val hdpiSize = BubblePhysics.bubbleSize(1, 400f, densityScale = 2f)
        // Higher density → larger minimum radius → potentially larger bubble for tiny edits
        assertTrue("HDPI minimum should be >= default", hdpiSize >= defaultSize)
    }

    // --- rippleProgress ---

    @Test
    fun `rippleProgress returns null before ring starts`() {
        assertNull(BubblePhysics.rippleProgress(1, 0.1)) // ring 1 starts at 0.3
    }

    @Test
    fun `rippleProgress returns 0 at ring start`() {
        val progress = BubblePhysics.rippleProgress(0, 0.0)
        assertNotNull(progress)
        assertEquals(0f, progress!!, epsilon)
    }

    @Test
    fun `rippleProgress returns 1 at ring end`() {
        val progress = BubblePhysics.rippleProgress(0, 1.0)
        assertNotNull(progress)
        assertEquals(1f, progress!!, epsilon)
    }

    @Test
    fun `rippleProgress returns null after ring duration`() {
        assertNull(BubblePhysics.rippleProgress(0, 1.1))
    }

    @Test
    fun `rippleProgress second ring starts after stagger`() {
        assertNull(BubblePhysics.rippleProgress(1, 0.2))
        val progress = BubblePhysics.rippleProgress(1, 0.3)
        assertNotNull(progress)
        assertEquals(0f, progress!!, epsilon)
    }

    // --- easeOutQuad ---

    @Test
    fun `easeOutQuad at 0 is 0`() {
        assertEquals(0f, BubblePhysics.easeOutQuad(0f), epsilon)
    }

    @Test
    fun `easeOutQuad at 1 is 1`() {
        assertEquals(1f, BubblePhysics.easeOutQuad(1f), epsilon)
    }

    @Test
    fun `easeOutQuad at 0_5 is 0_75`() {
        // 1 - (1-0.5)^2 = 1 - 0.25 = 0.75
        assertEquals(0.75f, BubblePhysics.easeOutQuad(0.5f), epsilon)
    }

    // --- positionX and positionY ---

    @Test
    fun `positionX is normalized times canvas width`() {
        assertEquals(50f, BubblePhysics.positionX(0.5f, 100f), epsilon)
    }

    @Test
    fun `positionY is normalized times canvas height`() {
        assertEquals(75f, BubblePhysics.positionY(0.75f, 100f), epsilon)
    }

    // --- LIFESPAN ---

    @Test
    fun `lifespan is 9 seconds`() {
        assertEquals(9.0, BubblePhysics.LIFESPAN, 0.001)
    }
}
