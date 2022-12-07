import 'package:collection/collection.dart' show IterableExtension;
import 'package:dartxx/dartxx.dart';

import '../helpers.dart';
import '../typedefs.dart';

extension DynamicMapExtensionMap<K> on Map<K, dynamic> {
  Iterable<MapEntry<K, dynamic>> flatEntry() {
    return entries.expand((entry) {
      final viter = [
        if (entry.value is Iterable) ...entry.value else if (entry.value != null) entry.value,
      ];
      return viter.map((v) => MapEntry<K, dynamic>(entry.key, v));
    });
  }
}

extension MapNullableExtensions<K, V> on Map<K, V>? {
  Map<K, V> orEmpty() {
    return this ?? {};
  }
}

extension MapExtensions<K, V> on Map<K, V> {
  String join([String entrySeparator = "; ", String keyValueSeparator = "="]) {
    return this.entries.map((e) => "${e.key}$keyValueSeparator${e.value}").join(entrySeparator);
  }

  Keyed<K, V> toKeyed() => Keyed(this);

  Map<K, V> filterEntries(bool predicate(K k, V v)) {
    return Map.fromEntries(entries.where((e) => predicate(e.key, e.value)));
  }

  /// see [filterEntries]
  Map<K, V> whereEntries(bool predicate(K k, V v)) {
    return Map.fromEntries(entries.where((e) => predicate(e.key, e.value)));
  }

  Map<K, V> whereValues(bool predicate(V v)) {
    return Map.fromEntries(entries.where((e) => predicate(e.value)));
  }

  Map<K, V> whereKeys(bool predicate(K v)) {
    return Map.fromEntries(entries.where((e) => predicate(e.key)));
  }

  void setByPath(JsonPath path, value) {
    Maps.setByPath(this, path, value);
  }

  dynamic getByPath(JsonPath path) {
    Maps.getByPath(this, path);
  }

  dynamic removeByPath(JsonPath path) {
    Maps.setByPath(this, path, null);
  }

  Map<KK, V> mapKeys<KK>(KK mapper(K k, V v)) {
    return this.map((k, v) => MapEntry(mapper(k, v), v));
  }

  Map<K, VV> mapValues<VV>(VV mapper(K k, V v)) {
    return this.map((k, v) => MapEntry(k, mapper(k, v)));
  }

  Iterable<VV> mapEntries<VV>(VV mapper(K k, V v)) {
    return this.entries.map((entry) => mapper(entry.key, entry.value));
  }

  String toDebugString() {
    return entries.map((e) {
      return "${e.key}=${e.value.toString().removeNewlines().truncate(40)}";
    }).join("; ");
  }
}

extension SunnyIterableExtensions<V> on Iterable<V>? {
  Iterable<V> ifEmpty(Getter<Iterable<V>> other) {
    if (this.isNullOrEmpty) {
      return other();
    } else {
      return this!;
    }
  }

  Iterable<V> whereNotNull() => this?.where(notNull()) ?? <V>[];

  Iterable<String> mapToString() => this?.map((_) => _?.toString()).whereType<String>() ?? <String>[];

  bool get isNullOrEmpty => this?.isNotEmpty != true;

  bool get isNotNullOrEmpty => this?.isNotEmpty == true;

  Map<K, List<V>> groupBy<K>(K keyOf(V value)) {
    final result = <K, List<V>>{};
    for (final item in this.orEmpty()) {
      result.putIfAbsent(keyOf(item), () => <V>[]).add(item);
    }
    return result;
  }

  Iterable<V> orEmpty() => this == null ? const [] : this!;

  Map<K, V> keyed<K>(K keyOf(V value)) => this?.map((v) => MapEntry<K, V>(keyOf(v), v)).toMap() ?? <K, V>{};

  Map<Type, List<V>> groupByType() {
    return groupBy((_) => _.runtimeType);
  }

  V? get firstOrNull => this?.firstWhereOrNull((_) => true);
}

extension IterableEntryExtensions<K, V> on Iterable<MapEntry<K, V>> {
  Iterable<MapEntry<K, V>> whereValuesNotNull() => this.where((entry) => entry.value != null);
}

class Keyed<K, V> {
  final Map<K, V> _boxed;

  const Keyed([this._boxed = const {}]);

  V? operator [](K key) {
    return _boxed[key];
  }
}
