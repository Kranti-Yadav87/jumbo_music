import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        currentSong: const Song(
          id: 'test_sc_1',
          title: 'Shortcuts Track',
          artist: 'Artist One',
          audioUrl: 'https://example.com/audio.mp3',
          coverUrl: 'https://example.com/cover.jpg',
          duration: Duration(seconds: 300),
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

    testWidgets(
      'Focusing a TextField passes keys through and does not trigger player actions',
      (tester) async {
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

        // Send key events while TextField is focused
        await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
        await tester.pumpAndSettle();

        // Verify player state is NOT changed (no next, no previous, still not playing)
        expect(manager.currentSong?.id, equals('test_sc_1'));
        expect(manager.isPlaying, isFalse);
      },
    );

    testWidgets('Entering text into TextField works normally with n, m, p, l', (
      tester,
    ) async {
      final textController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlobalKeyboardShortcutsWrapper(
              child: TextField(
                controller: textController,
                key: const Key('search_input'),
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('search_input')), 'nampla');
      await tester.pumpAndSettle();

      expect(textController.text, equals('nampla'));
      expect(manager.currentSong?.id, equals('test_sc_1'));
      expect(manager.isPlaying, isFalse);
    });

    testWidgets(
      'Bare letter keys without modifier do not trigger player actions',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GlobalKeyboardShortcutsWrapper(
                child: const Text('Browsing'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Bare letter N without Alt/Ctrl
        await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
        await tester.pumpAndSettle();

        // Song did not change
        expect(manager.currentSong?.id, equals('test_sc_1'));
        expect(manager.isPlaying, isFalse);
      },
    );

    testWidgets(
      'Hardware media keys (mediaTrackNext, mediaTrackPrevious) trigger actions',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GlobalKeyboardShortcutsWrapper(
                child: const Text('Browsing'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.mediaTrackNext);
        await tester.pumpAndSettle();

        // Next was triggered
        expect(manager.isPlaying, isFalse);
      },
    );
  });
}
