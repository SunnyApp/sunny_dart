import 'dart:collection';

import 'package:logging/logging.dart';

import '../typedefs.dart';
import 'functions.dart';

final _log = Logger("Lists");

class Lists {
  Lists._();

  static List<T> listOf<T>(T item) => item == null ? [] : [item];

  static List<T> combine<T>(T item, Iterable<T>? more) {
    final list = [item];
    if (more != null) list.addAll(more);
    return List.unmodifiable(compact(list));
  }

  static List<T> expand<T>(Iterable<T>? some, Iterable<T>? more) {
    final list = [];
    if (some != null) list.addAll(some);
    if (more != null) list.addAll(more);
    return List.unmodifiable(compact(list));
  }

  static List<T> append<T>(Iterable<T>? some, T item) {
    final list = [];
    if (some != null) list.addAll(some);
    if (item != null) list.add(item);
    return List.unmodifiable(compact(list));
  }

  static T? getOrNull<T>(Iterable<T>? items, int index) {
    if (items == null) return null;
    final List<T> list = (items is! List<T>) ? items = [...items] : [...items];
    if (list.length > index) {
      return list[index];
    } else {
      return null;
    }
  }

  static List<T> listIf<T>(bool condition, ListFactory<T> factory) =>
      condition ? factory() : [];

  static T? createIf<T>(bool condition, Factory<T> factory) =>
      condition ? factory() : null;

  static List<T> compact<T>(Iterable<T>? list) =>
      list?.where((item) => item != null).toList() ?? <T>[];

  static List<String> compactEmpty(Iterable<String?>? list) =>
      [...?list?.whereType<String>().where((item) => item.isNotEmpty)];

  static T? firstOrNull<T>(Iterable<T>? list, {bool filter(T input)?}) {
    if (filter != null) {
      list = list?.where(filter);
    }
    return list?.isNotEmpty == true ? list?.first : null;
  }

  static Iterable<T> without<T>(List<T>? list, T? removed) =>
      (removed == null ? list : list?.where((item) => item != removed)) ?? [];

  static T? lastOrNull<T>(Iterable<T?> names, {bool filter(T? input)?}) {
    return names.lastWhere(filter ?? matchAll(), orElse: returnNull());
  }

  static T? singleOrNull<T>(Iterable<T>? items) {
    if (items?.length != 1) return null;
    return items?.first;
  }
}

const List emptyList = [];

List<T> compact<T>(Iterable<T?>? list) =>
    list?.whereType<T>().toList() ?? <T>[];

T? createIf<T>(bool condition, Factory<T> factory) =>
    condition ? factory() : null;

List<T> chopList<T>(Iterable<T> items) {
  final list = [...items];
  if (list.isEmpty) return list;

  return list.sublist(0, list.length - 1);
}

Iterable<T> distinctBy<T>(Iterable<T>? list, dynamic by(T input)) {
  if (list == null) {
    return [];
  }
  final keys = <dynamic>{};
  return list.where((item) {
    final key = by(item);
    if (!keys.contains(key)) {
      keys.add(key);
      return true;
    } else {
      return false;
    }
  }).toList();
}

List<T> mapExceptLast<T>(Iterable<T>? list, T map(T t)) {
  final items = list?.toList(growable: false) ?? [];
  for (var i = 0; i < items.length; ++i) {
    if (i < list!.length - 1) {
      items[i] = map(items[i]);
    }
  }
  return items;
}

Map<K, V> mapOf<K, V>(Iterable<V> values, { required K Function(V item) keyOf }) {
  return Map.fromEntries(values.map((v) => MapEntry(keyOf(v), v)));
}

Map<K, List<V>> groupBy<K, V>(List<V> values, K mappedBy(V item)) {
  final result = <K, List<V>>{};
  values.forEach((v) {
    final key = mappedBy(v);
    if (!result.containsKey(key)) {
      result[key] = <V>[];
    }
    result[key]!.add(v);
  });
  return result;
}

