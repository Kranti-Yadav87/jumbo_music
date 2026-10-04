import 'package:flutter/material.dart';
import '../../models/playlist.dart';
import '../../services/music_api_service.dart';
import '../../screens/playlist_detail_screen.dart';
import 'home_section_header.dart';

class _Mood {
  final String name;
  final String query;
  final IconData icon;
  final List<Color> colors;
  const _Mood(this.name, this.query, this.icon, this.colors);
}

/// Replaces the old "Top 50" row with mood based mixes.
class MoodMixesSection extends StatefulWidget {
  const MoodMixesSection({super.key});

  @override
  State<MoodMixesSection> createState() => _MoodMixesSectionState();
}

class _MoodMixesSectionState extends State<MoodMixesSection> {
  static const List<_Mood> _moods = [
    _Mood('Romance', 'romantic hindi songs', Icons.favorite_rounded, [
      Color(0xFFEC4899),
      Color(0xFFBE185D),
    ]),
    _Mood('Party', 'party songs dance hits', Icons.celebration_rounded, [
      Color(0xFFF59E0B),
      Color(0xFFD97706),
    ]),
    _Mood('Workout', 'workout gym songs', Icons.fitness_center_rounded, [
      Color(0xFFEF4444),
      Color(0xFF991B1B),
    ]),
    _Mood('Chill', 'chill lofi songs', Icons.spa_rounded, [
      Color(0xFF06B6D4),
      Color(0xFF0E7490),
    ]),
    _Mood(
      'Devotional',
      'bhajan devotional songs',
      Icons.self_improvement_rounded,
      [Color(0xFFF97316), Color(0xFFC2410C)],
    ),
    _Mood('Sad', 'sad emotional songs', Icons.water_drop_rounded, [
      Color(0xFF6366F1),
      Color(0xFF3730A3),
    ]),
    _Mood('Retro', 'old hindi evergreen songs', Icons.album_rounded, [
      Color(0xFF8B5CF6),
      Color(0xFF5B21B6),
    ]),
    _Mood('Road Trip', 'road trip songs', Icons.directions_car_rounded, [
      Color(0xFF10B981),
      Color(0xFF047857),
    ]),
  ];

  String? _loadingMood;

  Future<void> _open(_Mood mood) async {
    if (_loadingMood != null) return;
    setState(() => _loadingMood = mood.name);
    final songs = await MusicApiService.searchLiveSongs(mood.query, limit: 30);
    if (!mounted) return;
    setState(() => _loadingMood = null);
    if (songs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load ${mood.name} mix. Try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final playlist = Playlist(
      id: 'mood_${mood.name.toLowerCase()}',
      title: '${mood.name} Mix',
      description: 'Handpicked ${mood.name.toLowerCase()} songs',
      coverUrl: songs.first.coverUrl,
      songIds: songs.map((s) => s.id).toList(),
      songs: songs,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaylistDetailScreen(playlist: playlist),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionHeader(
          title: 'Mood Mixes',
          subtitle: 'Music for every moment',
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _moods.length,
            itemBuilder: (context, i) {
              final mood = _moods[i];
              final loading = _loadingMood == mood.name;
              return GestureDetector(
                onTap: () => _open(mood),
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: mood.colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Icon(mood.icon, color: Colors.white, size: 26),
                      Text(
                        mood.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
