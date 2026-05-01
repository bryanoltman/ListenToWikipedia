import Combine
import SwiftUI

/// The backing model for each bubble drawn onscreen.
struct Bubble: Identifiable {
  let id = UUID()
  let creationTime: TimeInterval
  let normalizedX: Double
  let normalizedY: Double
  let color: Color
  let labelColor: Color
  let labelShadowColor: Color
  let size: Double
  let title: String
  let articleURL: URL?
}

enum BubblePhysics {
  static let lifespan: TimeInterval = 9.0

  // MARK: Entrance

  /// Smooth ease-out cubic scale from 0 → 1 over 0.3s.
  static func scale(forAge age: TimeInterval) -> Double {
    let entranceDuration = 0.3
    if age >= entranceDuration { return 1.0 }
    let t = age / entranceDuration
    return 1.0 - pow(1.0 - t, 3)
  }

  // MARK: Position (static — no drift)

  static func position(for bubble: Bubble, in size: CGSize) -> CGPoint {
    CGPoint(
      x: bubble.normalizedX * size.width,
      y: bubble.normalizedY * size.height
    )
  }

  // MARK: Ripple rings

  static let rippleCount = 2
  /// Delay between successive rings.
  static let rippleDelay: TimeInterval = 0.3
  /// How long each ring animates before disappearing.
  static let rippleDuration: TimeInterval = 1.0
  /// Ripple expands outward by this fraction of the bubble's radius.
  static let rippleExpansionFactor: Double = 0.4

  /// Returns (radius, opacity, lineWidth) for the given ripple ring, or nil if inactive.
  static func rippleState(
    index: Int,
    age: TimeInterval,
    baseRadius: Double
  ) -> (radius: Double, opacity: Double, lineWidth: Double)? {
    let ringStart = Double(index) * rippleDelay
    let ringAge = age - ringStart
    guard ringAge >= 0, ringAge <= rippleDuration else { return nil }

    let t = ringAge / rippleDuration
    // Ease-out quadratic: fast initial expansion, decelerating.
    let easedT = 1.0 - (1.0 - t) * (1.0 - t)

    let radius = baseRadius + easedT * (baseRadius * rippleExpansionFactor)
    let opacity = 0.4 * (1.0 - t)
    let lineWidth = 2.0 - 1.5 * t  // thins from 2pt → 0.5pt

    return (radius, opacity, lineWidth)
  }

  /// Maps a Wikipedia edit's byte-change magnitude to a bubble diameter.
  /// Based on Hatnote listen.hatnote.com sizing: radius = max(sqrt(abs(change_size)) * scaleFactor, minRadius).
  /// The scale factor is proportional to the view so bubbles look similar
  /// across phone, tablet, TV, and web.
  static func size(forChangeSize changeSize: Int, maxSize: Double) -> Double {
    // Hatnote uses scaleFactor=5 on a ~1200px-wide canvas (reference maxSize = 800).
    let referenceMaxSize = 800.0
    let scale = maxSize / referenceMaxSize
    let scaleFactor = 5.0 * scale
    let minRadius = max(15.0 * scale, 15.0)
    let magnitude = Double(abs(changeSize))
    let radius = max(sqrt(magnitude) * scaleFactor, minRadius)
    // Return diameter (the rest of the code uses size as diameter)
    return min(radius * 2.0, maxSize)
  }

  // MARK: Tap response

  static let tapAnimationDuration: TimeInterval = 0.25
  static let tapRippleDuration: TimeInterval = 0.4

  /// Scale pop: quick swell and settle using a sine curve.
  static func tapScale(tapAge: TimeInterval) -> Double {
    guard tapAge >= 0, tapAge < tapAnimationDuration else { return 1.0 }
    let t = tapAge / tapAnimationDuration
    return 1.0 + 0.1 * sin(t * .pi)
  }

  /// White flash overlay opacity that fades out quickly.
  static func tapFlashOpacity(tapAge: TimeInterval) -> Double {
    guard tapAge >= 0, tapAge < tapAnimationDuration else { return 0 }
    let t = tapAge / tapAnimationDuration
    return 0.05 * (1.0 - t * t)
  }

  /// Expanding ring emitted from a tapped bubble, or nil if inactive.
  static func tapRippleState(
    tapAge: TimeInterval,
    baseRadius: Double
  ) -> (radius: Double, opacity: Double, lineWidth: Double)? {
    guard tapAge >= 0, tapAge < tapRippleDuration else { return nil }
    let t = tapAge / tapRippleDuration
    let easedT = 1.0 - (1.0 - t) * (1.0 - t)
    let radius = baseRadius + easedT * baseRadius * 0.5
    let opacity = 0.35 * (1.0 - t)
    let lineWidth = 2.0 - 1.5 * t
    return (radius, opacity, lineWidth)
  }
}

