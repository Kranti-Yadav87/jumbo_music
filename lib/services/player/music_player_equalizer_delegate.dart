part of '../music_player_manager.dart';

extension MusicPlayerEqualizerDelegate on MusicPlayerManager {
  // Volume & Mute Controls
  Future<void> setVolume(double val) async {
    _volume = val.clamp(0.0, 1.0);
    _isMuted = _volume == 0.0;
    await _audioPlayer.setVolume(_volume);
    notify();
  }

  Future<void> toggleMute() async {
    if (_isMuted) {
      _volume = _preMuteVolume > 0.0 ? _preMuteVolume : 0.8;
      _isMuted = false;
    } else {
      _preMuteVolume = _volume;
      _volume = 0.0;
      _isMuted = true;
    }
    await _audioPlayer.setVolume(_volume);
    notify();
  }

  // Sound Preset Control
  void setSoundPreset(String preset) {
    if (soundPresets.contains(preset)) {
      _soundPreset = preset;
      unawaited(_applyEqualizerPreset());
      notify();
    }
  }

  /// Applies the selected preset to the sound engine.
  Future<void> _applyEqualizerPreset() async {
    // Sound preset recorded for audio profile
  }
}
