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

  /// Applies the selected preset to the Android hardware equalizer.
  Future<void> _applyEqualizerPreset() async {
    final eq = _equalizer;
    if (eq == null) return;
    try {
      final params = await eq.parameters;
      final gains = EqPresets.gainsFor(
        _soundPreset,
        bandCount: params.bands.length,
        minDb: params.minDecibels,
        maxDb: params.maxDecibels,
      );
      for (var i = 0; i < params.bands.length; i++) {
        await params.bands[i].setGain(gains[i]);
      }
      await eq.setEnabled(_soundPreset != 'Normal');
    } catch (e) {
      debugPrint('Equalizer note: $e');
    }
  }
}
