import 'dart:async';

import 'package:dartxx/tuple.dart';

import 'safe_completer.dart';

abstract class Resolvable<T> {
  T? resolveOrNull();

  bool get isResolved;

  Future<T> futureValue();
}

class FutureTuple<A, B> implements Resolvable<Tuple<A, B>> {
  final FutureOr<A>? _first;
  final FutureOr<B> _second;

  A? _firstResolved;
  B? _secondResolved;

  final SafeCompleter<Tuple<A, B>> _completer = SafeCompleter<Tuple<A, B>>();

  FutureTuple(this._first, this._second) {
    _resolve();
  }

  A get first => _firstResolved as A;

  B get second => _secondResolved as B;

  @override
  Tuple<A, B>? resolveOrNull() => isResolved ? Tuple(first, second) : null;

  @override
  Future<Tuple<A, B>> futureValue() async => await _completer.future;

  @override
  bool get isResolved => _completer.isCompleted;

  Future _resolve() async {
    this._firstResolved = await _first;
    this._secondResolved = await _second;
    _completer.complete(Tuple(first, second));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FutureTuple &&
          _first == other._first &&
          _second == other._second &&
          _firstResolved == other._firstResolved &&
          _secondResolved == other._secondResolved) ||
      (other is Tuple && other.first == first && other.second == second);

  @override
  int get hashCode =>
      _first.hashCode ^
      _second.hashCode ^
      _firstResolved.hashCode ^
      _secondResolved.hashCode;

  @override
  String toString() => "first[$_first]; second[$_second]";
}
