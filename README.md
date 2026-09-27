# Jumbo Music 🎵 — Professional Music Streaming & Player App

A high-performance, commercial-grade music streaming and player app built with Flutter & Material 3.

---

## 🌟 Professional Features

### 1. Live Worldwide & Indian Music Search & Streaming
- Real-time online music searching powered by the Apple/iTunes Music API.
- Search **ANY** artist, singer, song, or album (e.g. *Arijit Singh, Diljit Dosanjh, Sidhu Moosewala, Shreya Ghoshal, Badshah, AP Dhillon, Taylor Swift, The Weeknd*).
- 600x600 HD album artwork upscaling with instant, crystal-clear 256/320 kbps streaming audio.
- Pre-loaded with dynamic trending Bollywood and Global hits.

### 2. Studio Now Playing Player
- **Vinyl Spin & Pulse**: Dynamic turntable vinyl animation while playback is active.
- **Interactive Scrubbing / Seek Bar**: High-precision slider with elapsed time and total duration.
- **Smart Controls**: Previous (restarts if elapsed > 3s, otherwise jumps to previous), Hero Play/Pause button with glowing gradient ring, Next, Shuffle mode, Repeat modes (Off, All, One).
- **Bedtime Sleep Timer**: 15m, 30m, 45m, 60m, or "End of Current Song" with live countdown badge.
- **Equalizer / Sound Presets**: Normal, Bass Boost, Vocal Booster, Acoustic, Electronic, Rock.
- **Volume & Mute Slider**: Integrated volume control with one-tap instant mute.
- **Synchronized Lyrics Drawer**: Slide-up sheet to read song lyrics.
- **Queue Management**: Swipe to delete from queue, tap to jump, and clear queue options.
- **Track Information Sheet**: Inspect title, artist, album, genre, release year, and audio bitrate.

### 3. Floating Docked Mini-Player
- Floats above the bottom navigation bar.
- Shows current song cover art, title, artist, animated equalizer sound waves, and quick play/pause/skip actions.
- Top edge linear progress indicator.
- Tap to smoothly expand into the full-screen player.

### 4. 4 Core Multi-Tab Sections
1. **Home**: Dynamic greeting (Good Morning / Afternoon / Evening), Featured Track Hero card, Genre filter chips (Bollywood, Lo-Fi, EDM, Acoustic, Chill, Pop), Curated Playlists scroll, Recently Played cards, and Ranked Trending tracks.
2. **Live Search & Explore**: Real-time live search with debounced typing, quick top artist chips (*Arijit Singh, Diljit Dosanjh, etc.*), and vibrant category cards.
3. **Library & Playlists**: Liked Songs quick access, curated playlists (Late Night Lo-Fi, Bollywood Sukoon, High Octane EDM, Acoustic & Chillout), and custom playlist creation dialog.
4. **Favorites**: One-tap "Play All" for all liked tracks, instant heart toggle.

### 5. Android 14+ Background Audio & APK Readiness
- Configured with `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, and `POST_NOTIFICATIONS` in `AndroidManifest.xml` so audio continues playing uninterrupted even when the screen is locked or the app is in the background.
- Clean application ID `com.jumbomusic.app` and release signing setup.

---

## 📱 How to Build the APK

### Option 1: Via Flutter CLI
Make sure Flutter is in your PATH, then run:
```bash
# Get dependencies
flutter pub get

# Build Release APK
flutter build apk --release
```
The generated APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

### Option 2: Via Android Studio (Installed on your Mac)
1. Open **Android Studio** (`/Applications/Android Studio.app`).
2. Click **Open** and select `/Users/suraj/Downloads/jumbo_music-main`.
3. In the top menu, go to **Build** → **Flutter** → **Build APK** (or **Build** → **Generate Signed Bundle / APK**).
4. Transfer the resulting `.apk` file to any Android phone to install and enjoy!

---

## 📁 Architecture Overview

```
lib/
├── data/
│   └── music_repository.dart       # Catalog of songs, genres, playlists & lyrics
├── models/
│   ├── playlist.dart               # Playlist data model
│   └── song.dart                   # Enhanced Song model with HD artwork & metadata
├── screens/
│   ├── favorites_tab.dart          # Liked tracks tab with Play All
│   ├── home_tab.dart               # Home screen with greeting, banner & genres
│   ├── library_tab.dart            # Playlists, Liked Songs & Custom Playlists
│   ├── main_navigation_screen.dart # Root Bottom Navigation controller
│   ├── playlist_detail_screen.dart # Playlist tracks & playback view
│   └── search_tab.dart             # Live online iTunes search & artist explorer
├── services/
│   ├── music_api_service.dart      # Real-time online music search client
│   └── music_player_manager.dart   # Central audio & state manager (ChangeNotifier)
├── widgets/
│   ├── equalizer_bars.dart         # Animated sound wave bars
│   ├── mini_player.dart            # Floating mini player
│   ├── now_playing_screen.dart     # Full-screen studio player
│   └── song_tile.dart              # Individual track tile with animations
└── main.dart                       # App initialization & theme setup
```
