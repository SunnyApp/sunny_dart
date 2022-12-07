import 'dart:async';

import 'package:logging/logging.dart';

import '../extensions/future_extensions.dart';
import '../extensions/lang_extensions.dart';
import '../helpers.dart';
import '../typedefs.dart';

/// Interface representing a stream that has a current or initial value as well.
///
/// See [HStream], which provides the initial value at the start of the stream, and
/// [SyncStream], which keeps the value up-to-date
abstract class ValueStream<T> {
  String? get debugName;

  FutureOr<T?> get();

  T? resolve([T? ifAbsent]);

  bool get isFirstResolved;

  Stream<T> get after;

  Future<T?> get future;

  /// Basics of converting something over
  ValueStream<R> map<R>(R mapper(T input));

  factory ValueStream.of(FutureOr<T?> first, [Stream<T>? after, String? debugName]) {
    after ??= Stream.empty();
    if (first is Future<T?>) {
      return FStream<T>.ofFuture(first, after, debugName);
    } else {
      return HStream<T>(first.resolveOrNull(), after, debugName);
    }
  }

  factory ValueStream.empty() {
    return HStream<T>.static(null);
  }

  static ValueStreamController<X> controller<X>(String debugLabel, {X? initialValue, bool isUnique = true}) {
    return ValueStreamController(debugLabel, initialValue: initialValue, isUnique: isUnique);
  }

  static ValueStream<X> singleValue<X>({String? debugLabel, FutureOr<X>? initialValue}) {
    return ValueStream.of(initialValue);
  }
}

class HStream<T> implements ValueStream<T> {
  final T? first;
  @override
  final Stream<T> after;
  @override
  final String? debugName;

  @override
  Future<T> get future => Future.value(first);

  HStream(this.first, this.after, [this.debugName]);

  HStream.static(this.first, [this.debugName]) : after = Stream.empty();

  @override
  bool get isFirstResolved => true;

  @override
  HStream<R> map<R>(R mapper(T input)) {
    return HStream<R>(first?.let(mapper), after.map(mapper));
  }

  @override
  T? resolve([T? ifAbsent]) => first;

  @override
  T? get() => first;

  HStream<Iterable<R>> expandFrom<R, O>(HStream<O> other, Iterable<R> expander(T? input, O? other)) {
    return HStream<Iterable<R>>(
        expander(this.first, other.first),
        after.combineLatest(other.after, (ours, O theirs) {
          return expander(ours, theirs);
        }));
  }

  HStream<Iterable<R>> expand<R>(Iterable<R> expander(T? input)) {
    return HStream<Iterable<R>>(expander(first), after.map((T item) => expander(item)));
  }

  StreamSubscription listen(void onEach(T each), {bool cancelOnError = false}) {
    return after.listen(onEach, cancelOnError: cancelOnError);
  }
}

Stream<T> streamOfNullableFuture<T>(Future<T?>? nullable) {
  return nullable == null ? Stream.empty() : Stream.fromFuture(nullable).whereType<T>();
}

/// A value stream based where the first element is a future
class FStream<T> implements ValueStream<T> {
  T? _first;
  @override
  final String? debugName;
  final Future<T?> _firstFuture;
  bool _isResolved = false;
  @override
  final Stream<T> after;

  @override
  Future<T?> get future => _isResolved ? Future.value(_first) : _firstFuture.then((value) => value!);

  /// The constructor resolves the first item and then passes it in the [after] stream, while
  /// also setting it as [_first]
  FStream.ofFuture(this._firstFuture, Stream<T> after, [this.debugName])
      : after = streamOfNullableFuture<T>(_firstFuture).followedBy(after) {
    _firstFuture.then((resolved) {
      _isResolved = true;
      _first = resolved;
    });
  }

  FStream(T first, this.after, [this.debugName])
      : _first = first,
        _firstFuture = Future.value(null),
        _isResolved = true;

  @override
  bool get isFirstResolved => _isResolved;

  T? get first => isFirstResolved ? _first : nullPointer("Initial value not resolved.  Use future");

  @override
  ValueStream<R> map<R>(R mapper(T input)) {
    return (_isResolved
        ? HStream<R>(mapper(first!), after.map(mapper))
        : FStream<R>.ofFuture(_firstFuture.then((value) => value == null ? null : mapper(value)), after.map(mapper)));
  }

  @override
  T? resolve([T? ifAbsent]) => _isResolved ? _first : ifAbsent;

  @override
  FutureOr<T?> get() => (_isResolved ? _first : _firstFuture) as FutureOr<T?>;
}

