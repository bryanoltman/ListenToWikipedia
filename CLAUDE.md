# CLAUDE.md

## Project

ListenToWikipedia is a native Apple platform app that visualizes real-time Wikipedia edits as animated bubbles with musical sonification via MIDI/SoundFont. It connects to the Wikimedia EventStreams WebSocket, renders edits as bubbles in a Canvas, and plays musical notes scaled to edit size.

## Tech Stack

- **Language:** Swift, SwiftUI, Combine, AVFoundation
- **Platforms:** iOS 17.6+, macOS 15.7+, visionOS 26.2, tvOS
- **Dependencies:** None. Pure Apple SDK — no third-party packages.
- **Build system:** Xcode project (`apple/ListenToWikipedia.xcodeproj`). No SPM `Package.swift`.
- **License:** BSD 3-Clause

## Build / Test / Format

```bash
# Build (iOS Simulator)
xcodebuild -project apple/ListenToWikipedia.xcodeproj -scheme ListenToWikipedia -destination 'platform=iOS Simulator,name=iPhone Air' build

# Test
xcodebuild -project apple/ListenToWikipedia.xcodeproj -scheme ListenToWikipedia -destination 'platform=iOS Simulator,name=iPhone Air' test

# Format (swift-format, config in apple/.swift-format)
swift-format format --in-place --recursive apple/ListenToWikipedia/
```

Single scheme `ListenToWikipedia` covers the app and both test targets.

## Tooling

- **`swift-format`**: Installed via Homebrew. Config in `apple/.swift-format`.
- **`gh` CLI**: Authenticated, available at `/opt/homebrew/bin/gh`. Used for PR creation.

## Directory Layout

```
apple/                            # Apple platform app (iOS, macOS, tvOS, visionOS)
  ListenToWikipedia/              # Main app target
    App/                          # Entry point (ListenToWikipediaApp), logging (Log)
    Audio/                        # NotePlayer, MusicalScale, SoundFont parsing, types
    Models/                       # AppSettings, WikipediaLanguage
    Networking/                   # WikipediaWebSocketService, event models
    Views/                        # ContentView, BubblesView, toasts, banners
      Settings/                   # SettingsView and subviews
    GeneralUser-GS.sf2            # Bundled SoundFont asset
  ListenToWikipediaTests/         # Unit tests (Swift Testing framework)
  ListenToWikipediaUITests/       # UI tests (XCTest)
  AppIconAssets/                  # SVG app icons
  Screenshots/                    # App screenshots
```

## Architecture

### Data Flow

```
WikipediaWebSocketService (WebSocket → Combine publisher)
  → ContentView (root orchestrator, owns service + manager + player)
    → switches on .articleEdit / .newUser
      → BubbleManager (creates/manages Bubble values)
      → NotePlayer (plays MIDI note scaled to edit size)
      → BubblesView (Canvas + TimelineView rendering)
```

### Key Types

| Type | Role |
|---|---|
| `ContentView` | Root view. Owns `WikipediaWebSocketService`, `BubbleManager`, `NotePlayer`. |
| `WikipediaWebSocketService` | Connects to Wikimedia EventStreams via `URLSessionWebSocketTask`. Publishes `WikimediaEvent` values. |
| `NotePlayer` | `AVAudioEngine` + `AVAudioUnitSampler` per `EditSoundType`. Loads SF2 presets. |
| `MusicalScale` | Maps edit byte sizes to MIDI notes within a configurable scale. |
| `BubbleManager` | Creates and manages `Bubble` structs driven by incoming edits. |
| `BubblesView` | High-performance rendering via `Canvas` + `TimelineView`. |
| `AppSettings` | Singleton (`AppSettings.shared`). `@Published` properties persisted to `UserDefaults` via Combine debounce. |
| `Log` | `LeveledLogger` wrapper around `os.Logger`. Use `Log.audio` and `Log.network`. |

## Code Conventions

### Formatting (enforced by `.swift-format`)

- **Indentation:** 2 spaces
- **Line length:** 120 characters
- **Imports:** Alphabetical order
- **Trailing commas:** Required in multi-element collections
- **Semicolons:** Prohibited
- **Return type:** `-> Void`, not `-> ()`

### Style

- Use `private`, not `fileprivate`, for file-scoped declarations.
- Documentation comments use `///` (triple-slash), not `/** */`.
- Logging goes through `Log.audio` or `Log.network` — do not use `print()`.
- Settings are read from `AppSettings.shared` — do not create parallel storage.
- Use `Task.sleep(for:)` (Duration-based), not `Task.sleep(nanoseconds:)`.

### Concurrency

- `@MainActor` on service and player classes.
- `async/await` for asynchronous work.
- Combine publishers for reactive data flow (WebSocket events, settings changes).

## Platform Considerations

The codebase compiles for iOS, macOS, visionOS, and tvOS from a single target using conditional compilation:

```swift
#if os(iOS)
// iOS-specific code
#endif

#if os(macOS)
// macOS-specific code
#endif

#if os(tvOS)
// tvOS has limited UI (no Stepper, simplified navigation)
#endif
```

When adding platform-specific behavior, use these guards and keep shared logic unconditional.

## Testing

- **Unit tests:** Swift Testing framework (`import Testing`, `@Test` macro). Located in `apple/ListenToWikipediaTests/`.
- **UI tests:** XCTest. Located in `apple/ListenToWikipediaUITests/`.
- Both test targets are currently placeholder stubs — add real tests when modifying behavior.
