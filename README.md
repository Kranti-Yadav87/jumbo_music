# Jumbo Music 🎵 — High-Fidelity Music Streaming & Social Player

[![CI (analyze, test, web build)](https://github.com/Kranti-Yadav87/jumbo_music/actions/workflows/deploy-guard.yml/badge.svg)](https://github.com/Kranti-Yadav87/jumbo_music/actions/workflows/deploy-guard.yml)
[![Build & Publish Android APK](https://github.com/Kranti-Yadav87/jumbo_music/actions/workflows/build-apk.yml/badge.svg)](https://github.com/Kranti-Yadav87/jumbo_music/actions/workflows/build-apk.yml)
[![Firebase Hosting](https://img.shields.io/badge/Hosting-Live%20on%20Firebase-0284c7.svg)](https://jumbo-music-ff58c.web.app)
[![Flutter](https://img.shields.io/badge/Flutter-3.x%20%7C%20Material%203-blue.svg)](https://flutter.dev)

A cross-platform (Android APK + Web PWA / Desktop) high-fidelity music streaming and social player application built with **Flutter**, **Firebase Auth & Cloud Firestore**, **Web Audio DSP Biquad Filters**, and **Android Native AudioPipeline Hardware Effects**.

🌐 **Live Web App**: [https://jumbo-music-ff58c.web.app](https://jumbo-music-ff58c.web.app)  
📥 **Latest Android APK**: [Download APK Release](https://github.com/Kranti-Yadav87/jumbo_music/releases/latest/download/app-release.apk)

---

## 🌟 Key Architecture & Implemented Features

### 🎛️ 1. Studio-Grade 5-Band Graphic Equalizer & Real DSP Engine
- **Live Web Audio Biquad DSP Pipeline** (`web/index.html` & `lib/services/player/web_dsp_bridge.dart`):
  - Direct attachment to HTML5 audio stream with 5 cascaded `BiquadFilterNode`s (`60Hz` LowShelf, `230Hz` Peaking, `910Hz` Peaking, `3.6kHz` Peaking, `14kHz` HighShelf).
  - Dedicated **100Hz LowShelf Bass Boost** filter for low-frequency punch.
  - **Studio Dynamics Compressor** protecting against digital clipping at high gains (+12dB), dynamically bypassed with a 1:1 linear pass-through when EQ is disabled.
  - **Stereo Spatial Panner Node** for spatial virtualizer soundstage widening.
  - Master Loudness `GainNode` with smooth logarithmic `setTargetAtTime` curve updates.
- **Android Native Hardware Audio Pipeline** (`lib/services/music_player_manager.dart` & `lib/services/player/music_player_equalizer_delegate.dart`):
  - Configured with `AndroidEqualizer` and `AndroidLoudnessEnhancer` via `AudioPipeline` for true native sound processing.
  - `EqPresets.interpolateGains` dynamically maps user slider decibels (`_bandGains`) and low-end bass boost to hardware band count.
- **Dynamic Bézier Spline Visualization**: Real-time cubic spline frequency response curve painted with vibrant gradients (`EqualizerScreen`).
- **Custom Preset Manager**: Save, edit, and delete personalized custom EQ presets with local persistence.
- **12 Calibrated Factory Presets**: *Normal, Bass Boost, Pop, Rock, Electronic, Jazz, Acoustic, Classical, Hip Hop, Vocal Booster, Treble Boost, Deep Sub*.

### 🛡️ 2. Enterprise Security & Privacy Suite
- **Hardened Cloud Firestore Security Rules** (`firestore.rules`):
  - Complete user-scoped document isolation across all root documents and subcollections (`favorites`, `playlists`, `history`, `friends`, `settings`).
  - Strict schema whitelisting (`hasOnly`), string size limits, type checks, and atomic server timestamps (`request.time`).
  - Single-result anti-scraping query restriction on `/public_profiles` (`request.query.limit <= 1`).
  - Dedicated access controls for `shared_playlists`, and write-only constraints for crash reporting and app feedback.
- **Strict HTTP Web Security Headers** (`firebase.json`):
  - `Content-Security-Policy`: XSS and frame-injection protection (`frame-ancestors 'none'`, `object-src 'none'`).
  - `Strict-Transport-Security` (HSTS Preload enabled, `max-age=31536000`).
  - `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Cross-Origin-Opener-Policy: same-origin-allow-popups`.
- **Incognito Private Listening Mode**: 1-tap private session that automatically suppresses listening history, search query persistence, and Firestore live presence broadcasting.
- **GDPR Data Wipe & JSON Export**: Complete local/cloud personal data export and irreversible account erasure.

### 🎧 3. Social Presence & Collaborative Duo Blends
- **Live Social Presence**: Real-time broadcast of currently playing track, artist, album art, and listening state via Cloud Firestore.
- **1-Tap Live Sync**: Instantly jump into a friend's active playback stream with auto live-search fallback.
- **Collaborative Shared Playlists**: Synchronized playlists stored in Firestore (`shared_playlists` and user collections) where friends can curate music together in real time.

### 📱 4. True Offline Disk Downloads & Airplane Mode
- **Native Android / Desktop File Storage**: Downloads saved to device disk via `DownloadService` and `path_provider` (`Uri.file(...)`).
- **Web PWA Cache Storage**: Seamless browser audio caching using Web Cache API.
- **Atomic File Writing**: Downloads stream into temporary `.part` files preventing corrupted downloads on interrupted connections.

### ⌨️ 5. Web/PWA & Desktop Keyboard Shortcuts
- `Space`: Play / Pause (guarded when focused on text fields)
- `Arrow Right` / `Arrow Left`: Seek forward / backward (±10s)
- `Arrow Up` / `Arrow Down`: Volume adjustment
- `N` / `P`: Next / Previous track
- `M`: Mute / Unmute
- `F`: Toggle Favorite
- `L`: Open Synchronized Lyrics Drawer
- *Focus Protection*: All shortcuts are automatically suppressed when typing inside search or input fields.

### 🛠️ 6. Production Readiness & Observability
- **Global Error Boundaries**: Configured `FlutterError.onError`, `PlatformDispatcher.instance.onError`, and graceful fallback `ErrorWidget.builder`.
- **In-App Update Checker**: Automatic GitHub Releases verification alerting Android users when a new APK build is available.
- **Memory Optimization**: 120MB bounded image cache ceiling preventing memory leaks and OOM spikes.
- **Lock Screen & Media Controls**: Integrated with `JustAudioBackground` and `MediaSessionService` for lock screen controls, scrub bars, and metadata artwork.

---

## 🚀 Setup & Development

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.12.0+ recommended)
- Java 17+ (for Android builds)
- [Firebase CLI](https://firebase.google.com/docs/cli) (for deployment)

### CLI Commands
```bash
# 1. Install dependencies
flutter pub get

# 2. Format codebase
dart format lib test

# 3. Run static analysis (0 warnings / 0 errors)
flutter analyze --no-fatal-infos

# 4. Run automated test suite
flutter test

# 5. Run Web app locally
flutter run -d chrome

# 6. Build Web release
flutter build web --release --base-href /

# 7. Build Android release APK
flutter build apk --release
```

---

## 🔒 Firebase Deployment

Deploy Cloud Firestore Security Rules and Web Hosting:
```bash
# Deploy both Hosting and Firestore rules
firebase deploy --only hosting,firestore:rules
```

---

## 📦 Compile-Time Environment Flags

Pass flags at build/run time using `--dart-define`:
```bash
# Restrict catalog strictly to official Jamendo legal full tracks
flutter run --dart-define=USE_UNOFFICIAL_CATALOG=false

# Jamendo Client ID
flutter run --dart-define=JAMENDO_CLIENT_ID=<your-jamendo-client-id>

# Google Sign-In Web Client ID
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com

# Remote error reporting toggle
flutter run --dart-define=REPORT_ERRORS=false
```

---

## 📄 License
This project is open-source and available under the MIT License.
