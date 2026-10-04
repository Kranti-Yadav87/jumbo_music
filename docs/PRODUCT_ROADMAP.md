# Product roadmap & honest gap list

## Jo code se nahi ho sakta (business / legal)
- **Licensed catalog**: Spotify-level catalog ke liye label licences chahiye. Legal raste: Jamendo (CC, free non-commercial), Audius, ya Apple Music/Spotify official SDK (user ka premium account, full streaming SDK ke through).
  Unofficial JioSaavn endpoint Play Store / takedown risk hai — publish karne se pehle replace karo.
- **ML personalization, global scale, iOS/TV/car** — team + funding ka kaam.

## Antigravity prompts (copy-paste)
1. **Friend requests**: "Add a friend-request flow: Firestore `friend_requests/{id}` (from, to, status), accept/decline UI in friends_screen, update firestore.rules, notifications, unit tests. Keep existing add-by-email as 'send request'. Run flutter analyze and flutter test."
2. **Split big files**: "Refactor library_tab.dart, profile_screen.dart and track_options_sheet.dart (~1000 lines each) into smaller widgets under lib/widgets/<feature>/ without behaviour change; keep all tests passing."
3. **Widget/integration tests**: "Add widget tests for mini_player, search_tab and login flow using fake services; target >60% coverage; add `flutter test --coverage` to CI."
4. **Gapless/crossfade**: "Use just_audio gapless playback via a playlist audio source, then add optional crossfade setting."
5. **Legal-mode catalog**: "Add AppConfig flag USE_UNOFFICIAL_CATALOG (default true). When false, home sections/search/playlists must use only Jamendo and show an empty-state when unconfigured."
6. **Crashlytics (optional)**: "Add firebase_crashlytics and wire it into CrashReportingService._send for mobile; add the Gradle plugin per FlutterFire docs."
