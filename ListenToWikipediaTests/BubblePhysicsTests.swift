import Testing
import SwiftUI
@testable import ListenToWikipedia

struct BubblePhysicsTests {
    // MARK: - scale(forAge:)

    @Test func scaleAtZero() {
        #expect(BubblePhysics.scale(forAge: 0) == 0.0)
    }

    @Test func scaleAfterEntrance() {
        #expect(BubblePhysics.scale(forAge: 0.3) == 1.0)
        #expect(BubblePhysics.scale(forAge: 1.0) == 1.0)
        #expect(BubblePhysics.scale(forAge: 5.0) == 1.0)
    }

    @Test func scaleDuringEntrance() {
        let mid = BubblePhysics.scale(forAge: 0.15)
        #expect(mid > 0.0)
        #expect(mid < 1.0)
    }

    @Test func scaleIsMonotonicallyIncreasing() {
        var prev = 0.0
        for i in stride(from: 0.0, through: 0.3, by: 0.01) {
            let current = BubblePhysics.scale(forAge: i)
            #expect(current >= prev, "Scale should be monotonically increasing")
            prev = current
        }
    }

    // MARK: - size(forChangeSize:maxSize:)

    @Test func sizeForZeroChange() {
        let size = BubblePhysics.size(forChangeSize: 0, maxSize: 800)
        #expect(size >= 30) // min radius 15 * 2 = 30
    }

    @Test func sizeForSmallChange() {
        let size = BubblePhysics.size(forChangeSize: 1, maxSize: 800)
        #expect(size >= 30)
    }

    @Test func sizeForLargeChange() {
        let size = BubblePhysics.size(forChangeSize: 100000, maxSize: 800)
        #expect(size <= 800) // capped at maxSize
    }

    @Test func sizeIncreasesWithChangeSize() {
        let small = BubblePhysics.size(forChangeSize: 10, maxSize: 800)
        let large = BubblePhysics.size(forChangeSize: 10000, maxSize: 800)
        #expect(large > small)
    }

    @Test func negativeChangeSizeSameAsMagnitude() {
        let pos = BubblePhysics.size(forChangeSize: 500, maxSize: 800)
        let neg = BubblePhysics.size(forChangeSize: -500, maxSize: 800)
        #expect(pos == neg)
    }

    // MARK: - position

    @Test func positionUsesNormalizedCoordinates() {
        let bubble = Bubble(
            creationTime: 0,
            normalizedX: 0.5,
            normalizedY: 0.25,
            color: .white,
            labelColor: .white,
            labelShadowColor: .black,
            size: 50,
            title: "Test",
            articleURL: nil
        )
        let pos = BubblePhysics.position(for: bubble, in: CGSize(width: 400, height: 800))
        #expect(pos.x == 200)
        #expect(pos.y == 200)
    }

    // MARK: - Tap response

    @Test func tapScaleOutsideRange() {
        #expect(BubblePhysics.tapScale(tapAge: -1) == 1.0)
        #expect(BubblePhysics.tapScale(tapAge: 1.0) == 1.0)
    }

    @Test func tapScaleDuringAnimation() {
        let mid = BubblePhysics.tapScale(tapAge: 0.125)
        #expect(mid > 1.0) // Should swell above 1.0
    }

    @Test func tapFlashOutsideRange() {
        #expect(BubblePhysics.tapFlashOpacity(tapAge: -1) == 0)
        #expect(BubblePhysics.tapFlashOpacity(tapAge: 1.0) == 0)
    }

    // MARK: - Ripple

    @Test func rippleFirstRingActiveAtStart() {
        let ring = BubblePhysics.rippleState(index: 0, age: 0.0, baseRadius: 50)
        #expect(ring != nil)
    }

    @Test func rippleSecondRingDelayed() {
        // Second ring starts at rippleDelay (0.3s)
        let earlyRing = BubblePhysics.rippleState(index: 1, age: 0.1, baseRadius: 50)
        #expect(earlyRing == nil)
        let lateRing = BubblePhysics.rippleState(index: 1, age: 0.4, baseRadius: 50)
        #expect(lateRing != nil)
    }

    @Test func rippleExpandsRadius() {
        guard let ring = BubblePhysics.rippleState(index: 0, age: 0.5, baseRadius: 50) else {
            Issue.record("Expected ripple state")
            return
        }
        #expect(ring.radius > 50)
    }
}
