# CLAUDE.md

## Project

ListenToWikipedia visualizes real-time Wikipedia edits as animated bubbles with musical sonification. It connects to the Wikimedia EventStreams WebSocket, renders edits as bubbles on a canvas, and plays musical notes scaled to edit size. The project has two platform implementations sharing the same behavior:

- **Apple** (`apple/`): iOS, macOS, tvOS, visionOS — Swift/SwiftUI
- **Android** (`android/`): Android 13+ — Kotlin/Jetpack Compose

## Directory Layout

```
apple/                              # Apple platform app (iOS, macOS, tvOS, visionOS)
  ListenToWikipedia/                # Main app target
    App/                            # Entry point, logging
    Audio/                          # NotePlayer, MusicalScale, SoundFont parsing, types
    Models/                         # AppSettings, WikipediaLanguage
    Networking/                     # WikipediaWebSocketService, event models
    Views/                          # ContentView, BubblesView, toasts, banners
      Settings/                     # SettingsView and subviews
    GeneralUser-GS.sf2              # Bundled SoundFont asset
  ListenToWikipediaTests/           # Unit tests (Swift Testing)
  ListenToWikipediaUITests/         # UI tests (XCTest)
  AppIconAssets/                    # SVG app icons
  Screenshots/                     # App screenshots
android/                            # Android app
  app/src/main/java/.../            # me.bryanoltman.listentowikipedia
    audio/                          # NotePlayer, MusicalScale, enums, GM catalog
    model/                          # AppSettings, WikipediaLanguage
    networking/                     # WikipediaWebSocketService, event models
    ui/                             # ContentScreen, BubblesCanvas, overlays
      settings/                     # Settings screens
      theme/                        # Material 3 theme, colors
    MainActivity.kt                 # Entry point
```

## Shared Architecture

Both platforms implement the same data flow:

```
WikipediaWebSocketService (per-language WebSocket connections)
  → event stream (articleEdit | newUser)
    → BubbleManager (creates/manages bubble visuals)
    → NotePlayer (plays MIDI note scaled to edit size)
    → Canvas rendering (animated bubbles with physics)
```

### Key Constants (shared across platforms)
- WebSocket URL: `wss://wikimon.hatnote.com/v2/{languageCode}`
- Reconnection: exponential backoff, 1s initial, 30s max
- 32 supported Wikipedia languages
- Bubble lifespan: 9s, fade 3s (from 6s), entrance 0.3s
- Note duration: 5s auto-stop
- Toast: 3s, new user banner: 8s
- Default settings: key=F#, scale=pentatonic, mode=major pentatonic, root octave=1, octave range=3
- Default instruments: addition=Celesta (program 8), subtraction=Clavinet (program 7), new user=Warm Pad (program 89)

---

## Apple Platform

### Tech Stack
- **Language:** Swift, SwiftUI, Combine, AVFoundation
- **Platforms:** iOS 17.6+, macOS 15.7+, visionOS 26.2, tvOS
- **Dependencies:** None. Pure Apple SDK — no third-party packages.
- **Build system:** Xcode project (`apple/ListenToWikipedia.xcodeproj`). No SPM `Package.swift`.

### Build / Test / Format

```bash
# Build (iOS Simulator)
xcodebuild -project apple/ListenToWikipedia.xcodeproj -scheme ListenToWikipedia -destination 'platform=iOS Simulator,name=iPhone Air' build

# Test
xcodebuild -project apple/ListenToWikipedia.xcodeproj -scheme ListenToWikipedia -destination 'platform=iOS Simulator,name=iPhone Air' test

# Format (swift-format, config in apple/.swift-format)
swift-format format --in-place --recursive apple/ListenToWikipedia/
```

Single scheme `ListenToWikipedia` covers the app and both test targets.

### Apple Tooling
- **`swift-format`**: Installed via Homebrew. Config in `apple/.swift-format`.
- **`gh` CLI**: Authenticated, available at `/opt/homebrew/bin/gh`. Used for PR creation.

### Apple Key Types

| Type | Role |
|---|---|
| `ContentView` | Root view. Owns `WikipediaWebSocketService`, `BubbleManager`, `NotePlayer`. |
| `WikipediaWebSocketService` | `URLSessionWebSocketTask` per language. Publishes `WikipediaEvent` via Combine. |
| `NotePlayer` | `AVAudioEngine` + `AVAudioUnitSampler` per `EditSoundType`. Loads SF2 presets. |
| `MusicalScale` | Maps edit byte sizes to MIDI notes within a configurable scale. |
| `BubbleManager` | Creates and manages `Bubble` structs driven by incoming edits. |
| `BubblesView` | High-performance rendering via `Canvas` + `TimelineView`. |
| `AppSettings` | Singleton. `@Published` properties persisted to `UserDefaults` via Combine debounce. |
| `Log` | `LeveledLogger` wrapper around `os.Logger`. Use `Log.audio` and `Log.network`. |

