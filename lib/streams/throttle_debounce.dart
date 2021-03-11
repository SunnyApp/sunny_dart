import 'dart:async';

abstract class Limiter {
  void limit([callback]);
}

class Throttler implements Limiter {
  final Duration delay;
  final callback;
  final List? args;
  final bool noTrailing;
  final Duration? max;

  // ignore: always_require_non_null_named_parameters
  Throttler(
      {required this.delay,
      this.callback,
      this.max,
      this.args,
      this.noTrailing = false});

  Timer? timeoutId;

  DateTime lastExec = DateTime.now();

  @override
  void limit([callback]) => throttle(callback);

  void throttle([callback]) {
    assert(callback != null || this.callback != null);
    Duration elapsed = DateTime.now().difference(lastExec);

    void exec() {
      lastExec = DateTime.now();
      if (callback != null) {
        callback();
      } else {
        this.callback(args);
      }
    }

    if (elapsed.compareTo(delay) >= 0 ||
        (max != null && elapsed.compareTo(max!) >= 0)) {
      exec();
    }

    ///cancel the timeout scheduled for trailing callback
    if (timeoutId != null) timeoutId!.cancel();

    if (noTrailing == false) {
      ///there should be a trailing callback, so schedule one
      ///buggy here, should be 'delay - elasped' but dart async only supports const Duration for delay
      timeoutId = Timer(delay, exec);
    }
  }
}

class Debouncer implements Limiter {
  final Duration delay;
  final callback;
  final List? args;
  final bool atBegin;

  // ignore: always_require_non_null_named_parameters
  Debouncer(
      {required this.delay, this.callback, this.args, this.atBegin = false});

  Timer? timer;

  @override
  void limit([callback]) => debounce(callback);

  void debounce([callback]) {
    void exec() {
      callback != null ? callback() : this.callback(args);
    }

    void clear() {
      timer = null;
    }

    /// cancel the previous timer if debounce is still being called before the delay period is over
    timer?.cancel();

    /// if atBegin is true, 'exec' has to executed the first time debounce gets called
    if (atBegin && timer == null) {
      exec();
    }

    /// schedule a new call after delay time
    timer = Timer(delay, atBegin ? clear : exec);
  }
}
