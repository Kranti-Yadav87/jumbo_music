import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/music_player_manager.dart';
import 'app_cached_image.dart';
import 'equalizer_bars.dart';
import 'now_playing_screen.dart';
import 'track_options_sheet.dart';

/// Opens the full player with the standard slide-up transition.
void openNowPlaying(BuildContext context, Song song) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (_, animation, __) => NowPlayingScreen(initialSong: song),
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    ),
  );
}

/// Height of a non-compact card for a given tile width (16:9 thumb + meta row).
double videoThumbnailCardExtent(double tileWidth) => tileWidth * 9 / 16 + 105;

/// YouTube-style 16:9 thumbnail card used by Search results and the Home feed.
class VideoThumbnailCard extends StatelessWidget {
  final Song song;
  final bool compact;
  final VoidCallback onPlay;

  const VideoThumbnailCard({
    super.key,
    required this.song,
    required this.compact,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final manager = MusicPlayerManager();
    return AnimatedBuilder(
      animation: manager,
      builder: (context, _) {
        final isCurrent = manager.currentSong?.id == song.id;
        final isPlaying = isCurrent && manager.isPlaying;
        final isFavorite = manager.isFavorite(song.id);
        return Semantics(
          button: true,
          container: true,
          label: 'Play ${song.title} by ${song.artist}',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('video-thumbnail-card-${song.id}'),
              onTap: onPlay,
              borderRadius: BorderRadius.circular(16),
              child: compact
                  ? _buildCompact(isCurrent, isPlaying, isFavorite, context)
                  : _buildGrid(isCurrent, isPlaying, isFavorite, context),
            ),
          ),
        );
      },
    );
  }

  Widget _playBadge(bool isPlaying, double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFFF0000),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
        color: Colors.white,
        size: size * 0.62,
      ),
    );
  }

  Widget _buildGrid(
    bool isCurrent,
    bool isPlaying,
    bool isFavorite,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppCachedImage(
                imageUrl: song.coverUrl,
                borderRadius: BorderRadius.circular(14),
                fallbackBgColor: const Color(0xFF181818),
              ),
              if (isCurrent)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: EqualizerBars(
                      isPlaying: isPlaying,
                      color: const Color(0xFFFF0000),
                      height: 24,
                    ),
                  ),
                ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    song.formattedDuration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(bottom: 8, left: 8, child: _playBadge(isPlaying, 34)),
            ],
          ),
        ),
        const SizedBox(height: 9),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: const Color(0xFF2A2A2A),
              child: Text(
                song.artist.isEmpty ? 'J' : song.artist[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(child: _titleBlock()),
            _actions(context, isFavorite),
          ],
        ),
      ],
    );
  }

  Widget _buildCompact(
    bool isCurrent,
    bool isPlaying,
    bool isFavorite,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFF241010) : const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? Colors.red.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              AppCachedImage(
                imageUrl: song.coverUrl,
                width: 128,
                height: 82,
                borderRadius: BorderRadius.circular(11),
                fallbackBgColor: const Color(0xFF181818),
              ),
              Positioned(bottom: 5, left: 5, child: _playBadge(isPlaying, 28)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(child: _titleBlock()),
          _actions(context, isFavorite),
        ],
      ),
    );
  }

  Widget _titleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          song.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          song.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white60, fontSize: 11.5),
        ),
        const SizedBox(height: 3),
        Text(
          song.genre.isEmpty ? 'Music' : song.genre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white38, fontSize: 10.5),
        ),
      ],
    );
  }

  Widget _actions(BuildContext context, bool isFavorite) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: ValueKey(
            isFavorite
                ? 'favorite-remove-button-${song.id}'
                : 'favorite-add-button-${song.id}',
          ),
          tooltip: isFavorite ? 'Remove from liked songs' : 'Like song',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? const Color(0xFFFF0000) : Colors.white54,
            size: 19,
          ),
          onPressed: () => MusicPlayerManager().toggleFavorite(song.id),
        ),
        IconButton(
          key: ValueKey('track-options-button-${song.id}'),
          tooltip: 'More options',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          icon: const Icon(
            Icons.more_vert_rounded,
            color: Colors.white54,
            size: 19,
          ),
          onPressed: () => TrackOptionsSheet.show(context, song),
        ),
      ],
    );
  }
}
