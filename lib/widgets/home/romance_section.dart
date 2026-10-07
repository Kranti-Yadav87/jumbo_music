import 'package:flutter/material.dart';
import '../../data/music_repository.dart';
import '../../models/song.dart';
import '../../services/music_api_service.dart';
import 'home_section_header.dart';
import 'song_cover_card.dart';

/// Dedicated Soulful Romance / Love Hits section on Home tab.
class RomanceSection extends StatefulWidget {
  const RomanceSection({super.key});

  @override
  State<RomanceSection> createState() => _RomanceSectionState();
}

class _RomanceSectionState extends State<RomanceSection> {
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRomanceSongs();
  }

  Future<void> _loadRomanceSongs() async {
    try {
      final songs = await MusicApiService.searchLiveSongs(
        'romantic hindi bollywood love songs hits',
        limit: 25,
      );
      if (!mounted) return;
      setState(() {
        _songs = songs.isNotEmpty ? songs : MusicRepository.romanceEssentials;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _songs = MusicRepository.romanceEssentials;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSongs = _songs.isNotEmpty
        ? _songs
        : MusicRepository.romanceEssentials;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionHeader(
          title: 'Soulful Romance ❤️',
          subtitle: 'Timeless love anthems & heart-touching melodies',
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
                  color: Color(0xFFEC4899),
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
