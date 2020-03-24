import 'dart:async';

import '../extensions.dart';
import 'safe_completer.dart';

abstract class Resolvable<T> {
  T resolveOrNull();
  bool get isResolved;
  Future<T> futureValue();
}

abstract class Tuple<A, B> extends Resolvable<Tuple<A, B>> {
  A get first;
  B get second;

  @override
  bool get isResolved;

  @override
  Tuple<A, B> resolveOrNull() => this;

  factory Tuple(A first, B second) {
    return _Tuple(first, second);
  }

  factory Tuple.ofFuture(FutureOr<A> first, FutureOr<B> second) {
    if (first is Future<A> || second is Future<B>) {
      return _FutureTuple(first, second);
    } else {
      return _Tuple(first.resolve(), second.resolve());
    }
  }
}

class _Tuple<A, B> implements Tuple<A, B> {
  @override
  final A first;
  @override
  final B second;

  _Tuple(this.first, this.second);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tuple && runtimeType == other.runtimeType && first == other.first && second == other.second;

  @override
  int get hashCode => first.hashCode ^ second.hashCode;

  @override
  String toString() => "first[$first]; second[$second]";

  @override
  bool get isResolved => true;

  @override
  Tuple<A, B> resolveOrNull() => this;

  @override
  // ignore: use_to_and_as_if_applicable
  Future<Tuple<A, B>> futureValue() => Future.value(this);
}

class _FutureTuple<A, B> implements Tuple<A, B> {
  final FutureOr<A> _first;
  final FutureOr<B> _second;

  A _firstResolved;
  B _secondResolved;

  final _completer = SafeCompleter<Tuple<A, B>>();

  _FutureTuple(this._first, this._second) {
    _resolve();
  }

  @override
  A get first => _firstResolved;
  @override
  B get second => _secondResolved;

  @override
  Tuple<A, B> resolveOrNull() => this;
  @override
  Future<Tuple<A, B>> futureValue() async => await _completer.future;

  @override
  bool get isResolved => _completer.isCompleted;

  Future _resolve() async {
    this._firstResolved = await _first;
    this._secondResolved = await _second;
    _completer.complete(this);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _FutureTuple &&
          runtimeType == other.runtimeType &&
          _first == other._first &&
          _second == other._second &&
          _firstResolved == other._firstResolved &&
          _secondResolved == other._secondResolved;

  @override
  int get hashCode => _first.hashCode ^ _second.hashCode ^ _firstResolved.hashCode ^ _secondResolved.hashCode;

  @override
  String toString() => "first[$_first]; second[$_second]";
}
