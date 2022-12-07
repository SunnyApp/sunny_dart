import 'dart:async';

import 'package:chunked_stream/chunked_stream.dart';
import 'package:stream_transform/stream_transform.dart';

extension StreamExt<T> on Stream<T> {
  Future<void> complete() {
    return this.drain();
  }

  Stream<List<T>> chunked(int chunkSize) => asChunkedStream(chunkSize, this);

  Stream<E> mapAsyncLimited<E>(FutureOr<E> convert(T event),
      {int maxPending = 1}) {
    late StreamController<E> output;
    late StreamSubscription<T> input;

    /// Used to track when we've completed reading the source stream.
    var isClosing = false;

    /// The number of outstanding map operations
    var pending = 0;

    /// Run when the source stream is completed - ensures we're done processing
    /// all pending futures
    Future _checkClose() async {
      if (pending == 0) {
        await output.close();
      }
    }

    void onListen() {
      final add = output.add;

      final void Function(Object, [StackTrace]) addError = output.addError;
      input = this.listen(
          (T event) {
            FutureOr<E> newValue;
            try {
              newValue = convert(event);
            } catch (e, s) {
              output.addError(e, s);
              return;
            }
            if (newValue is Future<E>) {
              final isLimited = pending++ > maxPending;
              if (isLimited) {
                input.pause();
              }
              newValue.then(add, onError: addError).whenComplete(() async {
                pending--;
                if (isClosing) {
                  await _checkClose();
                } else if (input.isPaused && pending < maxPending) {
                  input.resume();
                }
              });
            } else if (newValue is E) {
              output.add(newValue);
            } else {
              output.addError(
                  Exception("Expected $E but found ${newValue?.runtimeType}"));
            }
          },
          cancelOnError: false,
          onError: addError,
          onDone: () {
            isClosing = true;
            _checkClose();
          });
    }

    if (this.isBroadcast) {
      output = StreamController<E>.broadcast(
          onListen: onListen,
          onCancel: () {
            input.cancel();
          },
          sync: true);
    } else {
      output = StreamController<E>(
          onListen: onListen,
          onPause: () {
            input.pause();
          },
          onResume: () {
            input.resume();
          },
          onCancel: () => input.cancel(),
          sync: true);
    }
    return output.stream;
  }
}

extension StreamIterableExtension<X> on Stream<Iterable<X>> {
  Stream<Iterable<X>> filterItems(bool predicate(X input)?) {
    if (predicate == null) return this;
    return this.map((items) => items.where(predicate));
  }

  /// Filters this stream using a result of another stream.  This allows us to apply the filter when either the
  /// filtering source changes or the original list changes.
  Stream<Iterable<X>> filteredBy<R>(
      Stream<R> other, bool filter(X item, R other)) {
    return this.combineLatest(other, (Iterable<X> items, R other) {
      return items.where((item) => filter(item, other));
    });
  }
}

extension FutureIterableStreamExtension<V> on Stream<Iterable<Future<V>>> {
  Stream<Future<Iterable<V>>> awaitEach() {
    return this.map((iterables) async {
      return await Future.wait(iterables, eagerError: true);
    });
  }
}

extension SafeStreamController<X> on StreamController<X> {
  void safeAdd(X item) {
    if (!this.isClosed) {
      this.add(item);
    }
  }
}