/// The SyncStream is used to control (and potentially debounce) updates to a single value, that are then dispatched
/// as a single stream of updates
class SyncStream<T> with Disposable implements ValueStream<T?> {
  SyncStream._({final FutureOr<T?>? current, this.debugName, this.onChange, Stream<T>? source})
      : _after = StreamController.broadcast() {
    if (current is Future<T?>) {
      source ??= Stream.empty();
      source = Stream.fromFuture(current).whereType<T>().merge(source);
    } else if (current != null) {
      /// We don't want to notify on initial values if they aren't a future.
      this._resolved = true;
      this._current = current;
    }

    if (source != null) {
      registerDisposer(source.listen((_) {
        try {
          update(_);
        } catch (e, stack) {
          log.info("Error with $debugName");
          log.info(e);
          log.info(stack);
        }
      }, cancelOnError: false).cancel);
    }
    registerDisposer(_after.close);
  }

  /// This stream doesn't subscribe to an upstream branch for updates, but can still be updated.
  SyncStream.controller({FutureOr<T>? initialValue, required String debugName, Consumer<T>? onChange})
      : this._(current: initialValue, debugName: debugName, onChange: onChange);

  SyncStream.empty() : this._(debugName: "empty");

  SyncStream.fromVStream(ValueStream<T> source, [Consumer<T>? onChange, String? debugName])
      : this._(debugName: debugName, onChange: onChange, current: source.get(), source: source.after);

  SyncStream.fromStream(Stream<T> after, [T? current, Consumer<T>? onChange, String? debugName])
      : this._(current: current, onChange: onChange, debugName: debugName, source: after);

  T? _current;
  @override
  final String? debugName;
  final StreamController<T?> _after;
  final log = Logger("syncStream.$T");

  @override
  Stream<T?> get after => _after.stream;
  final Consumer<T>? onChange;
  bool _resolved = false;

  String? get loggerName => debugName;

  T? get current => _current;

  set current(T? current) {
    update(current);
  }

  /// Like [StreamController.add]
  void update(T? current) {
    _current = current;
    _resolved = true;
    _after.add(current);
    if (current != null) {
      onChange?.call(current);
    }
  }

  ValueStream<T?> toVStream() {
    return HStream(current, after);
  }

  @override
  Future<T?> get future => current != null ? Future.value(current) : after.first;

  @override
  T? resolve([T? ifAbsent]) => current ?? ifAbsent;

  @override
  FutureOr<T>? get() => current;

  @override
  ValueStream<R> map<R>(R mapper(T? input)) {
    return HStream(mapper(current), after.map(mapper));
  }

  @override
  bool get isFirstResolved => _resolved;

  /// Forwards a stream to this one
  void forward(Stream<T> from) {
    registerDisposer(from.listen((data) {
      this.update(data);
    }, cancelOnError: false).cancel);
  }

  void reset() {
    _resolved = false;
    _current = null;
  }

  Future dispose() async => await disposeAll();
}

class HeadedEntryStream<K, V> {
  final Iterable<MapEntry<K, V>>? first;
  final Stream<Iterable<MapEntry<K, V>>> after;

  HeadedEntryStream(this.first, this.after);

  HeadedEntryStream.ofStream(HStream<Iterable<MapEntry<K, V>>> input)
      : first = input.first,
        after = input.after;
}

/// A class that tracks a single value as a stream, but can also provide the latest value;
class ValueStreamController<T> {
  T? _currentValue;
  final bool isUnique;
  final String debugLabel;
  bool _isClosing = false;
  late StreamController<T?> _controller;

  ValueStreamController(this.debugLabel, {T? initialValue, this.isUnique = true}) {
    _controller = StreamController.broadcast();
    if (initialValue != null) {
      add(initialValue);
    }
  }

  T? get currentValue => _currentValue;

  set currentValue(T? newValue) {
    add(newValue);
  }

  void add(T? newValue) {
    this._currentValue = newValue;
    if (!_isClosing) {
      _controller.add(newValue);
    }
  }

  ValueStream<T?> get stream => ValueStream.of(currentValue, _controller.stream);

  Future dispose() {
    return this.close();
  }

  Future close() {
    _isClosing = true;
    return _controller.close();
  }
}

class FuturesStream {
  final List<FutureOr> futures;
  final StreamController<List> _stream = StreamController.broadcast();
  final List _result;
  int _resolved = 0;

  FuturesStream(this.futures) : _result = List.filled(futures.length, null) {
    for (var i = 0; i < futures.length; ++i) {
      var f = futures[i];
      f.thenOr((r) {
        _result[i] = r;
        _resolved += 1;
        _stream.add([..._result]);
        if (_resolved == futures.length) {
          _stream.close();
        }
      });
    }
  }

  List get result => [..._result];

  Stream<List> get stream {
    return _stream.stream;
  }

  void close() {
    if (!_stream.isClosed) {
      _stream.close();
    }
  }
}
