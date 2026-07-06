import 'dart:async';

final class KugouRequestGate {
  KugouRequestGate({this.maxConcurrent = 4});

  final int maxConcurrent;
  int _activeRequests = 0;
  final List<Completer<void>> _queue = [];

  Future<T> run<T>(Future<T> Function() task) async {
    while (_activeRequests >= maxConcurrent) {
      final completer = Completer<void>();
      _queue.add(completer);
      await completer.future;
    }

    _activeRequests++;
    try {
      return await task();
    } finally {
      _activeRequests--;
      if (_queue.isNotEmpty) {
        final next = _queue.removeAt(0);
        next.complete();
      }
    }
  }
}
