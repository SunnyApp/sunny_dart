import 'dart:async';

import 'package:logging/logging.dart';

import '../extensions/future_extensions.dart';
import '../extensions/lang_extensions.dart';
import '../extensions/map_extensions.dart';
import '../helpers.dart';
import '../helpers/resolvable.dart';
import '../typedefs.dart';
import 'value_stream.dart';

extension StreamToVStreamExtensions<X> on Stream<X> {
  ValueStream<X> toVStream([X? initial]) => ValueStream.of(initial, this);

  SyncStream<X> toSyncStream([X? initial, Consumer<X>? onChange, String? name]) =>
      SyncStream.fromStream(this, initial, onChange, name);
}

extension ValueStreamIterableMapEntryExtensions<K, V> on ValueStream<Iterable<MapEntry<K, V>>> {
  ValueStream<Map<K, V>> toMap() {
    return this.map((entries) => Map.fromEntries(entries));
  }
}

extension ValueStreamOfMapExtensions<K, V> on ValueStream<Map<K, V>> {
  ValueStream<Map<K, R>> mapEntries<R>(MapEntry<K, R> mapper(K key, V value)) {
    return this.map((self) => self.map(mapper));
  }

  ValueStream<Map<K, R>> mapValues<R>(R mapper(K key, V value)) {
    return this.map((self) => self.map((k, v) => MapEntry(k, mapper(k, v))));
  }

  ValueStream<Map<K, V>> filterEntries(bool predicate(K key, V value)) {
    return this.map((self) => self.filterEntries(predicate));
  }

  ValueStream<Iterable<V>> get values => this.map((map) => map.values);

  ValueStream<Iterable<K>> get keys => this.map((map) => map.keys);
}

final _log = Logger("valueStream");

extension ValueStreamExtensions<T> on ValueStream<T> {
  ValueStream<T> debounced([Duration? duration]) => ValueStream.of(get(), after.debounce(duration ?? 300.ms));

  Stream<T?> flatten([T? initialValue, bool filterNotNull = true]) {
    final initial = get();

    Stream<T?> base = (initial is Future<T?>)
        ? Stream.fromIterable([initialValue]).merge(Stream.fromFuture(initial))
        : Stream.fromIterable([initial]);

    return filterNotNull
        ? base.followedBy(after).where((_) {
            if (_ == null) {
              _log.fine("Not sending null value for $T stream");
              return true;
            }
            return true;
          })
        : base.followedBy(after);
  }

  /// Combines another stream.
  ValueStream<R> combined<R, O>(ValueStream<O> other, R combiner(T? self, O? other)) {
    final startCombined = this.get().thenOrNull((first) {
      return other.get().thenOrNull((otherFirst) {
        return combiner(first, otherFirst);
      });
    });

    final _self = get().futureValue().asStream().combine(after);
    final Stream<O> _other = other.get().futureValue().asStream().whereType<O>().combine(other.after);

    /// THe combine transformation requires both stream to publish at least once, so we'll force the current value
    /// to be republished.
    return ValueStream<R>.of(startCombined.unbox(), _self.combineLatest(_other, combiner));
  }

  /// Combines another stream, passing unresolved Futures
  ValueStream<R?> combinedUnresolved<R, O>(ValueStream<O> other, Resolvable<R?> combiner(FutureOr<T?> self, FutureOr<O?> other)) {
    final Resolvable<R?> startCombined = combiner(this.get(), other.get());
    final Stream<R?> startingStream = startCombined.isResolved ? Stream.empty() : startCombined.futureValue().asStream();
    final afterTxr = this.after.combineLatest(other.after, (T t, O o) {
      final resolved = combiner(t, o);
      return resolved.resolveOrNull();
    });
    return ValueStream<R?>.of(startCombined.resolveOrNull(), startingStream.combine(afterTxr));
  }

  // ValueStream<Tuple<T, O>> tuple<O>(ValueStream<O> other,
  //     {bool waitForBoth = true}) {
  //   final ValueStream<Tuple<T, O>> stream =
  //       combinedUnresolved(other, (FutureOr<T?> self, FutureOr<O?> other) {
  //     return Tuple.ofFuture<T?, O?>(self, other);
  //   });
  //   return waitForBoth != true
  //       ? stream
  //       : stream.where((tuple) {
  //           return tuple.isResolved;
  //         });
  // }

  ValueStream<T> peek(void peek(T item)) {
    return this.map((input) {
      peek(input);
      return input;
    });
  }