// MARK: -

/// Provides data and hit testing for the bubbles canvas.
class BubbleManager: ObservableObject {
  @Published private(set) var bubbles: [Bubble] = []
  var viewSize: CGSize = CGSize(width: 400, height: 400)
  private(set) var tappedBubbleID: UUID?
  private(set) var tapTime: TimeInterval = 0
  private var pruneTimer: Timer?

  @MainActor
  func addBubble(from edit: WikipediaArticleEdit) {
    let currentTime = Date.timeIntervalSinceReferenceDate
    let (fill, label, shadow) = bubbleColors(for: edit)
    let newBubble = Bubble(
      creationTime: currentTime,
      normalizedX: Double.random(in: 0.05...0.95),
      normalizedY: Double.random(in: 0.05...0.95),
      color: fill,
      labelColor: label,
      labelShadowColor: shadow,
      size: BubblePhysics.size(
        forChangeSize: edit.changeSize, maxSize: max(viewSize.width, viewSize.height) * 2.0 / 3.0),
      title: edit.pageTitle,
      articleURL: Self.articleURL(
        language: edit.language,
        pageTitle: edit.pageTitle
      )
    )
    bubbles.append(newBubble)
    bubbles.removeAll { currentTime - $0.creationTime > BubblePhysics.lifespan }
  }

  /// Returns the topmost bubble at `point`, or `nil` if none was hit.
  @MainActor
  func bubble(at point: CGPoint, time: TimeInterval, in size: CGSize) -> Bubble? {
    for bubble in bubbles.reversed() {
      let age = time - bubble.creationTime
      guard age >= 0 else { continue }

      let currentScale = BubblePhysics.scale(forAge: age)
      let currentPos = BubblePhysics.position(for: bubble, in: size)
      let radius = (bubble.size * currentScale) / 2

      let dx = point.x - currentPos.x
      let dy = point.y - currentPos.y
      if sqrt((dx * dx) + (dy * dy)) <= radius {
        return bubble
      }
    }
    return nil
  }

  /// Records a tap on a bubble for visual feedback in the Canvas render loop.
  @MainActor
  func recordTap(on bubble: Bubble) {
    tappedBubbleID = bubble.id
    tapTime = Date.timeIntervalSinceReferenceDate
  }

  /// Removes bubbles whose lifespan has elapsed.
  @MainActor
  func pruneExpiredBubbles() {
    let currentTime = Date.timeIntervalSinceReferenceDate
    bubbles.removeAll { currentTime - $0.creationTime > BubblePhysics.lifespan }
  }

  /// Starts a repeating 1-second timer that prunes expired bubbles.
  func startPruning() {
    pruneTimer?.invalidate()
    pruneTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      Task { @MainActor [weak self] in
        self?.pruneExpiredBubbles()
      }
    }
  }

  /// Stops the prune timer.
  func stopPruning() {
    pruneTimer?.invalidate()
    pruneTimer = nil
  }

  private static func articleURL(language: String, pageTitle: String) -> URL? {
    let encodedTitle =
      pageTitle
      .replacingOccurrences(of: " ", with: "_")
      .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
      ?? pageTitle
    return URL(string: "https://\(language).wikipedia.org/wiki/\(encodedTitle)")
  }
  /// Returns (fill, label, shadow) colors for a bubble.
  /// Additions: bright fill, adaptive label. Deletions: dark fill, bright label.
  private func bubbleColors(for edit: WikipediaArticleEdit) -> (fill: Color, label: Color, shadow: Color) {
    let isDeletion = edit.changeSize < 0
    if edit.isBot {
      return isDeletion
        ? (.dotPurpleDark, .dotPurple, .black.opacity(0.6))
        : (.dotPurple, .white, .black.opacity(0.6))
    }
    if edit.isAnonymous {
      return isDeletion
        ? (.dotGreenDark, .dotGreen, .black.opacity(0.6))
        : (.dotGreen, .white, .black.opacity(0.6))
    }
    return isDeletion
      ? (.dotWhiteDark, .dotWhite, .black.opacity(0.6))
      : (.dotWhite, .white, .black.opacity(0.85))
  }
}

// MARK: -

/// Renders and animates bubbles.
struct BubblesView: View {
  @ObservedObject var manager: BubbleManager
  var onTap: (Bubble) -> Void

  @State private var gestureActive = false

  #if os(tvOS)
    @ScaledMetric(relativeTo: .caption2) private var fontSize: CGFloat = 18.0
  #else
    @ScaledMetric(relativeTo: .caption2) private var fontSize: CGFloat = 9.0
  #endif

