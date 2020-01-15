import 'package:sunny_dart/json/json_path.dart';

import '../helpers.dart';
import 'lang_extensions.dart';

extension MapExtensions<K, V> on Map<K, V> {
  String join([String entrySeparator = "; ", String keyValueSeparator = "="]) {
    return this
        .entries
        .map((e) => "${e.key}$keyValueSeparator${e.value}")
        .join(entrySeparator);
  }

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

  Map<K, V> whereKeysNotNull() {
    return entries.where((entry) => entry.key != null).toMap();
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

extension IterableExtensions<V> on Iterable<V> {
  Iterable<V> whereNotNull() => this?.where(notNull()) ?? <V>[];

  Iterable<String> mapToString() =>
      this?.map((_) => _?.toString()) ?? <String>[];

  bool get isNullOrEmpty => this?.isNotEmpty != true;
  bool get isNotNullOrEmpty => this?.isNotEmpty == true;

  Map<K, List<V>> groupBy<K>(K keyOf(V value)) {
    final result = <K, List<V>>{};
    for (final item in this) {
      result.putIfAbsent(keyOf(item), () => <V>[]).add(item);
    }
    return result;
  }

  Map<K, V> keyed<K>(K keyOf(V value)) =>
      this?.map((v) => MapEntry<K, V>(keyOf(v), v))?.toMap() ?? <K, V>{};

  Map<Type, List<V>> groupByType() {
    return groupBy((_) => _.runtimeType);
  }

  V get firstOrNull => this.firstWhere((_) => true, orElse: () => null);
}

extension IterableEntryExtensions<K, V> on Iterable<MapEntry<K, V>> {
  Map<K, List<V>> groupByKey() {
    Map<K, List<V>> results = {};
    this.forEach((e) {
      results.putIfAbsent(e.key, () => <V>[]).add(e.value);
    });
    return results;
  }

  Map<K, V> toMap() => Map.fromEntries(this);
  Iterable<MapEntry<K, V>> whereValuesNotNull() =>
      this.where((entry) => entry.value != null);
}
