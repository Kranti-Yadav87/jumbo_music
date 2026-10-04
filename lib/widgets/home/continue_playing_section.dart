import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../services/database_service.dart';
import '../../services/music_player_manager.dart';
import 'home_section_header.dart';
import 'song_cover_card.dart';
import '../../services/crash_reporting_service.dart';

/// "Continue Playing": the song that is loaded right now, then recent history.
class ContinuePlayingSection extends StatelessWidget {
  const ContinuePlayingSection({super.key});

  static List<Song> recentSongs(
    List<Map<String, dynamic>> history,
    Song? current, {
    int max = 12,
  }) {
    final out = <Song>[];
    final seen = <String>{};
    if (current != null && seen.add(current.id)) out.add(current);
    for (final item in history) {
      final raw = item['song'];
      if (raw is! Map) continue;
      try {
        final song = Song.fromJson(Map<String, dynamic>.from(raw));
        if (song.audioUrl.isNotEmpty && seen.add(song.id)) out.add(song);
      } catch (error) {
        CrashReportingService.swallow(
          error,
          'continue_playing_section.dart:26',
        );
      }
      if (out.length >= max) break;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    final manager = MusicPlayerManager();
    return AnimatedBuilder(
      animation: Listenable.merge([db, manager]),
      builder: (context, _) {
        final songs = recentSongs(db.history, manager.currentSong);
        if (songs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomeSectionHeader(
              title: 'Continue Playing',
              subtitle: 'Pick up where you left off',
            ),
            SongCoverRow(songs: songs),
          ],
        );
      },
    );
  }
}
