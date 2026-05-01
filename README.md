# Listen to Wikipedia

A real-time visualization and sonification of Wikipedia edits. Each edit produces an animated bubble sized by magnitude and a musical note pitched by edit size -- larger edits sound lower, smaller edits sound higher.

The app connects to the [Wikimedia EventStreams](https://wikitech.wikimedia.org/wiki/Event_Platform/EventStreams) WebSocket feed and renders edits across 32 languages. Inspired by [listen.hatnote.com](http://listen.hatnote.com/) and a successor to [HatnoteListen](https://github.com/bryanoltman/HatnoteListen).

## Features

- Real-time Wikipedia edit stream across 32 languages
- Animated bubbles color-coded by edit type (registered, anonymous, bot) and direction (addition, deletion)
- Musical sonification via MIDI with configurable scales, keys, modes, and instruments
- Tap a bubble to see the article; tap the toast to open it in your browser

## Platforms

| Platform         | Directory          | Status    |
| ---------------- | ------------------ | --------- |
| iOS, macOS, tvOS | [`apple/`](apple/) | Available |
| Android          | `android/`         | Planned   |

See each platform directory for build instructions and platform-specific details.

## License

BSD 3-Clause. See [LICENSE](LICENSE) for details.

### Third-Party Assets

**GeneralUser GS SoundFont** by S. Christian Collins, licensed under a [custom permissive license](http://www.schristiancollins.com/generaluser.php).
