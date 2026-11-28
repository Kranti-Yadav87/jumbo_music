import 'dart:async';

/// Executes asynchronous player commands in the order they are submitted.
class SerializedPlayerCommandQueue {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() operation) {
    final result = Completer<T>();

    final scheduled = _tail.then((_) async {
      try {
        result.complete(await operation());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });

    _tail = scheduled;
    return result.future;
  }
}
