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
  @Published var lastTappedMessage: String? = nil
  @Published var lastTappedArticleURL: URL? = nil
  var viewWidth: Double = 400

  private var tapClearTask: Task<Void, Never>?

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
    lastTappedMessage = bubble.title
    lastTappedArticleURL = bubble.articleURL

    tapClearTask?.cancel()

    tapClearTask = Task {
      try? await Task.sleep(nanoseconds: 3_000_000_000)
      guard !Task.isCancelled else { return }
      await MainActor.run {
        self.lastTappedMessage = nil
        self.lastTappedArticleURL = nil
      }
    }
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

struct BubblesView: View {
  @StateObject private var manager = BubbleManager()
  @StateObject private var service = WikipediaWebSocketService()
  @EnvironmentObject private var settings: AppSettings
  @State private var isShowingSettings = false
  @Environment(\.openURL) private var openURL

  @State private var notePlayer = NotePlayer(
    program: AppSettings.shared.selectedInstrumentProgram
  )

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
              .foregroundColor(bubble.labelColor)
            let resolvedLabel = bubbleContext.resolve(label)
            bubbleContext.draw(resolvedLabel, at: position, anchor: .center)
          }
        }
        .onTapGesture { location in
          let currentTime = Date.timeIntervalSinceReferenceDate
          manager.handleTap(at: location, time: currentTime, in: geometry.size)
        }
        .onAppear { manager.viewWidth = geometry.size.width }
        .onChange(of: geometry.size.width) { manager.viewWidth = geometry.size.width }
      }
    }
    .background(
      Color(red: 0x1B / 255.0, green: 0x20 / 255.0, blue: 0x24 / 255.0)
        .ignoresSafeArea()
    )
    .overlay(alignment: .topTrailing) {
      VStack(spacing: 8) {
        #if os(iOS)
          Button(action: {
            isShowingSettings = true
          }) {
            Image(systemName: "gearshape.fill")
              .font(.title2)
              .foregroundColor(.white)
              .padding()
              .background(Circle().fill(Color.black.opacity(0.5)))
          }
          .buttonStyle(.plain)
        #endif

        Button(action: {
          settings.isMuted.toggle()
        }) {
          Image(
            systemName: settings.isMuted
              ? "speaker.slash.fill" : "speaker.wave.2.fill"
          )
          .font(.title2)
          .foregroundColor(settings.isMuted ? .secondary : .white)
          .frame(width: 28, height: 28)
          .padding()
          .background(Circle().fill(Color.black.opacity(0.5)))
        }
        .buttonStyle(.plain)
      }
      .padding()
    }
    .overlay(alignment: .bottom) {
      if let message = manager.lastTappedMessage {
        Button {
          if let url = manager.lastTappedArticleURL {
            openURL(url)
          }
        } label: {
          HStack(spacing: 6) {
            Text(message)
              .font(.subheadline.bold())
              .foregroundColor(.white)
              .multilineTextAlignment(.center)
            if manager.lastTappedArticleURL != nil {
              Image(systemName: "arrow.up.right")
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.7))
            }
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(Color(white: 0.15))
              .shadow(color: .black.opacity(0.5), radius: 5, y: 3)
          )
        }
        .buttonStyle(.plain)
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
      syncConnections(to: settings.selectedLanguageCodes)
    }
    .onDisappear {
      service.disconnectAll()
    }
    .onReceive(settings.$selectedLanguageCodes) { codes in
      syncConnections(to: codes)
    }
    .onReceive(settings.$selectedInstrumentProgram) { program in
      notePlayer.loadInstrument(program: program)
    }
    .onReceive(service.eventPublisher) { event in
      if case .articleEdit(let edit) = event {
        manager.addBubble(from: edit)
        if !settings.isMuted,
          let note = MusicalScale.noteForEdit(
            changeSize: edit.changeSize,
            in: settings.currentScale
          )
        {
          notePlayer.play(note: note)
        }
      }
    }
  }

  /// Connects to languages that are selected but not yet connected,
  /// and disconnects languages that are connected but no longer selected.
  private func syncConnections(to selected: Set<String>) {
    for lang in service.connectedLanguages where !selected.contains(lang) {
      service.disconnect(language: lang)
    }
    for lang in selected where !service.connectedLanguages.contains(lang) {
      service.connect(language: lang)
    }
  }
}

#Preview {
  BubblesView()
    .environmentObject(AppSettings.shared)
}
