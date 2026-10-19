import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'music_player_manager.dart';
import '../widgets/now_playing/now_playing_lyrics_sheet.dart';

/// Wraps the application to provide global media keyboard shortcuts
/// (Space, N, P, M, L, F, Arrow keys) while ensuring that ALL keystrokes
/// are passed through untouched whenever any text input or search bar is focused.
class GlobalKeyboardShortcutsWrapper extends StatefulWidget {
  final Widget child;

  const GlobalKeyboardShortcutsWrapper({super.key, required this.child});

  @override
  State<GlobalKeyboardShortcutsWrapper> createState() =>
      _GlobalKeyboardShortcutsWrapperState();
}

class _GlobalKeyboardShortcutsWrapperState
    extends State<GlobalKeyboardShortcutsWrapper> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _isTextInputFocused() {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus == null) return false;

    final label = primaryFocus.debugLabel?.toLowerCase() ?? '';
    if (label.contains('editable') ||
        label.contains('input') ||
        label.contains('text') ||
        label.contains('search') ||
        label.contains('field')) {
      return true;
    }

    final focusedContext = primaryFocus.context;
    if (focusedContext != null) {
      if (focusedContext.widget is EditableText) return true;
      if (focusedContext.findAncestorWidgetOfExactType<EditableText>() !=
          null) {
        return true;
      }
      if (focusedContext.findAncestorWidgetOfExactType<TextField>() != null) {
        return true;
      }
      if (focusedContext.findAncestorWidgetOfExactType<TextFormField>() !=
          null) {
        return true;
      }
      if (focusedContext.findAncestorStateOfType<EditableTextState>() != null) {
        return true;
      }
    }
    return false;
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final key = event.logicalKey;

    // Dedicated hardware media keys (headsets, media keyboards) work globally
    if (key == LogicalKeyboardKey.mediaPlayPause) {
      MusicPlayerManager().togglePlay();
      return true;
    }
    if (key == LogicalKeyboardKey.mediaTrackNext) {
      MusicPlayerManager().next();
      return true;
    }
    if (key == LogicalKeyboardKey.mediaTrackPrevious) {
      MusicPlayerManager().previous();
      return true;
    }
    if (key == LogicalKeyboardKey.mediaStop) {
      MusicPlayerManager().pause();
      return true;
    }

    // 1. Critical: If any TextField or search input is focused, NEVER intercept standard typing!
    if (_isTextInputFocused()) {
      return false;
    }

    final isModifier =
        HardwareKeyboard.instance.isAltPressed ||
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    if (key == LogicalKeyboardKey.space && !isModifier) {
      MusicPlayerManager().togglePlay();
      return true;
    }

    // Letter shortcuts require Alt / Control / Meta to avoid hijacking letters in text fields
    if (key == LogicalKeyboardKey.keyN && isModifier) {
      MusicPlayerManager().next();
      return true;
    }
    if (key == LogicalKeyboardKey.keyP && isModifier) {
      MusicPlayerManager().previous();
      return true;
    }
    if (key == LogicalKeyboardKey.keyM && isModifier) {
      MusicPlayerManager().toggleMute();
      return true;
    }
    if (key == LogicalKeyboardKey.keyF && isModifier) {
      final song = MusicPlayerManager().currentSong;
      if (song != null) {
        MusicPlayerManager().toggleFavorite(song.id);
      }
      return true;
    }
    if (key == LogicalKeyboardKey.keyL && isModifier) {
      final manager = MusicPlayerManager();
      final song = manager.currentSong;
      if (song != null && mounted) {
        NowPlayingLyricsSheet.show(context, manager, song);
      }
      return true;
    }
    if (key == LogicalKeyboardKey.arrowRight && !isModifier) {
      final manager = MusicPlayerManager();
      final target = manager.position + const Duration(seconds: 10);
      manager.seek(target < manager.duration ? target : manager.duration);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowLeft && !isModifier) {
      final manager = MusicPlayerManager();
      final target = manager.position - const Duration(seconds: 10);
      manager.seek(target > Duration.zero ? target : Duration.zero);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowUp && !isModifier) {
      final manager = MusicPlayerManager();
      manager.setVolume((manager.volume + 0.1).clamp(0.0, 1.0));
      return true;
    }
    if (key == LogicalKeyboardKey.arrowDown && !isModifier) {
      final manager = MusicPlayerManager();
      manager.setVolume((manager.volume - 0.1).clamp(0.0, 1.0));
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
