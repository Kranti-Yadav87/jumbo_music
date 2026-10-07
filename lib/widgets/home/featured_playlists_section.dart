import 'package:flutter/material.dart';
import '../../data/music_repository.dart';
import '../../models/playlist.dart';
import '../../services/music_api_service.dart';
import '../../services/theme_service.dart';
import '../../screens/playlist_detail_screen.dart';
import '../app_cached_image.dart';
import 'home_section_header.dart';

class FeaturedPlaylistsSection extends StatefulWidget {
  const FeaturedPlaylistsSection({super.key});

  @override
  State<FeaturedPlaylistsSection> createState() =>
      _FeaturedPlaylistsSectionState();
}

class _FeaturedPlaylistsSectionState extends State<FeaturedPlaylistsSection> {
  String? _loadingPlaylistId;

  Future<void> _openPlaylist(BuildContext context, Playlist playlist) async {
    if (_loadingPlaylistId != null) return;
    setState(() => _loadingPlaylistId = playlist.id);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final songs = await MusicApiService.searchLiveSongs(
        '${playlist.title} best songs',
        limit: 35,
      );

      if (!mounted) return;

      final fullSongs = songs.isNotEmpty
          ? songs
          : await MusicApiService.searchLiveSongs(playlist.title, limit: 30);

      if (!mounted) return;

      final populated = Playlist(
        id: playlist.id,
        title: playlist.title,
        description: playlist.description,
        coverUrl: fullSongs.isNotEmpty
            ? fullSongs.first.coverUrl
            : playlist.coverUrl,
        songIds: fullSongs.map((s) => s.id).toList(),
        songs: fullSongs,
      );

      navigator.push(
        MaterialPageRoute(
          builder: (_) => PlaylistDetailScreen(playlist: populated),
        ),
      );
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Could not load "${playlist.title}". Try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingPlaylistId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlists = MusicRepository.featuredPlaylistsForYou;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionHeader(
          title: 'Featured Playlists For You',
          subtitle: 'Handpicked sets and daily recommendations',
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              final isLoading = _loadingPlaylistId == playlist.id;

              return GestureDetector(
                onTap: () => _openPlaylist(context, playlist),
                child: Container(
                  width: 155,
                  margin: const EdgeInsets.only(right: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          children: [
                            AppCachedImage(
                              imageUrl: playlist.coverUrl,
                              width: 155,
                              height: 155,
                              fit: BoxFit.cover,
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (isLoading)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withOpacity(0.6),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 26,
                                      height: 26,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF6366F1),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black45,
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        playlist.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppThemeManager.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        playlist.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppThemeManager.textSecondary(context),
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