  StreamSubscription listen(void onData(T item)) {
    return after.listen(onData, cancelOnError: false, onError: (_) {
      print("Error: $_");
    });
  }

  /// Filters the entire stream, including the current element
  ValueStream<T> where(Predicate<T?> predicate) {
    final first = this.get().thenOrNull((T? resolved) {
          return predicate(resolved) == true ? resolved : null;
        } as T Function(T?));
    return ValueStream.of(first, this.after.where(predicate));
  }

  ValueStream<T> whereNotNull() => ValueStream.of(get(), after.where(notNull()));

  SyncStream<T> toSyncStream([void onChange(T value)?, String? name]) => SyncStream.fromVStream(this, onChange, name);
}

extension StreamNullableExt<X> on Stream<X?> {
  Stream<X> expectNotNull() {
    return this.map((nullable) => nullable!);
  }
}

extension ValueStreamFutureExtensions<X> on ValueStream<Future<X>> {
  ValueStream<Future<R>> thenMap<R>(R mapper(X input)) {
    return this.map((item) {
      return item.then(mapper);
    });
  }

  ValueStream<X?> sampled() {
    return FStream<X>.ofFuture(get() as Future<X>, after.asyncMapSample((future) => future));
  }
}

extension ValueStreamIterableFutureExtensions<X> on ValueStream<Iterable<Future<X>>> {
  ValueStream<Iterable<Future<R>>> thenMapEach<R>(R mapper(X input)) {
    return this.mapEach((future) => future.then(mapper));
  }

  ValueStream<Future<Iterable<X>>> awaitEach() {
    return this.map((iterables) {
      return Future.wait(iterables, eagerError: true);
    });
  }
}

extension ValueStreamIterableExtensions<X> on ValueStream<Iterable<X>> {
  ValueStream<Iterable<X>> filterItems(bool predicate(X input)?) {
    if (predicate == null) return this;
    return this.map((items) => items.where(predicate));
  }

  bool get isNotEmpty => this.resolve([])?.isNotEmpty == true;

  int get length => resolve([])?.length ?? 0;

  ValueStream<Iterable<R>> expandEach<R>(Iterable<R> expander(X input)) {
    return this.map((items) => items.expand(expander));
  }

  /// Filters this stream using a result of another stream.  This allows us to apply the filter when either the
  /// filtering source changes or the original list changes.
  ValueStream<Iterable<X>> filteredBy<R>(ValueStream<R> other, bool filter(X item, R? other)) {
    final FutureOr<Iterable<X>?> first = get();
    final FutureOr<R?> otherFirst = other.get();

    /// When combining, we need to ensure at least one emission.
    final withOtherFirst = Future.value(otherFirst).asStream().whereType<R>().followedBy(other.after);
    final afterTransform = after.combineLatest(withOtherFirst, (items, R filters) {
      return items.where((item) => filter(item, filters));
    });

    if (first is Future || otherFirst is Future) {
      final firstFuture = Future.value(first).then((_first) {
        return Future.value(otherFirst).then((_otherFirst) {
          return _first?.where((item) => filter(item, _otherFirst));
        });
      });
      final afterCombined = firstFuture.asStream().expectNotNull().followedBy(afterTransform);
      return ValueStream.of(firstFuture, afterCombined);
    } else {
      final _first = first as Iterable<X>;
      final _otherFirst = otherFirst;
      return HStream(_first.where((item) => filter(item, _otherFirst!)), afterTransform);
    }
  }

  ValueStream<Iterable<R>> mapEach<R>(R mapper(X input)) {
    return this.map((items) => items.orEmpty().map(mapper as R Function(X?)));
  }

  ValueStream<Iterable<X>> followedBy(ValueStream<Iterable<X>> other) {
    final first = [
      ...this.resolve([])!,
      ...other.resolve([])!,
    ];
    return ValueStream<Iterable<X>>.of(first, this.after.followedBy(other.after));
  }

  ValueStream<Iterable<X>> combineWith(Iterable<ValueStream<Iterable<X>>> others, [String? debugName]) {
    /// Ensures that the ValueStream emits
    // ignore: avoid_shadowing_type_parameters
    Stream<X> flatten<X>(ValueStream<X> input) {
      return Stream.fromFuture(Future.value(input.get())).expectNotNull().merge(input.after);
    }

    Stream<Iterable<X>> stream = flatten(this).combineLatestAll(others.map((o) => flatten(o))).map((all) {
      return [
        ...all.expand((_) => _),
      ];
    });

    return ValueStream<Iterable<X>>.of([], stream, this.debugName);
  }
}
