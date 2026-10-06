import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/database_service.dart';
import 'package:jumbo_music/services/music_player_manager.dart';
import 'package:jumbo_music/widgets/cover_image.dart';
import 'package:jumbo_music/widgets/mini_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.ryanheise.just_audio.methods'),
          (MethodCall methodCall) async {
            return {'id': 'fake_player_id'};
          },
        );
  });

  group('Player Rebuild Optimization & CoverImage Tests', () {
    late MusicPlayerManager manager;
    late DatabaseService db;

    const testSong = Song(
      id: 'rebuild_song_1',
      title: 'Performance Track',
      artist: 'Optimized Artist',
      album: 'Performance Album',
      coverUrl: 'https://example.com/cover.jpg',
      audioUrl: 'https://example.com/stream.mp3',
      duration: Duration(seconds: 240),
    );

    setUp(() async {
      db = DatabaseService.instance;
      await db.init();
      await db.switchUserScope(null);
      await db.clearAllUserData();

      manager = MusicPlayerManager();
      manager.allSongs.clear();
      manager.allSongs.add(testSong);
    });

    testWidgets(
      'MiniPlayer / parent subscriber does not rebuild on positionNotifier updates',
      (WidgetTester tester) async {
        int parentRebuildCount = 0;
        int seekbarRebuildCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  // Parent widget simulating MiniPlayer / screen listening to manager
                  AnimatedBuilder(
                    animation: manager,
                    builder: (context, child) {
                      parentRebuildCount++;
                      return Text(
                        'Song: ${manager.currentSong?.title ?? "None"}',
                      );
                    },
                  ),
                  // Dedicated seekbar listener simulating ValueListenableBuilder
                  ValueListenableBuilder<Duration>(
                    valueListenable: manager.positionNotifier,
                    builder: (context, pos, child) {
                      seekbarRebuildCount++;
                      return Text('Position: ${pos.inSeconds}s');
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();
        expect(find.text('Position: 0s'), findsOneWidget);

        final initialParentCount = parentRebuildCount;
        final initialSeekbarCount = seekbarRebuildCount;

        // Simulate multiple position updates
        manager.positionNotifier.value = const Duration(seconds: 5);
        await tester.pump();

        manager.positionNotifier.value = const Duration(seconds: 10);
        await tester.pump();

        manager.positionNotifier.value = const Duration(seconds: 15);
        await tester.pump();

        // Parent widget rebuild count MUST NOT increase during position ticks
        expect(
          parentRebuildCount,
          equals(initialParentCount),
          reason:
              'Parent widget listening to manager should not rebuild on position ticks',
        );

        // Dedicated seekbar listener MUST update
        expect(
          seekbarRebuildCount,
          equals(initialSeekbarCount + 3),
          reason: 'Only position listeners should rebuild on position ticks',
        );
        expect(find.text('Position: 15s'), findsOneWidget);

        // Real state changes (e.g. favorite / volume) MUST rebuild parent
        manager.toggleFavorite(testSong.id);
        await tester.pump();
        expect(parentRebuildCount, greaterThan(initialParentCount));
      },
    );

    testWidgets('MiniPlayer renders cleanly when no active playback', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MiniPlayer())),
      );

      await tester.pump();
      expect(find.byType(MiniPlayer), findsOneWidget);
    });

    testWidgets(
      'CoverImage renders fallback icon cleanly for invalid or empty URL',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CoverImage(
                imageUrl: '',
                width: 50,
                height: 50,
                fallbackIcon: Icons.music_note,
              ),
            ),
          ),
        );

        await tester.pump();
        expect(find.byIcon(Icons.music_note), findsOneWidget);
      },
    );
  });
}
