part of '../music_player_manager.dart';

extension MusicPlayerSleepTimer on MusicPlayerManager {
  void setSleepTimer(Duration duration) {
    cancelSleepTimer();
    _sleepSecondsRemaining = duration.inSeconds;
    _sleepAfterCurrentSong = false;
    notify();

    _sleepTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sleepSecondsRemaining > 0) {
        _sleepSecondsRemaining--;
        notify();
      } else {
        cancelSleepTimer();
        _audioPlayer.pause();
      }
    });
  }

  void setSleepTimerAfterSong() {
    cancelSleepTimer();
    _sleepAfterCurrentSong = true;
    notify();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTicker?.cancel();
    _sleepTimer = null;
    _sleepTicker = null;
    _sleepSecondsRemaining = 0;
    _sleepAfterCurrentSong = false;
    notify();
  }
}
