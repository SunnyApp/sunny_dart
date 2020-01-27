import 'package:logging/logging.dart';
import 'package:recase/recase.dart';
import 'package:sunny_dart/sunny_dart.dart';

mixin LoggingMixin {
  String get loggerName => runtimeType.name;

  Logger get log => Logger(loggerName);

  R logged<R>(R block(), {String debugLabel, bool propagate = false}) {
    try {
      final R r = block();
      if (r is Future) {
        r.catchError((e, StackTrace stack) {
          log.severe("[${debugLabel ?? 'operation'}] async: $e", e, stack);
        });
      }
      return r;
    } catch (e, stack) {
      log.severe("[${debugLabel ?? 'operation'}] $e", e, stack);
      if (propagate == true) {
        rethrow;
      } else {
        return null;
      }
    }
  }
}

/// Produces a logger using snake case naming conventions.  If [subscript] is provided, it will be
/// appended to the name in square brackets, eg
/// sunny_list[contact]
Logger sunnyLogger(Type type, {Type subscript}) {
  String typeName = loggerNameOf(type);
  if (subscript != null) typeName += "[${loggerNameOf(subscript)}]";
  return Logger(typeName);
}

/// Converts a type name to snake case
String loggerNameOf(Type type) {
  return ReCase("$type").camelCase;
}
