# Listen to Wikipedia

A native Apple platform app that visualizes real-time Wikipedia edits as animated bubbles with musical sonification. Inspired by [listen.hatnote.com](http://listen.hatnote.com/) and a successor to [HatnoteListen](https://github.com/bryanoltman/HatnoteListen).

## How It Works

The app connects via WebSocket to [Hatnote's wikimon service](https://github.com/hatnote/wikimon) (`wss://wikimon.hatnote.com/v2/{lang}`) and receives a stream of Wikipedia edit and new-user events. Each event produces:

- **A bubble** on a Canvas view, sized proportionally to the edit magnitude. Colors encode the edit type: white for registered users, green for anonymous, purple for bots; lighter shades for additions, darker for deletions.
- **A MIDI note** played through a bundled SoundFont (GeneralUser GS). Larger edits produce lower-pitched notes; smaller edits produce higher-pitched notes.

Tap a bubble to see the article title; tap the toast to open it in your browser. New user registrations display a banner with a link to welcome the user on their talk page.

## Features

- Real-time Wikipedia edit stream across 32 languages
- Configurable musical scales (pentatonic and heptatonic), all 12 keys, and multiple modes
- Selectable SF2 instruments per event type (additions, deletions, new users)
- Adjustable root octave and octave range
- Settings persisted automatically via UserDefaults

## Platforms

| Platform | Minimum Version | Notes                    |
| -------- | --------------- | ------------------------ |
| iOS      | 17.6            |                          |
| macOS    | 15.7            |                          |
| visionOS | 26.2            | Untested                 |
| tvOS     | Supported       | Limited (no settings UI) |

## Building

Open `ListenToWikipedia.xcodeproj` in Xcode and build. There are no third-party dependencies.

## Architecture

The app is built entirely in SwiftUI with no external packages.

- **App** -- Entry point (`ListenToWikipediaApp`), centralized logging via `os.Logger`
- **Views** -- `ContentView` orchestrates the WebSocket service, bubble manager, and note player. `BubblesView` renders bubbles on a `Canvas` with `TimelineView` animation. Platform-adaptive settings views.
- **Networking** -- `WikipediaWebSocketService` manages `URLSessionWebSocketTask` connections (one per selected language) and publishes `WikipediaEvent` values via Combine.
- **Audio** -- `NotePlayer` drives `AVAudioEngine` + `AVAudioUnitSampler` to play MIDI notes from loaded SF2 presets. `MusicalScale` handles note generation and edit-size-to-note mapping.
- **Models** -- `WikipediaEvent` (`.articleEdit` / `.newUser`), `WikipediaLanguage`, musical scale/key/mode types, SF2 instrument descriptors.

## License

BSD 3-Clause. See [LICENSE](LICENSE) for details.

### Third-Party Assets

**GeneralUser GS SoundFont** by S. Christian Collins, licensed under a [custom permissive license](http://www.schristiancollins.com/generaluser.php).
