abstract class MLiteral<T> {
  final T value;

  const MLiteral(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MLiteral && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() {
    return value.toString();
  }

  bool get isKnown => true;

  dynamic get diffSource => value;

  String get diffKey => value.toString();

  int get equalityHashCode => diffSource.hashCode;

  int get diffHashCode => diffKey.hashCode;
}
