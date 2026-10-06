import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;
import '../models/song.dart';
import 'music_player_manager.dart';

/// Custom [AudioHandler] connecting Jumbo Music's [MusicPlayerManager] to
/// native Android notification and lock screen media controls.
class JumboAudioHandler extends BaseAudioHandler with SeekHandler {
  final MusicPlayerManager _manager;
  VoidCallback? _managerListener;

  JumboAudioHandler(this._manager) {
    _managerListener = _syncStateFromManager;
    _manager.addListener(_managerListener!);
    _syncStateFromManager();
  }

  @visibleForTesting
  MusicPlayerManager get manager => _manager;

  void _syncStateFromManager() {
    final song = _manager.currentSong;
    final isPlaying = _manager.isPlaying;
    final isBuffering = _manager.isBuffering;
    final isFavorite = song != null
        ? _manager.favoriteIds.contains(song.id)
        : false;
    final loopMode = _manager.loopMode;

    // 1. Update MediaItem when song metadata or duration changes
    if (song != null) {
      final currentItem = mediaItem.value;
      if (currentItem == null ||
          currentItem.id != song.id ||
          currentItem.duration != song.duration) {
        final coverUri = _parseArtUri(song.coverUrl);
        mediaItem.add(
          MediaItem(
            id: song.id,
            title: song.title,
            artist: song.artist,
            album: song.album.isNotEmpty ? song.album : 'Jumbo Music',
            duration: song.duration > Duration.zero ? song.duration : null,
            artUri: coverUri,
          ),
        );
      }
    } else {
      if (mediaItem.value != null) {
        mediaItem.add(null);
      }
    }

    // 2. Publish PlaybackState
    final processingState = _computeProcessingState(song, isBuffering);

    final List<MediaControl> controls = [
      MediaControl.custom(
        androidIcon: isFavorite
            ? 'drawable/ic_action_favorite_on'
            : 'drawable/ic_action_favorite_off',
        label: isFavorite ? 'Favorited' : 'Favorite',
        name: 'toggleFavorite',
      ),
      MediaControl.skipToPrevious,
      if (isPlaying) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
      MediaControl.custom(
        androidIcon: loopMode == LoopMode.one
            ? 'drawable/ic_action_repeat_one'
            : 'drawable/ic_action_repeat',
        label: loopMode == LoopMode.one ? 'Repeat One' : 'Repeat All',
        name: 'toggleRepeat',
      ),
    ];

    final state = PlaybackState(
      controls: controls,
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.setRepeatMode,
      },
      androidCompactActionIndices: const [1, 2, 3],
      processingState: processingState,
      playing: isPlaying,
      updatePosition: _manager.position,
      bufferedPosition: _manager.bufferedPosition,
      speed: _manager.playbackSpeed,
      queueIndex: _manager.currentIndex >= 0 ? _manager.currentIndex : null,
    );

    playbackState.add(state);
  }

  Uri? _parseArtUri(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();
    final httpsUrl = trimmed.startsWith('http://')
        ? 'https://${trimmed.substring(7)}'
        : trimmed;
    return Uri.tryParse(httpsUrl);
  }

  AudioProcessingState _computeProcessingState(Song? song, bool isBuffering) {
    if (song == null) return AudioProcessingState.idle;
    if (isBuffering) return AudioProcessingState.buffering;
    return AudioProcessingState.ready;
  }

  @override
  Future<void> play() async {
    await _manager.play();
    _syncStateFromManager();
  }

  @override
  Future<void> pause() async {
    await _manager.pause();
    _syncStateFromManager();
  }

  @override
  Future<void> stop() async {
    await _manager.stop();
    _syncStateFromManager();
  }

  @override
  Future<void> seek(Duration position) async {
    await _manager.seek(position);
    _syncStateFromManager();
  }

  @override
  Future<void> skipToNext() async {
    await _manager.next();
    _syncStateFromManager();
  }

  @override
  Future<void> skipToPrevious() async {
    await _manager.previous();
    _syncStateFromManager();
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'favorite' || name == 'toggleFavorite') {
      final current = _manager.currentSong;
      if (current != null) {
        _manager.toggleFavorite(current.id);
      }
    } else if (name == 'repeat' || name == 'toggleRepeat') {
      _manager.toggleLoopMode();
    }
    _syncStateFromManager();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _manager.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _manager.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _manager.setLoopMode(LoopMode.all);
        break;
    }
    _syncStateFromManager();
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }

  void dispose() {
    if (_managerListener != null) {
      _manager.removeListener(_managerListener!);
      _managerListener = null;
    }
  }
}
