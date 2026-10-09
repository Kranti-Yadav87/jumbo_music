import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'music_player_manager.dart';

import '../widgets/now_playing/now_playing_lyrics_sheet.dart';

class GlobalKeyboardShortcutsWrapper extends StatelessWidget {
  final Widget child;

  const GlobalKeyboardShortcutsWrapper({super.key, required this.child});

  bool _isTextInputFocused() {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus == null) return false;
    final focusedContext = primaryFocus.context;
    if (focusedContext != null) {
      if (focusedContext.widget is EditableText) return true;
      if (focusedContext.findAncestorWidgetOfExactType<EditableText>() !=
          null) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.space): () {
          if (_isTextInputFocused()) return;
          MusicPlayerManager().togglePlay();
        },
        const SingleActivator(LogicalKeyboardKey.arrowRight): () {
          if (_isTextInputFocused()) return;
          final manager = MusicPlayerManager();
          final target = manager.position + const Duration(seconds: 10);
          manager.seek(target < manager.duration ? target : manager.duration);
        },
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
          if (_isTextInputFocused()) return;
          final manager = MusicPlayerManager();
          final target = manager.position - const Duration(seconds: 10);
          manager.seek(target > Duration.zero ? target : Duration.zero);
        },
        const SingleActivator(LogicalKeyboardKey.arrowUp): () {
          if (_isTextInputFocused()) return;
          final manager = MusicPlayerManager();
          manager.setVolume((manager.volume + 0.1).clamp(0.0, 1.0));
        },
        const SingleActivator(LogicalKeyboardKey.arrowDown): () {
          if (_isTextInputFocused()) return;
          final manager = MusicPlayerManager();
          manager.setVolume((manager.volume - 0.1).clamp(0.0, 1.0));
        },
        const SingleActivator(LogicalKeyboardKey.keyM): () {
          if (_isTextInputFocused()) return;
          MusicPlayerManager().toggleMute();
        },
        const SingleActivator(LogicalKeyboardKey.keyN): () {
          if (_isTextInputFocused()) return;
          MusicPlayerManager().next();
        },
        const SingleActivator(LogicalKeyboardKey.keyP): () {
          if (_isTextInputFocused()) return;
          MusicPlayerManager().previous();
        },
        const SingleActivator(LogicalKeyboardKey.keyF): () {
          if (_isTextInputFocused()) return;
          final song = MusicPlayerManager().currentSong;
          if (song != null) {
            MusicPlayerManager().toggleFavorite(song.id);
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyL): () {
          if (_isTextInputFocused()) return;
          final manager = MusicPlayerManager();
          final song = manager.currentSong;
          if (song != null && context.mounted) {
            NowPlayingLyricsSheet.show(context, manager, song);
          }
        },
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
