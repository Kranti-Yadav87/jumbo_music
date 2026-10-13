import 'package:flutter/material.dart';
import '../../data/music_repository.dart';
import '../../models/song.dart';
import '../../services/music_api_service.dart';
import 'home_section_header.dart';
import 'song_cover_card.dart';

/// Dedicated BTS / Bangtan Army & K-Pop Hits section on Home tab.
class BtsSection extends StatefulWidget {
  const BtsSection({super.key});

  @override
  State<BtsSection> createState() => _BtsSectionState();
}

class _BtsSectionState extends State<BtsSection> {
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBtsSongs();
  }

  Future<void> _loadBtsSongs() async {
    try {
      final songs = await MusicApiService.searchLiveSongs(
        'BTS Dynamite Butter Boy With Luv',
        limit: 25,
      );
      if (!mounted) return;
      setState(() {
        _songs = songs.isNotEmpty ? songs : MusicRepository.btsEssentials;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _songs = MusicRepository.btsEssentials;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSongs = _songs.isNotEmpty
        ? _songs
        : MusicRepository.btsEssentials;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionHeader(
          title: 'BTS Hits 💜',
          subtitle: 'Dynamite, Butter, Boy With Luv & Bangtan Army anthems',
        ),
        if (_isLoading)
          const SizedBox(
            height: 215,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ),
          )
        else
          SongCoverRow(songs: effectiveSongs),
      ],
    );
  }
}
