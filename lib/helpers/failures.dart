T raise<T>(String message) => throw message ?? "Error raised";

T nullPointer<T>(String property) => throw ArgumentError.notNull(property ?? "Null found");

T todo<T>([String message]) => throw UnimplementedError(message);

T assertNotNull<T>(T value) => value ?? nullPointer("Expected not-null value of type ${T.toString()}, but got null");

T illegalState<T>([String message]) => throw Exception(message ?? "Illegal state");

T notImplemented<T>() => throw Exception("Not implemented");

class ErrorStack {
  final exception;
  final StackTrace stackTrace;

  const ErrorStack(this.exception, [this.stackTrace]);
}
