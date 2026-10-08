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

  // Graphic Equalizer & DSP Controls
  void toggleEqualizer(bool enabled) {
    _equalizerEnabled = enabled;
    DatabaseService.instance.updateSetting('eq_enabled', enabled);
    _applyEqualizerPreset();
    notify();
  }

  void setSoundPreset(String preset) {
    _soundPreset = preset;
    if (_customPresets.containsKey(preset)) {
      _bandGains = List<double>.from(_customPresets[preset]!);
    } else {
      _bandGains = EqPresets.getGainsForPreset(preset);
    }
    DatabaseService.instance.updateSetting('eq_preset', preset);
    DatabaseService.instance.updateSetting('soundPreset', preset);
    DatabaseService.instance.updateSetting('eq_gains', _bandGains);
    _applyEqualizerPreset();
    notify();
  }

  void setBandGain(int bandIndex, double gainDb) {
    if (bandIndex < 0 || bandIndex >= _bandGains.length) return;
    _bandGains[bandIndex] = gainDb.clamp(-12.0, 12.0);
    _soundPreset = 'Custom';
    DatabaseService.instance.updateSetting('eq_preset', 'Custom');
    DatabaseService.instance.updateSetting('soundPreset', 'Custom');
    DatabaseService.instance.updateSetting('eq_gains', _bandGains);
    _applyEqualizerPreset();
    notify();
  }

  void setBassBoost(double value) {
    _bassBoost = value.clamp(0.0, 1.0);
    DatabaseService.instance.updateSetting('eq_bass', _bassBoost);
    _applyEqualizerPreset();
    notify();
  }

  void setVirtualizer(double value) {
    _virtualizer = value.clamp(0.0, 1.0);
    DatabaseService.instance.updateSetting('eq_virtualizer', _virtualizer);
    _applyEqualizerPreset();
    notify();
  }

  void setLoudnessGain(double value) {
    _loudnessGain = value.clamp(0.0, 1.0);
    DatabaseService.instance.updateSetting('eq_loudness', _loudnessGain);
    _applyEqualizerPreset();
    notify();
  }

  void saveCustomPreset(String name, List<double> gains) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;
    _customPresets[cleanName] = List<double>.from(gains);
    _soundPreset = cleanName;
    _bandGains = List<double>.from(gains);
    DatabaseService.instance.updateSetting('eq_preset', cleanName);
    DatabaseService.instance.updateSetting('soundPreset', cleanName);
    DatabaseService.instance.updateSetting('eq_custom_presets', _customPresets);
    _applyEqualizerPreset();
    notify();
  }

  void deleteCustomPreset(String name) {
    if (_customPresets.containsKey(name)) {
      _customPresets.remove(name);
      if (_soundPreset == name) {
        setSoundPreset('Normal');
      }
      DatabaseService.instance.updateSetting(
        'eq_custom_presets',
        _customPresets,
      );
      notify();
    }
  }

  void resetEqualizer() {
    _soundPreset = 'Normal';
    _bandGains = [0.0, 0.0, 0.0, 0.0, 0.0];
    _bassBoost = 0.0;
    _virtualizer = 0.0;
    _loudnessGain = 0.0;
    DatabaseService.instance.updateSetting('eq_preset', 'Normal');
    DatabaseService.instance.updateSetting('soundPreset', 'Normal');
    DatabaseService.instance.updateSetting('eq_gains', _bandGains);
    DatabaseService.instance.updateSetting('eq_bass', 0.0);
    DatabaseService.instance.updateSetting('eq_virtualizer', 0.0);
    DatabaseService.instance.updateSetting('eq_loudness', 0.0);
    _applyEqualizerPreset();
    notify();
  }

  /// Applies active DSP and equalizer curve to audio engine
  Future<void> _applyEqualizerPreset() async {
    // 1. Web Audio DSP Live Biquad Filtering
    if (kIsWeb) {
      WebDspBridge.applyEqualizer(
        enabled: _equalizerEnabled,
        gains: _bandGains,
        bass: _bassBoost,
        virtualizer: _virtualizer,
        loudness: _loudnessGain,
      );
    }

    // 2. Android Hardware Equalizer & Loudness Enhancer
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _androidEqualizer.setEnabled(_equalizerEnabled);
        if (_equalizerEnabled) {
          final params = await _androidEqualizer.parameters;
          if (params.bands.isNotEmpty) {
            final gains = EqPresets.gainsFor(
              _soundPreset,
              bandCount: params.bands.length,
              minDb: params.minDecibels,
              maxDb: params.maxDecibels,
            );
            for (int i = 0; i < params.bands.length && i < gains.length; i++) {
              await params.bands[i].setGain(gains[i]);
            }
          }
          await _androidLoudnessEnhancer.setEnabled(_loudnessGain > 0.0);
          if (_loudnessGain > 0.0) {
            await _androidLoudnessEnhancer.setTargetGain(
              _loudnessGain * 1000.0,
            );
          }
        }
      } catch (e) {
        debugPrint('Android EQ apply note: $e');
      }
    }

    // Dynamic Volume scaling for loudness gain on other platforms
    if (_equalizerEnabled &&
        _loudnessGain > 0.0 &&
        !kIsWeb &&
        defaultTargetPlatform != TargetPlatform.android) {
      final boosted = (_volume * (1.0 + _loudnessGain * 0.25)).clamp(0.0, 1.0);
      await _audioPlayer.setVolume(boosted);
    } else {
      await _audioPlayer.setVolume(_volume);
    }
  }
}
