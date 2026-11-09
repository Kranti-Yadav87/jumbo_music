import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/services/player/youtube_web_player.dart';

void main() {
  test('YouTubeWebPlayer stub methods execute safely without error', () {
    // On native/VM test runner, YouTubeWebPlayer uses the stub
    expect(YouTubeWebPlayer.isSupported, isFalse);
    expect(YouTubeWebPlayer.getCurrentTime(), equals(0.0));
    expect(YouTubeWebPlayer.getDuration(), equals(0.0));
    expect(YouTubeWebPlayer.getState(), equals(-1));

    // Calling control methods does not throw
    YouTubeWebPlayer.play('test_id');
    YouTubeWebPlayer.pause();
    YouTubeWebPlayer.resume();
    YouTubeWebPlayer.seek(10.0);
    YouTubeWebPlayer.setVolume(0.8);
    YouTubeWebPlayer.stop();
    YouTubeWebPlayer.registerCallbacks(
      onStateChange: (state) {},
      onError: (err) {},
    );
  });
}
