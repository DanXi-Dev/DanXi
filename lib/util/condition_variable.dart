import 'dart:async';
import 'dart:collection';

import 'package:mutex/mutex.dart';

/// Copied from https://github.com/adrianjagielak/semaphore_plus/blob/master/lib/src/condition_variable/condition_variable.dart.

class ConditionVariable {
  final Queue<Completer<void>> _readyQueue = Queue<Completer<void>>();

  final Mutex _lock;

  ConditionVariable(this._lock);

  Future<void> signal() async {
    if (_readyQueue.isNotEmpty) {
      final completer = _readyQueue.removeFirst();
      completer.complete();
    }
  }

  Future<void> wait() async {
    final completer = Completer<void>();
    _readyQueue.add(completer);
    _lock.release();

    await completer.future;
    await _lock.acquire();
  }

  Future<void> broadcast() async {
    final completers = _readyQueue.toList();
    _readyQueue.clear();
    for (final completer in completers) {
      completer.complete();
    }
  }
}