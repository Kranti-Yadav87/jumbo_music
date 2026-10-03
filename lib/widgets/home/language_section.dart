import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../services/music_api_service.dart';
import '../../services/theme_service.dart';
import 'home_section_header.dart';
import 'song_cover_card.dart';

/// Songs grouped by language: Hindi, English, Punjabi, Bhojpuri, Tamil...
class LanguageSection extends StatefulWidget {
  const LanguageSection({super.key});

  @override
  State<LanguageSection> createState() => _LanguageSectionState();
}

class _LanguageSectionState extends State<LanguageSection> {
  final Map<String, List<Song>> _cache = {};
  String _selected = 'Hindi';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _select('Hindi');
  }

  Future<void> _select(String language) async {
    setState(() => _selected = language);
    if (_cache.containsKey(language)) return;
    setState(() => _loading = true);
    List<Song> songs = [];
    try {
      songs = await MusicApiService.fetchByLanguage(language);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      if (songs.isNotEmpty) _cache[language] = songs;
      if (_selected == language) _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final songs = _cache[_selected] ?? const <Song>[];
    final languages = MusicApiService.homeLanguages.keys.toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionHeader(
          title: 'Songs by Language',
          subtitle: 'Hindi, English, Punjabi, Bhojpuri, Tamil & more',
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: languages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final lang = languages[i];
              final selected = lang == _selected;
              return ChoiceChip(
                label: Text(lang),
                selected: selected,
                onSelected: (_) => _select(lang),
                selectedColor: const Color(0xFFFF5E3A),
                backgroundColor: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : AppThemeManager.textPrimary(context),
                ),
                side: BorderSide.none,
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        if (_loading && songs.isEmpty)
          const SizedBox(
            height: 215,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF5E3A)),
            ),
          )
        else if (songs.isEmpty)
          SizedBox(
            height: 120,
            child: Center(
              child: TextButton.icon(
                onPressed: () => _select(_selected),
                icon: const Icon(Icons.refresh_rounded),
                label: Text('Could not load $_selected songs. Tap to retry'),
              ),
            ),
          )
        else
          SongCoverRow(songs: songs),
      ],
    );
  }
}
