import 'dart:async';

import 'package:stream_transform/stream_transform.dart';
import 'package:sunny_dart/sunny_dart.dart';
import 'package:sunny_dart/typedefs.dart';

extension StreamIterableExtension<X> on Stream<Iterable<X>> {
  Stream<Iterable<X>> filterItems(bool predicate(X input)) {
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

extension StreamToVStreamExtensions<X> on Stream<X> {
  ValueStream<X> toVStream([X initial]) => ValueStream.of(initial, this);

  SyncStream<X> toSyncStream([X initial, Consumer<X> onChange, String name]) =>
      SyncStream.fromStream(this, initial, onChange, name);
}
