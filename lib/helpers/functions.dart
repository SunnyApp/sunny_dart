import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:sunny_dart/typedefs.dart';

import '../platform/platform_interface.dart'
    if (dart.library.io) '../platform/platform_native.dart'
    if (dart.library.html) '../platform/platform_web.dart';

final _log = Logger("functions");

typedef Func<R> = R Function();

class Functions {
  Functions._();

  static T findResult<T>({List<Func<T>> checks, T exclude}) {
    for (var check in checks) {
      if (check == null) continue;
      final result = check();
      if (result != null && (exclude != null && result != exclude)) {
        return result;
      }
    }
    return null;
  }

  static WidgetBuilder ofStatic(Widget widget) => (context) => widget;
}

Factory<T> returnNull<T>() => () => null;

bool alwaysTrue<T>(T input) => true;

bool alwaysFalse<T>(T input) => false;

T create<T>(Factory<T> factory) => (factory ?? returnNull())();

Future delay([Duration duration = const Duration(milliseconds: 300)]) async {
  await Future.delayed(duration);
}

Mapping<I, O> catching<I, O>(O execute(I input), {String debugLabel, Logger logger}) {
  return (I input) {
    try {
      final result = execute(input);
      if (result is Future) {
        result.catchError((e, StackTrace stack) {
          (logger ?? _log).severe((debugLabel ?? "Error catching") + ": $e", e, stack);
        });
      }
      return result;
    } catch (e, stack) {
      (logger ?? _log).severe((debugLabel ?? "Error catching") + ": $e", e, stack);
      return null;
    }
  };
}

//typedef SetState = void Function(VoidCallback callback);

R timed<R>(R block(), {dynamic result(R result, Duration time)}) {
  result ??= (R result, Duration time) {};

  final start = DateTime.now();
  R r = block();
  final duration = DateTime.now().difference(start);
  final handled = result(r, duration);
  return handled is R ? handled : r;
}

Future<R> timedAsync<R>(FutureOr<R> block(), {dynamic result(R result, Duration time)}) async {
  result ??= (R result, Duration time) {
    print("Duration: $time");
  };

  final start = DateTime.now();
  R r = await block();
  final duration = DateTime.now().difference(start);
  final handled = result(r, duration);
  return handled is R ? handled : r;
}

bool get isIOS => isPlatformIOS;

bool get isAndroid => isPlatformAndroid;

bool get isMacOS => isPlatformMacOS;

bool get isWindows => isPlatformWindows;

bool get isLinux => isPlatformLinux;

bool get isWeb => isPlatformWeb;

String get operatingSystem => platformName;

Map<String, String> get environment => platformEnvironment;

bool get canReadFiles => canPlatformReadFiles;