### Apple Code Conventions

#### Formatting (enforced by `.swift-format`)
- **Indentation:** 2 spaces
- **Line length:** 120 characters
- **Imports:** Alphabetical order
- **Trailing commas:** Required in multi-element collections
- **Semicolons:** Prohibited
- **Return type:** `-> Void`, not `-> ()`

#### Style
- Use `private`, not `fileprivate`, for file-scoped declarations.
- Documentation comments use `///` (triple-slash), not `/** */`.
- Logging goes through `Log.audio` or `Log.network` — do not use `print()`.
- Settings are read from `AppSettings.shared` — do not create parallel storage.
- Use `Task.sleep(for:)` (Duration-based), not `Task.sleep(nanoseconds:)`.

#### Concurrency
- `@MainActor` on service and player classes.
- `async/await` for asynchronous work.
- Combine publishers for reactive data flow (WebSocket events, settings changes).

### Apple Platform Considerations

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

### Apple Testing
- **Unit tests:** Swift Testing framework (`import Testing`, `@Test` macro). Located in `apple/ListenToWikipediaTests/`.
- **UI tests:** XCTest. Located in `apple/ListenToWikipediaUITests/`.
- Both test targets are currently placeholder stubs — add real tests when modifying behavior.

---

## Android Platform

### Tech Stack
- **Language:** Kotlin
- **UI:** Jetpack Compose, Material Design 3
- **Min SDK:** 33 (Android 13 Tiramisu)
- **Target SDK:** 36
- **Dependencies:** OkHttp (WebSocket), kotlinx-serialization-json, Compose Material Icons Extended, AndroidX Lifecycle ViewModel/Runtime Compose
- **Build system:** Gradle (Kotlin DSL), single `:app` module
- **Package:** `me.bryanoltman.listentowikipedia`

### Build / Test

```bash
# Requires JAVA_HOME set to Android Studio's bundled JDK:
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"

# Build
cd android && ./gradlew assembleDebug

# Unit tests
cd android && ./gradlew testDebugUnitTest
```

### Android Key Types

| Type | Role |
|---|---|
| `ContentScreen` | Root composable. Orchestrates WebSocket, BubbleManager, NotePlayer. |
| `WikipediaWebSocketService` | OkHttp WebSocket per language. Emits events via `SharedFlow`. |
| `NotePlayer` | Android MIDI API (`MidiManager`). 3 MIDI channels for 3 `EditSoundType`s. Graceful no-op if no synth found. |
| `MusicalScale` | Same algorithm as Apple — log-maps edit size to MIDI note index. |
| `BubbleManager` | Compose `mutableStateListOf<Bubble>` with pruning timer. |
| `BubblesCanvas` | Compose `Canvas` with `withFrameNanos` animation loop. |
| `AppSettings` | Singleton. `MutableStateFlow` per setting, backed by `SharedPreferences`. |
| `GeneralMidiCatalog` | 128 standard GM instrument names for the instrument picker. |

### Android Code Conventions

#### Style
- **Indentation:** 4 spaces (Kotlin standard)
- Standard Kotlin naming: `camelCase` functions/properties, `PascalCase` types, `SCREAMING_SNAKE` constants.
- Logging via `android.util.Log` with tags `"NotePlayer"`, `"WebSocket"`.
- Settings are read from `AppSettings.getInstance(context)` — do not create parallel storage.

#### Concurrency
- Kotlin coroutines (`CoroutineScope`, `Dispatchers.IO`/`Main`, `StateFlow`/`SharedFlow`).
- Compose state: `mutableStateOf`, `mutableStateListOf`, `collectAsState()`.
- Lifecycle awareness via `LifecycleEventEffect` (pause disconnects, resume reconnects).

### Android Platform Differences from Apple
- **Audio:** Uses Android MIDI API with platform's built-in virtual synthesizer (Sonivox) instead of a bundled SoundFont. Same GM program numbers map to equivalent instruments. Audio is unavailable on devices without a MIDI synthesizer (visual-only fallback).
- **Instrument picker:** Shows standard General MIDI instrument names (128 programs) instead of parsing from SF2 file.
- **Settings:** Uses `SharedPreferences` + `MutableStateFlow` instead of `UserDefaults` + Combine.
- **Networking:** OkHttp `WebSocket` instead of `URLSessionWebSocketTask`.
- **UI:** Material 3 `ModalBottomSheet` for settings (instead of SwiftUI `.sheet`). Compose `Canvas` with `withFrameNanos` instead of SwiftUI `Canvas` + `TimelineView`.

### Android Testing
- **Unit tests:** JUnit 4. Located in `android/app/src/test/`.
- **Instrumented tests:** AndroidJUnit4 + Espresso. Located in `android/app/src/androidTest/`.
- Both test targets currently contain only placeholder stubs.

---

## License

BSD 3-Clause
