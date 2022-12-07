import 'dart:async';

import 'package:logging/logging.dart';
import 'package:sunny_dart/typedefs.dart';

final _log = Logger("functions");

typedef Func<R> = R Function();

class Functions {
  Functions._();

  static T? findResult<T>({required List<Func<T>?> checks, T? exclude}) {
    for (var check in checks) {
      if (check == null) continue;
      final result = check();
      if (result != null && (exclude != null && result != exclude)) {
        return result;
      }
    }
    return null;
  }
}

Factory<T?> returnNull<T>() => () => null;

bool alwaysTrue<T>(T input) => true;

bool alwaysFalse<T>(T input) => false;

T? create<T>(Factory<T>? factory) => factory?.call();

Future delay([Duration duration = const Duration(milliseconds: 300)]) async {
  await Future.delayed(duration);
}

Mapping<I, O?> catching<I, O>(O execute(I input),
    {String? debugLabel, Logger? logger}) {
  return (I input) {
    try {
      final result = execute(input);
      if (result is Future) {
        result.catchError((e, StackTrace stack) {
          (logger ?? _log)
              .severe((debugLabel ?? "Error catching") + ": $e", e, stack);
        });
      }
      return result;
    } catch (e, stack) {
      (logger ?? _log)
          .severe((debugLabel ?? "Error catching") + ": $e", e, stack);
      return null;
    }
  };
}

O trying<O>(O execute(), {Logger? log}) {
  try {
    return execute();
  } catch (e, stack) {
    print(e);
    print(stack);
    rethrow;
  }
}

//typedef SetState = void Function(VoidCallback callback);

R timed<R>(R block(), {dynamic result(R result, Duration time)?}) {
  result ??= (R result, Duration time) {};

  final start = DateTime.now();
  R r = block();
  final duration = DateTime.now().difference(start);
  final handled = result(r, duration);
  return handled is R ? handled : r;
}

Future<R> timedAsync<R>(FutureOr<R> block(),
    {dynamic result(R result, Duration time)?}) async {
  result ??= (R result, Duration time) {
    print("Duration: $time");
  };

  final start = DateTime.now();
  R r = await block();
  final duration = DateTime.now().difference(start);
  final handled = result(r, duration);
  return handled is R ? handled : r;
}

void ignoreVoid<T>(T input) {}

T nullPointer<T>(String? property) =>
    throw ArgumentError.notNull(property ?? "Null found");

T todo<T>([String? message]) => throw UnimplementedError(message);

T assertNotNull<T>(T value) =>
    value ??
    nullPointer(
        "Expected not-null value of type ${T.toString()}, but got null");

T illegalState<T>([String? message]) =>
    throw Exception(message ?? "Illegal state");

T illegalArg<T>(String prop, [String? message]) => throw Exception(
    message ?? "Illegal argument $prop: ${message ?? 'No message'}");

T notImplemented<T>() => throw Exception("Not implemented");