  var body: some View {
    GeometryReader { geometry in
      TimelineView(.animation) { timeline in
        Canvas { context, size in
          let currentTime = timeline.date.timeIntervalSinceReferenceDate

          for bubble in manager.bubbles {
            let age = currentTime - bubble.creationTime
            guard age >= 0 else { continue }

            // Main circle fades from 6s → 9s (3s fade).
            let fadeDuration: TimeInterval = 3.0
            let fadeStart: TimeInterval = BubblePhysics.lifespan - fadeDuration
            let opacity =
              if age > fadeStart {
                max(0, 1.0 - (age - fadeStart) / fadeDuration)
              } else {
                1.0
              }

            guard opacity > 0 else { continue }

            let scale = BubblePhysics.scale(forAge: age)
            let position = BubblePhysics.position(for: bubble, in: size)

            // --- Ripple rings ---
            let baseRadius = (bubble.size * scale) / 2
            for ringIndex in 0..<BubblePhysics.rippleCount {
              guard
                let ring = BubblePhysics.rippleState(
                  index: ringIndex,
                  age: age,
                  baseRadius: baseRadius
                )
              else { continue }

              var ringContext = context
              ringContext.opacity = ring.opacity * opacity
              let ringRect = CGRect(
                x: position.x - ring.radius,
                y: position.y - ring.radius,
                width: ring.radius * 2,
                height: ring.radius * 2
              )
              ringContext.stroke(
                Path(ellipseIn: ringRect),
                with: .color(bubble.color),
                lineWidth: ring.lineWidth
              )
            }

            // --- Tap response ---
            var tapScaleMultiplier = 1.0
            var tapFlash = 0.0
            var tapAge: TimeInterval?
            if bubble.id == manager.tappedBubbleID {
              let elapsed = currentTime - manager.tapTime
              tapAge = elapsed
              tapScaleMultiplier = BubblePhysics.tapScale(tapAge: elapsed)
              tapFlash = BubblePhysics.tapFlashOpacity(tapAge: elapsed)
            }

            // --- Filled circle with subtle shadow for depth between overlapping bubbles ---
            var bubbleContext = context
            bubbleContext.opacity = opacity
            bubbleContext.addFilter(.shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 0))

            let drawSize = bubble.size * scale * tapScaleMultiplier
            let rect = CGRect(
              x: position.x - (drawSize / 2),
              y: position.y - (drawSize / 2),
              width: drawSize,
              height: drawSize
            )
            bubbleContext.fill(Path(ellipseIn: rect), with: .color(bubble.color))

            // --- Tap flash overlay ---
            if tapFlash > 0 {
              var flashContext = context
              flashContext.opacity = tapFlash * opacity
              flashContext.fill(Path(ellipseIn: rect), with: .color(.white))
            }

            // --- Tap ripple ---
            if let tapAge,
              let ring = BubblePhysics.tapRippleState(
                tapAge: tapAge, baseRadius: baseRadius
              )
            {
              var tapRingContext = context
              tapRingContext.opacity = ring.opacity * opacity
              let ringRect = CGRect(
                x: position.x - ring.radius,
                y: position.y - ring.radius,
                width: ring.radius * 2,
                height: ring.radius * 2
              )
              tapRingContext.stroke(
                Path(ellipseIn: ringRect),
                with: .color(.white),
                lineWidth: ring.lineWidth
              )
            }

            // --- Title label with shadow glow for contrast on any background ---
            var textContext = bubbleContext
            textContext.addFilter(
              .shadow(color: bubble.labelShadowColor, radius: 3, x: 0, y: 0)
            )
            let font = Font.system(size: fontSize, weight: .medium)
            let resolvedLabel = textContext.resolve(
              Text(bubble.title).font(font).foregroundColor(bubble.labelColor)
            )
            textContext.draw(resolvedLabel, at: position, anchor: .center)
          }
        }
        #if !os(tvOS)
          .gesture(
            DragGesture(minimumDistance: 0)
              .onChanged { value in
                guard !gestureActive else { return }
                gestureActive = true
                let now = Date.timeIntervalSinceReferenceDate
                if let bubble = manager.bubble(at: value.startLocation, time: now, in: geometry.size) {
                  manager.recordTap(on: bubble)
                }
              }
              .onEnded { value in
                gestureActive = false
                let now = Date.timeIntervalSinceReferenceDate
                if let bubble = manager.bubble(at: value.startLocation, time: now, in: geometry.size) {
                  onTap(bubble)
                }
              }
          )
        #endif
        .onAppear {
          manager.viewSize = geometry.size
          manager.startPruning()
        }
        .onDisappear { manager.stopPruning() }
        .onChange(of: geometry.size) { _, size in manager.viewSize = size }
      }
    }
    .ignoresSafeArea()
  }
}