Comparator<T> compareBool<T>(bool toBool(T input)) {
  return (T a, T b) {
    bool ba = toBool(a);
    bool bb = toBool(b);
    if (ba == bb) return 0;
    return ba ? 1 : -1;
  };
}

Iterable<T> sort<T>(Iterable<T> list, Comparator<T> comparator) {
  final copy = [...list];
  copy.sort(comparator);
  return copy;
}

List<T> mapExceptFirst<T>(Iterable<T>? list, T map(T t)) {
  final items = list?.toList(growable: false) ?? [];
  for (var i = 0; i < items.length; ++i) {
    if (i > 0) {
      items[i] = map(items[i]);
    }
  }
  return items;
}

T? firstNonNull<T>([T? a, T? b, T? c, T? d, T? e, T? f]) {
  return a ?? b ?? c ?? d ?? e ?? f;
}

Predicate<T?> notNull<T>() {
  return (T? x) => x != null;
}

Predicate<String?> notNullOrBlank() {
  return (x) => x?.isNotEmpty == true;
}

typedef Predicate<T> = bool Function(T input);

T? convert<F, T>(F obj,
    {Transformer<F, T>? converter, Predicate<F>? predicate}) {
  final _predicate = predicate ?? (i) => i != null;
  return _predicate(obj) ? converter!(obj) : null;
}

Iterable<R> mapIndexed<R, T>(Iterable<T> input, R mapper(T item, int index)) {
  int i = 0;
  return input.map((item) => mapper(item, i++));
}

List<T?> ifEmpty<T>(Iterable<T>? list, {T? then}) => [
      ...?list,
      if (list?.isNotEmpty != true) then,
    ];

T? find<T>(Map<String, T> container, String? id) {
  if (id == null) return null;
  final item = container[id];
  if (item == null) {
    final current = StackTrace.current
        .toString()
        .split("\n")
        .take(5)
        .map((frame) => "\t$frame")
        .join("\n");
    _log.warning("WARN: Item with id $id not found: $current");
  }
  return item;
}

Map<K, V> filterKeys<K, V>(Map<K, V> source, bool filter(K key)) =>
    source.entries
        .where((e) => filter(e.key))
        .toList()
        .asMap()
        .map((_, e) => e);

Map<K, V> filterValues<K, V>(Map<K, V> source, bool filter(V value)) =>
    source.entries
        .where((e) => filter(e.value))
        .toList()
        .asMap()
        .map((_, e) => e);

T badArgument<T>({value, String? name, String? message}) =>
    throw ArgumentError.value(value, name, message);

T wrongType<T>(String name, value, List<Type> accepted) =>
    throw ArgumentError.value(value, name,
        "Wrong type (${value?.runtimeType}) - expected one of $accepted");

List<T> removeElement<T>(Iterable<T>? elements, T toRemove) =>
    elements?.where((item) => item != toRemove).toList() ?? [];

Predicate<T> matchAll<T>() {
  return (x) => true;
}

/// Converts a dynamic json value into a list, using the provided transformer to convert
List<T> toList<T>(dynamic value, DynTransformer<T> txr) {
  if (value is Iterable) {
    return value.map((item) => txr(item)).toList();
  } else {
    throw ArgumentError("Expected list value");
  }
}

/// Converts a dynamic json value into a map, using the provided transformer to convert
Map<String, T> toMap<T>(value, DynTransformer<T> txr) {
  if (value is Map) {
    return value.map((key, item) {
      return MapEntry("$key", txr(item));
    });
  } else {
    throw ArgumentError("Expected map value");
  }
}

abstract class ListDelegateMixin<T> extends ListMixin<T> {
  List<T> get delegate;

  @override
  Iterator<T> get iterator => delegate.iterator;

  @override
  int get length => delegate.length;

  @override
  set length(int length) => delegate.length = length;

  @override
  T operator [](int index) {
    return delegate[index];
  }

  @override
  void operator []=(int index, T value) {
    delegate[index] = value;
  }
}
