import Combine
import SwiftUI

/// The backing model for each bubble drawn onscreen.
struct Bubble: Identifiable {
  let id = UUID()
  let creationTime: TimeInterval
  let normalizedX: Double
  let normalizedY: Double
  /// Fill color of the bubble circle.
  let color: Color
  /// Color used for the title label drawn inside the bubble.
  let labelColor: Color
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

  /// Maps a Wikipedia edit's byte-change magnitude to a bubble diameter,
  /// clamped to `maxSize`. Uses a log scale so both tiny and enormous edits
  /// remain visible.
  static func size(forChangeSize changeSize: Int, maxSize: Double) -> Double {
    let magnitude = Double(abs(changeSize))
    let scaled = 20.0 + 50.0 * log10(1.0 + magnitude)
    return min(scaled, maxSize)
  }
}

// MARK: -

/// Provides data and hit testing for the bubbles canvas.
class BubbleManager: ObservableObject {
  @Published private(set) var bubbles: [Bubble] = []
  var viewWidth: Double = 400

  @MainActor
  func addBubble(from edit: WikipediaArticleEdit) {
    let currentTime = Date.timeIntervalSinceReferenceDate
    let (fill, label) = bubbleColors(for: edit)
    let newBubble = Bubble(
      creationTime: currentTime,
      normalizedX: Double.random(in: 0.05...0.95),
      normalizedY: Double.random(in: 0.05...0.95),
      color: fill,
      labelColor: label,
      size: BubblePhysics.size(forChangeSize: edit.changeSize, maxSize: viewWidth / 2),
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

  private static func articleURL(language: String, pageTitle: String) -> URL? {
    let encodedTitle =
      pageTitle
      .replacingOccurrences(of: " ", with: "_")
      .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
      ?? pageTitle
    return URL(string: "https://\(language).wikipedia.org/wiki/\(encodedTitle)")
  }
  /// Returns (fill, label) colors for a bubble.
  /// Additions: bright fill, white label. Deletions: dark fill, bright label.
  private func bubbleColors(for edit: WikipediaArticleEdit) -> (fill: Color, label: Color) {
    let isDeletion = edit.changeSize < 0
    if edit.isBot {
      return isDeletion
        ? (.dotPurpleDark, .dotPurple)
        : (.dotPurple, .white)
    }
    if edit.isAnonymous {
      return isDeletion
        ? (.dotGreenDark, .dotGreen)
        : (.dotGreen, .white)
    }
    return isDeletion
      ? (.dotWhiteDark, .dotWhite)
      : (.dotWhite, .white)
  }
}

// MARK: -

/// Renders and animates bubbles.
struct BubblesView: View {
  @ObservedObject var manager: BubbleManager
  var onTap: (Bubble) -> Void

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

            // --- Filled circle ---
            var bubbleContext = context
            bubbleContext.opacity = opacity

            let drawSize = bubble.size * scale
            let rect = CGRect(
              x: position.x - (drawSize / 2),
              y: position.y - (drawSize / 2),
              width: drawSize,
              height: drawSize
            )
            bubbleContext.fill(Path(ellipseIn: rect), with: .color(bubble.color))

            // --- Title label (outline + fill for contrast on any background) ---
            let font = Font.system(size: 9, weight: .medium)
            let resolvedOutline = bubbleContext.resolve(
              Text(bubble.title).font(font).foregroundColor(.black.opacity(0.4))
            )
            let resolvedLabel = bubbleContext.resolve(
              Text(bubble.title).font(font).foregroundColor(bubble.labelColor)
            )
            // Draw dark copies at corner offsets to form a crisp outline.
            let d: CGFloat = 1.0
            for dx: CGFloat in [-d, d] {
              for dy: CGFloat in [-d, d] {
                bubbleContext.draw(
                  resolvedOutline,
                  at: CGPoint(x: position.x + dx, y: position.y + dy),
                  anchor: .center
                )
              }
            }
            bubbleContext.draw(resolvedLabel, at: position, anchor: .center)
          }
        }
        .onTapGesture { location in
          let currentTime = Date.timeIntervalSinceReferenceDate
          if let bubble = manager.bubble(at: location, time: currentTime, in: geometry.size) {
            onTap(bubble)
          }
        }
        .onAppear { manager.viewWidth = geometry.size.width }
        .onChange(of: geometry.size.width) { _, width in manager.viewWidth = width }
      }
    }
    .ignoresSafeArea()
  }
}
