import Combine
import SwiftUI

/// The backing model for each bubble drawn onscreen.
struct Bubble: Identifiable {
  let id = UUID()
  let creationTime: TimeInterval
  let normalizedX: Double
  let normalizedY: Double
  let color: Color
  let size: Double
  let title: String
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
}

// MARK: -

/// Provides data and hit testing.
/// TODO: connect this to an actual data source
class BubbleManager: ObservableObject {
  @Published private(set) var bubbles: [Bubble] = []
  @Published var lastTappedMessage: String? = nil

  private var tapClearTask: Task<Void, Never>?
  private let colors: [Color] = [.blue, .purple, .teal, .pink, .indigo]
  private let articleTitles: [String] = [
    "Egypt",
    "Linux",
    "Venus",
    "Japan",
    "Pluto",
    "World War II",
    "Solar System",
    "Black hole",
    "DNA",
    "Albert Einstein",
    "French Revolution",
    "William Shakespeare",
    "Theory of relativity",
    "American Civil War",
    "History of mathematics",
    "International Space Station",
    "List of Nobel Prize winners",
    "Ancient Greek philosophy",
    "The Renaissance in Europe",
    "Photosynthesis and plant biology",
    "History of the Roman Empire",
    "United Nations Security Council",
    "Quantum mechanics and wave functions",
    "Climate change and global warming effects",
    "List of countries by population density",
    "History of the United States Constitution",
    "Exploration of the deep ocean and sea life",
    "Artificial intelligence and machine learning",
    "Overview of the human digestive system",
    "History and culture of ancient Mesopotamia",
    "List of tallest buildings and structures worldwide",
  ]

  func startMockingEvents() {
    Task {
      while !Task.isCancelled {
        let delay = UInt64.random(in: 500_000_000...3000_000_000)
        try? await Task.sleep(nanoseconds: delay)
        addBubble()
      }
    }
  }

  @MainActor
  private func addBubble() {
    let currentTime = Date.timeIntervalSinceReferenceDate
    let newBubble = Bubble(
      creationTime: currentTime,
      normalizedX: Double.random(in: 0.05...0.95),
      normalizedY: Double.random(in: 0.05...0.95),
      color: colors.randomElement() ?? .blue,
      size: Double.random(in: 30...60),
      title: articleTitles.randomElement() ?? "Wikipedia"
    )
    bubbles.append(newBubble)

    bubbles.removeAll { currentTime - $0.creationTime > BubblePhysics.lifespan }
  }

  @MainActor
  func handleTap(at point: CGPoint, time: TimeInterval, in size: CGSize) {
    for index in bubbles.indices.reversed() {
      let bubble = bubbles[index]
      let age = time - bubble.creationTime
      guard age >= 0 else { continue }

      let currentScale = BubblePhysics.scale(forAge: age)
      let currentPos = BubblePhysics.position(for: bubble, age: age, in: size)
      let radius = (bubble.size * currentScale) / 2

      let dx = point.x - currentPos.x
      let dy = point.y - currentPos.y
      let distance = sqrt((dx * dx) + (dy * dy))

      if distance <= radius {
        showTapMessage(for: bubble)
        break
      }
    }
  }

  @MainActor
  private func showTapMessage(for bubble: Bubble) {
    let colorName = String(describing: bubble.color).capitalized
    lastTappedMessage =
      "Tapped Bubble\nID: \(bubble.id.uuidString.prefix(8)) | Color: \(colorName)"

    tapClearTask?.cancel()

    tapClearTask = Task {
      try? await Task.sleep(nanoseconds: 3_000_000_000)
      guard !Task.isCancelled else { return }
      await MainActor.run {
        self.lastTappedMessage = nil
      }
    }
  }
}

// MARK: -

struct BubblesView: View {
  @StateObject private var manager = BubbleManager()
  @State private var isShowingSettings = false

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
            let position = BubblePhysics.position(
              for: bubble,
              age: age,
              in: size
            )

            var bubbleContext = context
            bubbleContext.opacity = opacity

            let drawSize = bubble.size * scale
            let rect = CGRect(
              x: position.x - (drawSize / 2),
              y: position.y - (drawSize / 2),
              width: drawSize,
              height: drawSize
            )

            bubbleContext.fill(
              Path(ellipseIn: rect),
              with: .color(bubble.color)
            )

            let label = Text(bubble.title)
              .font(.system(size: 9, weight: .semibold))
              .foregroundColor(.white)
            let resolvedLabel = bubbleContext.resolve(label)
            bubbleContext.draw(resolvedLabel, at: position, anchor: .center)
          }
        }
        .onTapGesture { location in
          let currentTime = Date.timeIntervalSinceReferenceDate
          manager.handleTap(at: location, time: currentTime, in: geometry.size)
        }
      }
    }
    .background(Color.black.ignoresSafeArea())
    .overlay(alignment: .topTrailing) {
      Button(action: {
        isShowingSettings = true
      }) {
        Image(systemName: "gearshape.fill")
          .font(.title2)
          .foregroundColor(.white)
          .padding()
          .background(Circle().fill(Color.black.opacity(0.5)))
          .padding()
      }
      .buttonStyle(.plain)
    }
    .overlay(alignment: .bottom) {
      if let message = manager.lastTappedMessage {
        Text(message)
          .font(.subheadline.bold())
          .foregroundColor(.white)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(Color(white: 0.15))
              .shadow(color: .black.opacity(0.5), radius: 5, y: 3)
          )
          .padding(.bottom, 40)
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .animation(
      .spring(response: 0.3, dampingFraction: 0.7),
      value: manager.lastTappedMessage
    )
    .sheet(isPresented: $isShowingSettings) {
      SettingsView()
    }
    .onAppear {
      manager.startMockingEvents()
    }
  }
}

#Preview {
  BubblesView()
}
