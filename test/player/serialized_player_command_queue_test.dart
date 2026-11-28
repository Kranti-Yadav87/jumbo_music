import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/services/player/serialized_player_command_queue.dart';

void main() {
  group('SerializedPlayerCommandQueue', () {
    test('executes a pending operation before the next operation', () async {
      final queue = SerializedPlayerCommandQueue();
      final firstStarted = Completer<void>();
      final releaseFirst = Completer<void>();
      final order = <String>[];

      final first = queue.run(() async {
        order.add('source-start');
        firstStarted.complete();
        await releaseFirst.future;
        order.add('source-finished');
      });

      await firstStarted.future;

      final stop = queue.run(() async {
        order.add('stop');
      });

      expect(order, ['source-start']);

      releaseFirst.complete();
      await Future.wait([first, stop]);

      expect(order, ['source-start', 'source-finished', 'stop']);
    });

    test('continues processing after an operation fails', () async {
      final queue = SerializedPlayerCommandQueue();
      final order = <String>[];

      final failed = queue.run<void>(() async {
        order.add('failed-operation');
        throw StateError('Expected test failure');
      });

      final next = queue.run(() async {
        order.add('next-operation');
      });

      await expectLater(failed, throwsA(isA<StateError>()));
      await next;

      expect(order, ['failed-operation', 'next-operation']);
    });
  });
}
