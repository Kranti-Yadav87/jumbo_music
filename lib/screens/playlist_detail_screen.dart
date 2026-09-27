import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/music_player_manager.dart';
import '../services/music_api_service.dart';
import '../widgets/song_tile.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  bool _isLoading = false;
  List<Song> _loadedSongs = [];

  @override
  void initState() {
    super.initState();
    _checkAndLoadSongs();
  }

  Future<void> _checkAndLoadSongs() async {
    final manager = MusicPlayerManager();
    final localSongs = manager.allSongs
        .where((song) => widget.playlist.songIds.contains(song.id))
        .toList();

    if (localSongs.isNotEmpty) {
      setState(() {
        _loadedSongs = localSongs;
      });
      return;
    }

    // If empty and has a remote numeric ID, fetch live
    if (int.tryParse(widget.playlist.id) != null) {
      setState(() {
        _isLoading = true;
      });

      final result = await MusicApiService.fetchPlaylist(widget.playlist.id);
      final songs = (result['songs'] as List<Song>?) ?? [];

      if (mounted) {
        setState(() {
          _loadedSongs = songs;
          _isLoading = false;
        });

        // Add to manager so player can play whole queue
        for (final s in songs) {
          if (!manager.allSongs.any((item) => item.id == s.id)) {
            manager.allSongs.add(s);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = MusicPlayerManager();

    return AnimatedBuilder(
      animation: manager,
      builder: (context, _) {
        final List<Song> playlistSongs = _loadedSongs.isNotEmpty
            ? _loadedSongs
            : manager.allSongs
                .where((song) => widget.playlist.songIds.contains(song.id))
                .toList();

        return Scaffold(
          backgroundColor: const Color(0xFF0C0C14),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Sliver App Bar with Playlist Cover
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: const Color(0xFF141424),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    widget.playlist.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        widget.playlist.coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF1E1B4B),
                          child: const Icon(Icons.queue_music, size: 60, color: Colors.white30),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              const Color(0xFF0C0C14).withOpacity(0.8),
                              const Color(0xFF0C0C14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Playlist Action Bar & Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.playlist.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${playlistSongs.length} songs',
                            style: const TextStyle(
                              color: Color(0xFF818CF8),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '320 KBPS LIVE MASTER',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.play_arrow_rounded, size: 24),
                              label: const Text(
                                'Play All',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: playlistSongs.isEmpty
                                  ? null
                                  : () {
                                      manager.playPlaylist(playlistSongs);
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.08),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.shuffle, size: 20),
                            label: const Text('Shuffle'),
                            onPressed: playlistSongs.isEmpty
                                ? null
                                : () async {
                                    if (!manager.isShuffle) {
                                      await manager.toggleShuffle();
                                    }
                                    manager.playPlaylist(playlistSongs);
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Song List or Loading
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF818CF8)),
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Loading live playlist tracks...',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                )
              else if (playlistSongs.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No tracks in this playlist yet',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = playlistSongs[index];
                      return SongTile(
                        song: song,
                        index: index + 1,
                        playlistContext: playlistSongs,
                      );
                    },
                    childCount: playlistSongs.length,
                  ),
                ),

              // Padding at the bottom for floating miniplayer
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        );
      },
    );
  }
}
