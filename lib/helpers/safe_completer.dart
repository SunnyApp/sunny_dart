import 'dart:async';

class SafeCompleter<T> implements Completer<T> {
  bool _isStarted = false;
  Completer<T> _delegate = Completer<T>();

  SafeCompleter() : _isStarted = true;
  SafeCompleter.stopped() : _isStarted = false;

  bool get isNotStarted => !_isStarted;
  bool get isStarted => _isStarted;
  bool get isActive => _isStarted && isNotComplete;
  bool get isNotComplete => !isCompleted;

  @override
  void complete([FutureOr<T> value]) {
    assert(_isStarted == true, "Completing a future that hasn't been started...");
    if (!_delegate.isCompleted) _delegate.complete(value);
  }

  @override
  void completeError(Object error, [StackTrace stackTrace]) {
    assert(_isStarted == true, "Completing a future that hasn't been started...");
    if (!_delegate.isCompleted) _delegate.completeError(error, stackTrace);
  }

  @override
  Future<T> get future => _delegate.future;

  @override
  bool get isCompleted => _delegate.isCompleted;

  void reset([T value]) {
    if (isActive) {
      complete(value);
      _delegate = Completer<T>();
    } else if (_isStarted) {
      _delegate = Completer<T>();
    }
    _isStarted = false;
  }

  void start() {
    _isStarted = true;
  }
}
