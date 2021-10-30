import 'package:dartxx/dartxx.dart';
import 'package:logging/logging.dart';
import 'package:recase/recase.dart';

mixin LoggingMixin {
  String get loggerName => runtimeType.name;
  Logger get log => Logger(loggerName);
}

/// Produces a logger using snake case naming conventions.  If [subscript] is provided, it will be
/// appended to the name in square brackets, eg
/// sunny_list[contact]
Logger sunnyLogger(Type type, {Type? subscript}) {
  var typeName = loggerNameOf(type);
  if (subscript != null) typeName += "[${loggerNameOf(subscript)}]";
  return Logger(typeName);
}

/// Converts a type name to snake case
String loggerNameOf(Type type) {
  return ReCase("$type").camelCase;
}
