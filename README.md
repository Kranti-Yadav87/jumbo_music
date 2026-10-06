# Jumbo Music 🎵 — Modern Music Streaming & Social Player

A cross-platform (Android, Web/PWA) music streaming and collaborative player built with **Flutter & Material 3**, **Firebase Auth & Cloud Firestore (Spark Free Tier)**, and a **Supabase Edge Function** proxy with local caching, offline persistence, and native background media controls.

---

## 🌟 Key Features

### 1. Modern Player Experience & Studio Controls
- **Full Studio Player**: Expandable full-screen player with artwork carousel, repeat/shuffle modes, seekable progress bar, and volume controls.
- **Docked Mini-Player**: Floats above navigation with real-time animated equalizer waveform and instant play/pause.
- **Lock-Screen & Notification Media Controls**: Native Android background media service powered by `just_audio_background` and web MediaSession API with lock-screen track information and playback controls.
- **Synchronized Lyrics Drawer**: Slide-up drawer parsing and highlighting synchronized LRC lyrics in real time.
- **Bedtime Sleep Timer**: Configurable timers (15m, 30m, 45m, 60m, or end-of-track) with countdown badge in the top bar.

### 2. Real Offline Downloads & Airplane Mode Playback
- **Atomic Local Storage**: Downloaded songs are safely written to local application storage via `path_provider` using temporary `.part` files to prevent corruption.
- **Smart Local URI Detection**: `MusicPlayerManager` automatically detects when a downloaded track exists and streams directly from disk (`file://`) without internet access.
- **Web PWA Cache Persistence**: Utilizes browser Cache Storage on Web when CORS permits.

### 3. Android Hardware Equalizer (EQ) Presets
- **Real Hardware DSP**: Integrates `AndroidEqualizer` in `AudioPipeline` for hardware-accelerated sound adjustment on Android.
- **Mathematical Presets**: Calibrated frequency gain curves (`EqPresets`) for `Normal`, `Bass Boost`, `Vocal Booster`, `Acoustic`, `Electronic`, and `Rock`.

### 4. Real-time Social Presence & Friends Jam
- **Live Firestore Presence**: Authenticated users broadcast active listening status (`currentSongTitle`, `currentSongArtist`, `currentSongCover`, `isListening`, `isOnline`) in real time.
- **Live Jam Rooms & Listen Together**: Synchronize playback with friends using 6-character room codes (`JUMBO-SYNC-XXXX`).
- **Collaborative Playlists**: Duo Blend playlists stored in Firestore where friends can curate shared music libraries.

### 5. Multi-Auth & Privacy-First Architecture
- **Flexible Sign-In**: Supports Google Sign-In, Email/Password authentication, and instant Anonymous Guest Mode.
- **Granular Firestore Security Rules**: Private user metadata (`users/{uid}`), read-by-ID presence documents (`presence/{uid}`), and write-only rate-limited error logs (`client_errors`).

### 6. Zero-Cost Free Backend & Catalog Options
- **Firebase Spark Plan**: Operates completely on the free Spark tier (no Cloud Functions required).
- **Supabase Edge Function**: Fast edge proxy for search and stream resolution.
- **Jamendo Legal Fallback**: Optional Creative Commons music catalog via `--dart-define=JAMENDO_CLIENT_ID=...` or strict legal mode via `--dart-define=USE_UNOFFICIAL_CATALOG=false`.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.12.0+ recommended)
- Java / Android SDK (for Android builds)
- Chrome / Edge (for Web development)

### Quick Start Commands

```bash
# 1. Install dependencies
flutter pub get

# 2. Run static analysis
flutter analyze --no-fatal-infos

# 3. Run full test suite
flutter test

# 4. Run on Chrome (Web)
flutter run -d chrome

# 5. Build Web Release (PWA)
flutter build web --release --base-href /

# 6. Build Android APK
flutter build apk --release
```

---

## 🔧 Build & Environment Flags

Configure app endpoints and keys at compile time using `--dart-define`:

| Flag | Description | Default |
|------|-------------|---------|
| `SPOTIFY_ENDPOINT` | Supabase Edge Function proxy URL | *Configured in AppConfig* |
| `SPOTIFY_ANON_KEY` | Supabase Anonymous JWT Key | *Configured in AppConfig* |
| `JAMENDO_CLIENT_ID` | Optional Jamendo API client ID | `""` |
| `USE_UNOFFICIAL_CATALOG` | Enable/disable unofficial proxy catalog | `true` |
| `REPORT_ERRORS` | Remote error reporting to Firestore | `true` in release |
| `APK_URL` | In-app Android APK download link | GitHub Releases URL |

---

## 📁 Documentation & Guides

- [Google Sign-In Setup & Diagnosis](docs/GOOGLE_SIGNIN_SETUP.md): SHA-1 registration, OAuth Web Client IDs, and Firebase setup.
- [Supabase Edge Function Guide](docs/SUPABASE_SETUP.md): Edge function deployment, API contracts, and proxy architecture.
- [Manual Steps & Deployment](docs/MANUAL_STEPS.md): Firestore security rules, error reporting validation, and release signing.
- [Product Roadmap](docs/PRODUCT_ROADMAP.md): Architecture status and future enhancements.

---

## 🛡️ Quality & Testing

Every commit passes the quality gate:
```bash
dart format lib test --set-exit-if-changed
flutter analyze --no-fatal-infos
flutter test
```
