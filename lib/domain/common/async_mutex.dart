import 'dart:async';

/// Serializes asynchronous operations, including nested work in the same task.
class AsyncMutex {
  Future<void> _tail = Future.value();

  Future<T> run<T>(Future<T> Function() action) {
    final owner = Zone.current[this];
    if (owner is _Owner && owner.active) return action();
    final operation = _tail.then((_) async {
      final owner = _Owner();
      try {
        return await runZoned(action, zoneValues: {this: owner});
      } finally {
        owner.active = false;
      }
    });
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }
}

class _Owner {
  bool active = true;
}

final _resourceLocks = Expando<AsyncMutex>();

/// All writers of a repository share its lock, including backup and reset.
AsyncMutex mutationLockFor(Object resource) =>
    _resourceLocks[resource] ??= AsyncMutex();
