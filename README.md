# Jumbo Music 🎵 — Professional Music Streaming & Social Player App

A high-performance, commercial-grade music streaming and player app built with **Flutter & Material 3**, **Firebase Auth + Cloud Firestore**, and a **custom music catalog API** with local caching and offline persistence.

---

## 🌟 Key Features

### 1. Real-time Social Presence & Friends Jam
- **Live Firestore Presence**: Authenticated users broadcast their active listening status (`currentSongTitle`, `currentSongArtist`, `currentSongCover`, `isListening`, `isOnline`) in real time.
- **Listen Together & Live Jam Rooms**: Synchronize playback with friends instantly or share a room code (`JUMBO-SYNC-XXXX`) for joint listening sessions.
- **Collaborative Duo Blend Playlists**: Synchronized playlists stored in Cloud Firestore where multiple friends can add and stream songs together.
- **Modular Friends Screen**: Broken down into maintainable submodules (`friend_listening_tile.dart`, `shared_playlist_dialog.dart`, `live_jam_dialog.dart`, `add_friend_dialog.dart`).

### 2. Real Offline Disk Downloads & Airplane Mode Playback
- **Persistent Local File Storage**: Songs downloaded via `DownloadService` are saved directly to local storage using `path_provider` (`FileDownloader`).
- **Offline Playback Engine**: `MusicPlayerManager` automatically detects when a downloaded file exists locally and streams directly from disk (`Uri.file(...)`) without requiring any internet connection.
- **Atomic Downloads**: Writes to a `.part` temporary file first so incomplete downloads are never corrupted.

### 3. Android Hardware Equalizer (EQ) Presets
- **Real Hardware Equalizer**: Utilizes `AndroidEqualizer` in `AudioPipeline` for true DSP sound modification on Android devices.
- **Pure Math Presets**: Mathematically calibrated frequency gain curves (`EqPresets`) for:
  - `Normal` (Flat reference response)
  - `Bass Boost` (Low-frequency enhancement)
  - `Vocal Booster` (Mid-range voice clarity)
  - `Acoustic` (Warm acoustic balance)
  - `Electronic` (V-shaped energetic response)
  - `Rock` (Punchy punch & highs)

### 4. Studio Player & Lock Screen Media Controls
- **Lock Screen & Notification Controls**: Integrated with `JustAudioBackground` and `MediaSessionService` for lock-screen controls, scrub bars, and metadata.
- **Bedtime Sleep Timer**: 15m, 30m, 45m, 60m, or "End of Current Song" with live countdown badge.
- **Synchronized Lyrics Drawer**: Slide-up sheet to read synced song lyrics (LRC).
- **Docked Mini-Player**: Floats above navigation with real-time waveform equalizer animation and expandable player.

### 5. Crash Reporting & Observability
- **Centralized Error Boundaries**: `CrashReportingService` captures Flutter widget errors (`FlutterError.onError`) and unhandled asynchronous exceptions (`PlatformDispatcher.instance.onError`).
- **Ready for Firebase Crashlytics & Sentry**: Hooked into the root application runner (`CrashReportingService.runWithCrashReporting`).

---

## 🚀 Setup & Commands

```bash
# 1. Install dependencies
flutter pub get

# 2. Run static analysis (0 warnings guaranteed)
flutter analyze --no-fatal-infos

# 3. Run full test suite
flutter test

# 4. Run on Chrome (Web)
flutter run -d chrome

# 5. Build Web Release
flutter build web --release --base-href /

# 6. Build Android APK
flutter build apk --release
```

### Custom Music API Configuration
Override the music backend endpoint without modifying code using `--dart-define`:
```bash
flutter run --dart-define=SPOTIFY_ENDPOINT=https://<project>.supabase.co/functions/v1/spotify \
            --dart-define=SPOTIFY_ANON_KEY=<anon-key>
```

---

## 🔒 Cloud Firestore Security Rules
Deploy Firestore security rules for user profile presence and shared playlists:
```bash
firebase deploy --only firestore:rules
```
