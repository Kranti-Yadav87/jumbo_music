import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'music_player_manager.dart';

class GlobalKeyboardShortcutsWrapper extends StatelessWidget {
  final Widget child;

  const GlobalKeyboardShortcutsWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.space): () {
          MusicPlayerManager().togglePlay();
        },
        const SingleActivator(LogicalKeyboardKey.arrowRight): () {
          final manager = MusicPlayerManager();
          final target = manager.position + const Duration(seconds: 5);
          manager.seek(target < manager.duration ? target : manager.duration);
        },
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
          final manager = MusicPlayerManager();
          final target = manager.position - const Duration(seconds: 5);
          manager.seek(target > Duration.zero ? target : Duration.zero);
        },
        const SingleActivator(LogicalKeyboardKey.arrowUp): () {
          final manager = MusicPlayerManager();
          manager.setVolume((manager.volume + 0.1).clamp(0.0, 1.0));
        },
        const SingleActivator(LogicalKeyboardKey.arrowDown): () {
          final manager = MusicPlayerManager();
          manager.setVolume((manager.volume - 0.1).clamp(0.0, 1.0));
        },
        const SingleActivator(LogicalKeyboardKey.keyM): () {
          MusicPlayerManager().toggleMute();
        },
        const SingleActivator(LogicalKeyboardKey.keyN): () {
          MusicPlayerManager().next();
        },
        const SingleActivator(LogicalKeyboardKey.keyP): () {
          MusicPlayerManager().previous();
        },
        const SingleActivator(LogicalKeyboardKey.keyF): () {
          final song = MusicPlayerManager().currentSong;
          if (song != null) {
            MusicPlayerManager().toggleFavorite(song.id);
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}
