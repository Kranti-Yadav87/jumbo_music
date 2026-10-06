# Product Roadmap & Architecture Notes

This document outlines active architecture features, completed milestones, and planned future enhancements.

---

## Completed Architecture Milestones

1. **Material 3 UI & Player Experience**:
   - Modern dark/light theme switching with smooth transitions.
   - Dynamic docked mini-player with live waveform visualization.
   - Studio player with full-screen gesture sheet, sleep timer, and synchronized LRC lyrics drawer.
   - Native Android lock-screen and notification media controls via `just_audio_background`.

2. **Offline Mode & Multi-Platform Download Engine**:
   - Native Android file persistence (`path_provider` + atomic `.part` downloads).
   - Web browser cache persistence via Cache API when CORS permits.
   - Smart local URI playback detection (`Uri.file(...)`) in `MusicPlayerManager`.

3. **Backend Integration on Zero-Cost Infrastructure**:
   - Firebase Spark tier: Auth (Google + Email/Password + Guest Anonymous), Cloud Firestore for presence, user profiles, and shared playlists.
   - Supabase Edge Functions proxy for music search and stream resolution without paid Cloud Functions.
   - Dual catalog support: Jamendo CC catalog fallback and configurable `--dart-define=USE_UNOFFICIAL_CATALOG=false`.

4. **Equalizer & Audio DSP**:
   - Real hardware DSP equalizer on Android (`AndroidEqualizer`).
   - Mathematically calibrated EQ presets (`EqPresets`: Normal, Bass Boost, Vocal Booster, Acoustic, Electronic, Rock).

---

## Planned Future Enhancements

1. **Social & Collaboration**:
   - Interactive friend requests (`friend_requests/{id}`) with real-time accept/decline notifications.
   - Live room audio sync timestamps for low-latency joint listening.

2. **Player Improvements**:
   - Seamless crossfade between tracks during playlist playback.
   - High-resolution cached album art prefetching for upcoming queue tracks.

3. **Platform Expansion**:
   - Desktop packaging (macOS, Windows, Linux).
   - Android Auto / Apple CarPlay media service integration.
