# Jumbo Music 🎵 — Professional Music Streaming & Social Player App

A cross-platform (Android + Web/PWA) music streaming and social player app built with **Flutter & Material 3**, **Firebase Auth + Cloud Firestore**, and a **custom music catalog API** with local caching and offline persistence.

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
- **Global error boundaries**: `CrashReportingService` captures Flutter framework errors, unhandled async errors and root-zone errors.
- **Real remote reports (release builds)**: compact, size-limited, rate-limited and de-duplicated reports are written to the write-only Firestore collection `client_errors` (read them in the Firebase console). Disable/enable with `--dart-define=REPORT_ERRORS=false|true`.
- **No silent failures**: recoverable errors go through `CrashReportingService.swallow(...)` which leaves a breadcrumb that is attached to the next real report.
- **Legal full-length fallback catalog**: optional Jamendo provider (`--dart-define=JAMENDO_CLIENT_ID=...`).

---

## 🚀 Setup & Commands

```bash
# 1. Install dependencies
flutter pub get

# 2. Run static analysis
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

### Optional build-time configuration
```bash
flutter run --dart-define=JAMENDO_CLIENT_ID=<your-jamendo-client-id>
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


---

## What's new in this build
- **Home**: Continue Playing, Songs by Language (Hindi, English, Punjabi, Bhojpuri, Tamil, Telugu, Marathi, Bengali, Gujarati, Kannada, Malayalam, Haryanvi), Mood Mixes, and a New Releases row that shows *only* this year's songs.
- **Dark / light toggle** in the top bar.
- **Real share sheet** (WhatsApp, Instagram, ...) for songs and the app.
- **Offline downloads** on Android/desktop (files) *and* web (browser Cache Storage, only if the audio host allows CORS).
- **Play / pause fix**: playback is no longer awaited (the old code blocked next/prev and auto-advance).
- **Logout fix**: signing out always returns to the Login screen; back on Login exits the app.
- **Privacy**: `users/{uid}` is private. Friends search uses `public_profiles` (name + email, no bulk listing) and `presence` (read by id only).

## Android APK link (fixing the 404)
The in-app button opens `https://github.com/Kranti-Yadav87/jumbo_music/releases/latest/download/app-release.apk`.
That file exists only after the **Build & Publish Android APK** workflow succeeds once:
1. Push to `main` (or run the workflow manually in the Actions tab).
2. Wait until it creates a Release containing `app-release.apk`.
3. The in-app link then works. Override with `--dart-define=APK_URL=...` if you host the APK elsewhere.

Optional signing secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.

## After pulling this update
```bash
flutter pub get
flutter analyze
flutter test
firebase deploy --only firestore:rules   # new privacy rules
```
