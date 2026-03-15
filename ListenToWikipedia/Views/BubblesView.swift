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
  static let initialUpwardSpeed: Double = 15.0
  static let upwardAcceleration: Double = 45.0
  static let lifespan: TimeInterval = 4.0

  static func scale(forAge age: TimeInterval) -> Double {
    let bounceDuration = 0.4
    if age > bounceDuration { return 1.0 }

    let t = age / bounceDuration
    return 1.0 - cos(t * .pi * 3.0) * exp(-t * 5.0)
  }

  static func position(for bubble: Bubble, age: TimeInterval, in size: CGSize)
    -> CGPoint
  {
    let startY = bubble.normalizedY * size.height
    let currentX = bubble.normalizedX * size.width

    // Apply kinematic equation for acceleration
    // distance = (v * t) + (0.5 * a * t^2)
    let distanceTraveled =
      (initialUpwardSpeed * age) + (0.5 * upwardAcceleration * (age * age))
    let currentY = startY - distanceTraveled

    return CGPoint(x: currentX, y: currentY)
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
      let currentPos = BubblePhysics.position(for: bubble, age: age, in: size)
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

  // MARK: - Colors

  // Base dot colors
  private static let greenDot = Color(
    red: 0x30 / 255.0,
    green: 0xDA / 255.0,
    blue: 0x59 / 255.0
  )
  private static let purpleDot = Color(
    red: 0xCC / 255.0,
    green: 0x67 / 255.0,
    blue: 0xCB / 255.0
  )
  private static let whiteDot = Color.white

  // "Way darker" variants (brightness × 0.3), used as fill for deletions and as label color for additions.
  private static let darkGreenDot = Color(
    red: 0x0E / 255.0,
    green: 0x41 / 255.0,
    blue: 0x1B / 255.0
  )
  private static let darkPurpleDot = Color(
    red: 0x3D / 255.0,
    green: 0x1F / 255.0,
    blue: 0x3D / 255.0
  )
  private static let darkWhiteDot = Color(white: 0.30)

  /// Returns (fill, label) colors for a bubble, matching HatnoteListen's drawRect logic.
  /// Additions: bright fill, dark label. Deletions: dark fill, bright label.
  private func bubbleColors(for edit: WikipediaArticleEdit) -> (
    fill: Color, label: Color
  ) {
    let isDeletion = edit.changeSize < 0
    if edit.isBot {
      return isDeletion
        ? (Self.darkPurpleDot, Self.purpleDot)
        : (Self.purpleDot, Self.darkPurpleDot)
    }
    if edit.isAnonymous {
      return isDeletion
        ? (Self.darkGreenDot, Self.greenDot)
        : (Self.greenDot, Self.darkGreenDot)
    }
    return isDeletion
      ? (Self.darkWhiteDot, Self.whiteDot)
      : (Self.whiteDot, Self.darkWhiteDot)
  }
}

// MARK: -

/// Renders and animates bubbles. Knows nothing about websockets, audio, or navigation.
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

            // Bubbles start fading at age 2.5s and fully disappear at 4s.
            let fadeDuration: TimeInterval = 1.5
            let fadeStart: TimeInterval = BubblePhysics.lifespan - fadeDuration
            let opacity =
              if age > fadeStart {
                max(0, 1.0 - (age - fadeStart) / fadeDuration)
              } else {
                1.0
              }

            guard opacity > 0 else { continue }

            let scale = BubblePhysics.scale(forAge: age)
            let position = BubblePhysics.position(for: bubble, age: age, in: size)

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

            let label = Text(bubble.title)
              .font(.system(size: 9, weight: .semibold))
              .foregroundColor(bubble.labelColor)
            bubbleContext.draw(
              bubbleContext.resolve(label),
              at: position,
              anchor: .center
            )
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
