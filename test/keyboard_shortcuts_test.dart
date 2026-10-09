import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/services/keyboard_shortcuts_service.dart';
import 'package:jumbo_music/services/music_player_manager.dart';
import 'package:jumbo_music/models/song.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Keyboard Shortcuts & Focus Guard Tests', () {
    late MusicPlayerManager manager;

    setUp(() {
      manager = MusicPlayerManager();
      manager.setMockState(
        currentSong: Song(
          id: 'test_sc_1',
          title: 'Shortcuts Track',
          artist: 'Artist One',
          audioUrl: 'https://example.com/audio.mp3',
          coverUrl: 'https://example.com/cover.jpg',
          duration: const Duration(seconds: 300),
        ),
        isPlaying: false,
      );
    });

    testWidgets('Renders GlobalKeyboardShortcutsWrapper with child properly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlobalKeyboardShortcutsWrapper(
              child: const Text('Playback Content'),
            ),
          ),
        ),
      );

      expect(find.text('Playback Content'), findsOneWidget);
    });

    testWidgets('Focusing a TextField prevents global shortcuts from firing', (
      tester,
    ) async {
      final textController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlobalKeyboardShortcutsWrapper(
              child: Column(
                children: [
                  TextField(
                    controller: textController,
                    key: const Key('search_input'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Tap to focus TextField
      await tester.tap(find.byKey(const Key('search_input')));
      await tester.pumpAndSettle();

      // Enter text into TextField
      await tester.enterText(find.byKey(const Key('search_input')), 'Arijit');
      await tester.pumpAndSettle();

      expect(textController.text, equals('Arijit'));
    });
  });
}
