//ignore_for_file: unnecessary_cast
import 'dart:async';
import 'dart:math';

import 'package:chunked_stream/chunked_stream.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:dartxx/dartxx.dart';
import 'package:flexidate/flexidate.dart';
import 'package:logging/logging.dart';

import '../helpers.dart';

export 'package:dartxx/dartxx.dart';

final _random = Random();

extension ObjectAsListExtension on Object? {
  List asIterable() {
    final self = this;
    if (self is Iterable) {
      return [...self];
    } else {
      return [if (this != null) this];
    }
  }
}

extension ObjectToListExtension<T> on T {
  List<T> asList() {
    if (this == null) return [];
    return [if (this != null) this];
  }

  int? toInt() {
    final self = this;
    if (self == null) return null;
    if (self is int) return self;
    if (self is num) return self.toInt();
    assert(false, "Can't convert to int");
    return null;
  }
}

extension ObjectExtension on dynamic {
  int? toInteger() {
    final self = this;
    if (self == null) return 0;
    if (self is int) return self;
    if (self is num) return self.toInt();
    if (self is String) return self.isBlank ? 0 : self.toInt();
    assert(false, "Can't convert to int");
    return null;
  }
}

final typeParameters = RegExp("<(.*)>");
final newLinesPattern = RegExp("\\n");

extension EnumValueExtensions on Object? {
  String? get enumValue {
    if (this == null) return null;
    return "$this".extension;
  }

  bool get isNullOrBlank {
    final self = this;
    if (self is String) {
      return self.isNullOrBlank;
    } else {
      return this == null;
    }
  }
}

extension IntList on List<int> {
  String sha256Hex() {
    return crypto.sha256.convert(this).toString();
  }

  crypto.Digest sha256() {
    return crypto.sha256.convert(this);
  }
}

extension AnyExtensions<T> on T? {
  R? let<R>(R block(T self)) {
    if (this == null) {
      return null;
    } else {
      return block(this!);
    }
  }

  T? also<R>(R block(T self)) {
    if (this == null) {
      return null;
    } else {
      block(this!);
      return this;
    }
  }
}

extension AnyFutureExtensions<T> on Future<T> {
  Future<T> maybeTimeout(Duration? duration, FutureOr<T> onTimeout()) {
    if (duration == null) return this;
    if (duration.inMicroseconds <= 0) return this;
    return this.timeout(duration, onTimeout: onTimeout);
  }
}

extension AnyFutureNullableExtensions<T> on Future<T>? {
  Future<R> let<R>(R block(T self)) async {
    if (this == null) {
      return Future.value(null);
    } else {
      return block(await this!);
    }
  }

  Future<T?> also<R>(R block(T self)) async {
    if (this == null) {
      return Future.value(null);
    } else {
      block(await this!);
      return this;
    }
  }
}

extension TypeExtensions on Type {
  String get name => "$this"
      .trimAround("_")
      .replaceAllMapped(
          typeParameters, (match) => "[${match.group(1)!.uncapitalize()}]")
      .uncapitalize();

  String get simpleName => simpleNameOfType(this);
}

String simpleNameOfType(Type type) {
  return "$type".replaceAll(typeParameters, '').uncapitalize();
}

extension DoubleExt on double {
  /// Gets the fraction part
  double get fractional => this - this.truncateToDouble();
}

const digits = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'};

extension ModelMapExtensions on Map<String, dynamic> {
  Map<String, dynamic> orEmpty() => <String, dynamic>{};
}

extension DynamicExtension on dynamic {
  String orBlank() => this?.toString() ?? "";
}

extension StringBufferExt on StringBuffer {
  StringBuffer operator +(append) {
    this.write(append);
    return this;
  }
}

final wordSeparator = RegExp('[\.\;\, ]');
final nameSeparator = RegExp('[@\.\; ]');
final isLetters = RegExp(r"^[A-Za-z]*$");

final upToLastDot = RegExp('.*\\.');
const aggresiveTokenizer = "(,|\\/|_|\\.|-|\\s)";
final aggresiveTokenizerPattern = RegExp(aggresiveTokenizer);

const spaceTokenizer = "(\s)";
final spaceTokenizerPattern = RegExp(spaceTokenizer);
enum IterationPosition { only, first, middle, last }

extension IterationPositionExtensions on IterationPosition {
  bool get isLast =>
      this == IterationPosition.last || this == IterationPosition.only;

  bool get isNotLast =>
      this != IterationPosition.last && this != IterationPosition.only;

  bool get isNotFirst =>
      this != IterationPosition.first && this != IterationPosition.only;

  bool get isFirst =>
      this == IterationPosition.first || this == IterationPosition.only;
}

extension IterableOfIntExtensions on Iterable<int>? {
  int sum() {
    if (this == null) return 0;
    var i = 0;
    for (final x in this!) {
      i += x;
    }
    return i;
  }
}

extension IterableOfDoubleExtensions on Iterable<double>? {
  double sum() {
    if (this == null) return 0;
    var i = 0.0;
    for (final x in this!) {
      i += x;
    }
    return i;
  }
}

extension ComparableIterableExtension<T extends Comparable> on Iterable<T> {
  T? max([T? ifNull]) {
    T? _max;
    for (final t in this.orEmpty()) {
      if (_max == null || t!.compareTo(_max) > 0) {
        _max = t;
      }
    }
    return _max ?? ifNull;
  }

  T? min([T? ifNull]) {
    T? _min;
    for (final t in this.orEmpty()) {
      if (_min == null || t!.compareTo(_min) < 0) {
        _min = t;
      }
    }
    return _min ?? ifNull;
  }

  List<T> sorted() {
    final buffer = [...this];
    buffer.sort((T a, T b) => a.compareTo(b));
    return buffer;
  }
}

extension SetNullableExtension<T> on Set<T>? {
  bool containsAny(Iterable<T>? toCompare) {
    return toCompare?.any((item) {
          return this?.contains(item) == true;
        }) ??
        false;
  }
}

extension SunnyIterableExtensionExt<T> on Iterable<T?> {
  /// No way to override the + operator for an iterable, so I use a downcast to iterable
  Iterable<T?> operator +(item) {
    final self = this as List<T?>;

    if (item is List<T>) {
      self.addAll(item);
    } else if (item is T) {
      self.add(item);
    } else if (item == null) {
      self.add(null);
    } else {
      throw "Invalid input - must be null, $T, List<$T>";
    }
    return this;
  }
}

extension SunnyIterableSafeExtensionExt<T> on Iterable<T> {
  Stream<List<T>> chunkedStream(int chunkSize) {
    return asChunkedStream(chunkSize, Stream.fromIterable(this));
  }

  List<T> freeze() {
    return List.unmodifiable(this).whereType<T>().toList();
  }

  T? random() {
    if (this.isEmpty) return null;
    final randomIdx = _random.nextInt(this.length);
    return this.toList()[randomIdx];
  }

  double sumBy(double toDouble(T? t)) {
    return this.map(toDouble).sum();
  }

  int sumByInt(int toDouble(T? t)) {
    return this.map(toDouble).sum();
  }

  List<R> mapIndexed<R>(R mapper(T item, int index)) {
    int i = 0;
    return [...this.map((item) => mapper(item, i++))];
  }

  List<R> expandIndexed<R>(Iterable<R> mapper(T item, int index)) {
    int i = 0;
    return [...this.expand((item) => mapper(item, i++))];
  }

  T? maxBy<R extends Comparable<R>>(R by(T? item), [T? ifNull]) {
    T? _max;
    for (final t in this) {
      if (_max == null || (by(t).compareTo(by(_max))) > 0) {
        _max = t;
      }
    }
    return _max ?? ifNull;
  }
}

extension SunnyIterableNullableExtensionExt<T> on Iterable<T?>? {
  Stream<List<T?>> chunkedStream(int chunkSize) {
    return asChunkedStream(chunkSize, Stream.fromIterable(this ?? <T>[]));
  }

  List<T> whereNotNull() {
    return this?.whereType<T>().toList() ?? [];
  }

  // ignore: use_to_and_as_if_applicable
  List<T> freeze() {
    return this == null
        ? const []
        : List.unmodifiable(this!).whereType<T>().toList();
  }

  T? random() {
    if (this == null || this!.isEmpty) return null;
    final randomIdx = _random.nextInt(this!.length);
    return this!.toList()[randomIdx];
  }

  double sumBy(double toDouble(T? t)) {
    if (this == null) return 0.0;
    return this!.map(toDouble).sum();
  }

  int sumByInt(int toDouble(T? t)) {
    if (this == null) return 0;
    return this!.map(toDouble).sum();
  }

  List<R> mapIndexed<R>(R mapper(T? item, int index)) {
    int i = 0;
    return [...?this?.map((T? item) => mapper(item, i++))];
  }

  List<R> expandIndexed<R>(Iterable<R> mapper(T? item, int index)) {
    int i = 0;
    return [...?this?.expand((T? item) => mapper(item, i++))];
  }

  T? maxBy<R extends Comparable<R>>(R by(T? item), [T? ifNull]) {
    T? _max;
    for (final T? t in (this ?? const [])) {
      if (_max == null || (by(t).compareTo(by(_max))) > 0) {
        _max = t;
      }
    }
    return _max ?? ifNull;
  }

  T? minBy<R extends Comparable<R>>(R by(T? item), [T? ifNull]) {
    T? _min;
    for (final T? t in (this ?? const [])) {
      if (_min == null || (by(t).compareTo(by(_min))) < 0) {
        _min = t;
      }
    }
    return _min ?? ifNull;
  }

  @deprecated
  List<T?> sorted([Comparator<T?>? compare]) {
    return sortedBy(compare);
  }

  List<T?> sortedBy([Comparator<T?>? compare]) {
    final buffer = [...?this];
    buffer.sort(compare);
    return buffer;
  }

  List<T> sortedUsing(Comparable getter(T? item)) {
    final List<T?> ts = <T?>[...?this];
    return ts.sortedBy((a, b) {
      final f1 = getter(a as T?);
      final f2 = getter(b as T?);
      return f1.compareTo(f2);
    }).cast();
  }

  Iterable<T?> uniqueBy(dynamic uniqueProp(T? item)) {
    final mapping = <dynamic, T?>{};
    for (final t in (this ?? <T>[])) {
      final unique = uniqueProp(t);
      mapping[unique] = t;
    }
    return mapping.values;
  }

  Stream<T?> toStream() {
    return Stream.fromIterable(this ?? []);
  }

  Stream<T> forEachAsync(FutureOr onEach(T? item)) async* {
    for (final item in (this ?? <T>[])) {
      await onEach(item);
      yield item!;
    }
  }

  void forEachIndexed<R>(R mapper(T? item, int index)) {
    if (this == null) return;
    int i = 0;

    for (final x in this!) {
      mapper(x, i++);
    }
  }

  List<T?> truncate([int? length]) {
    if (this == null) return [];
    if (length == null) return [...this!];
    return [...this!.take(length)];
  }

  Iterable<T?> orEmpty() => this ?? <T>[];

  List<T?> orEmptyList() => this?.toList() ?? <T>[];

  List<R> mapNotNull<R>(R? mapper(T? item)) {
    return [
      ...?this?.map(mapper).whereNotNull(),
    ];
  }

  Iterable<R> mapPos<R>(R mapper(T? item, IterationPosition pos)) {
    int i = 0;

    if (this == null) return const [];
    final length = this!.length;
    final isSingle = length == 1;
    return [
      ...this!.map((T? item) {
        final _i = i;
        i++;
        return mapper(
            item,
            isSingle
                ? IterationPosition.only
                : _i == 0
                    ? IterationPosition.first
                    : _i == length - 1
                        ? IterationPosition.last
                        : IterationPosition.middle);
      })
    ];
  }

  String joinWithAnd([String? formatter(T? input)?]) {
    formatter ??= (item) => item?.toString();
    if (this == null) return '';
    if (this!.length < 3) {
      return this!.join(" and ");
    } else {
      return mapPos((item, pos) {
        String? formatted = formatter!(item);
        switch (pos) {
          case IterationPosition.first:
          case IterationPosition.only:
            return formatted;
          case IterationPosition.middle:
            return ", $formatted";
          case IterationPosition.last:
            return ", and $formatted";
          default:
            return ", $formatted";
        }
      }).join("");
    }
  }

  T? lastOrNull() => this?.lastWhere((_) => true, orElse: () => null);

  T? firstOr([T? ifEmpty]) =>
      this?.firstWhere((_) => true, orElse: () => ifEmpty);
}

extension SunnyIterableIterableExtension<T> on Iterable<Iterable<T>> {
  List<T> flatten() {
    return [...this.expand((i) => i)];
  }
}

extension CoreListNullableExtension<T> on List<T>? {
  bool removeLastWhere({bool removeIf(T item)?, T? removeItem}) {
    assert(removeIf != null || removeItem != null);
    assert(removeIf == null || removeItem == null);

    if (this == null) return false;
    int lastIndex = this!.lastIndexWhere((item) {
      return removeItem != null ? removeItem == item : removeIf!(item);
    });

    if (lastIndex >= 0) {
      this!.removeAt(lastIndex);
      return true;
    } else {
      return false;
    }
  }

  Iterable<ListIndex<T>> whereIndexed([bool filter(T item)?]) {
    Iterable<ListIndex<T>> indexed = this != null
        ? this!.indexed() as Iterable<ListIndex<T>>
        : <ListIndex<T>>[];
    if (filter != null) {
      indexed = indexed.where((li) => filter(li.value));
    }
    return indexed;
  }

  T? lastOrNull({bool filter(T item)?}) {
    Iterable<T>? list = this;
    if (filter != null) {
      list = list?.where(filter);
    }
    return list?.isNotEmpty == true ? list?.last : null;
  }
}

extension CoreListExtension<T> on List<T> {
  T? get(int index) => Lists.getOrNull(this, index);

  List<T> updateWhere(bool predicate(T check), dynamic mutate(T input)) {
    return this.mapIndexed((T item, idx) {
      if (!predicate(item)) {
        return item;
      } else {
        final res = mutate(item);
        return res is T ? res : item;
      }
    } as T Function(T?, int));
  }

  Stream<List<T>> chunkedStream(int chunkSize) {
    return asChunkedStream(chunkSize, Stream.fromIterable(this));
  }

  Iterable<T> get iterable => this as Iterable<T>;

  T? tryGet(int index) {
    if (length > index) {
      return this[index];
    } else {
      return null;
    }
  }

  List<T> trySublist(int startIndex, int endIndex) {
    if (startIndex + 1 > length) {
      return const [];
    }
    final _end = min(length, endIndex);
    if (startIndex >= _end) return const [];
    return sublist(startIndex, _end);
  }

  T? tryRemove(int index) {
    if (length > index) {
      return this.removeAt(index);
    } else {
      return null;
    }
  }

  int get lastIndex => length - 1;

  List<T> compact() {
    return [
      ...where((item) => item != null),
    ];
  }

  T? firstOrNull([bool filter(T item)?]) {
    Iterable<T> list = this;
    if (filter != null) {
      list = list.where(filter);
    }
    return list.isNotEmpty == true ? list.first : null;
  }

  Iterable<ListIndex<T>> indexed() {
    return this.mapIndexed(((T item, int idx) => ListIndex<T>(idx, item)));
  }

  List<T> tail([int i = 1]) {
    List<T> list = this;
    return list.sublist(list.length - min<int>(i, list.length));
  }

  List<T> head([int num = 1]) {
    List<T> list = this;
    return list.sublist(0, min(num, list.length));
  }

  T? singleOrNull() {
    if (length != 1) return null;
    return first;
  }

  List<T> chop([int num = 1]) {
    final list = [...this];
    if (list.isEmpty) return list;

    return list.sublist(0, list.length - num);
  }

  @Deprecated("Use tryRemove")
  T? safeRemove(int index) {
    return tryRemove(index);
  }

  /// The existing List + operator only works for lists, so *= is the best we can do
  ///
  ///
  List<T> operator *(item) {
    if (item is List<T>) {
      this.addAll(item);
    } else if (item is T) {
      this.add(item);
    } else if (item == null) {
      /// we don't add nulls, may regret this some day
      return this;
    } else {
      throw "Invalid input - must be null, $T, List<$T>";
    }
    return this;
  }
}

class ListIndex<T> {
  final int index;
  final T value;

  const ListIndex(this.index, this.value);
}

extension BoolNullableExtension on bool? {
  bool? negate() {
    if (this == null) return null;
    return !this!;
  }
}

extension BoolExtension on bool {
  bool negate() {
    return !this;
  }
}

extension DateTimeNullableExtensions on DateTime? {
  /// Returns how much time has elapsed since this date.  If the date is null
  /// or in the future, then [Duration.zero] will be returned
  Duration get elapsed {
    if (this == null) return Duration.zero;
    if (this!.isFuture) return Duration.zero;
    return this!.sinceNow();
  }

  DateTime? atStartOfDay() {
    final t = this;
    if (t == null) return null;
    return DateTime(t.year, t.month, t.day);
  }

  DateTime? atTime([int hour = 0, int minute = 0, int second = 0]) {
    final t = this;
    if (t == null) return null;
    return DateTime(t.year, t.month, t.day, hour, minute, second);
  }
}

extension Multiples on int {
  int get million => this * 1000000;

  int get thousand => this * 1000;
}

extension TimeSpanExtensions on TimeSpan {
  TimeSpan abs() {
    return this;
  }
}

extension TimeSpanNullableExtensions on TimeSpan? {
  DateTime get fromNow {
    if (this == null) return DateTime.now();
    return DateTime.now().plusTimeSpan(this!.abs());
  }

  TimeSpan abs() {
    return this ?? TimeSpan.zero;
  }

  DateTime get ago {
    if (this == null) return DateTime.now();
    return DateTime.now().minusTimeSpan(this.abs());
  }
}

extension DurationExtensions on int {
  Duration get seconds => Duration(seconds: this);

  Duration get second => Duration(seconds: this);

  Duration get minutes => Duration(minutes: this);

  Duration get minute => Duration(minutes: this);

  Duration get hour => Duration(hours: this);

  Duration get hours => Duration(hours: this);

  Duration get days => Duration(days: this);

  Duration get day => Duration(days: this);

  Duration get microseconds => Duration(microseconds: this);

  Duration get milliseconds => Duration(milliseconds: this);

  Duration get ms => Duration(milliseconds: this);

  TimeSpan get weeks => TimeSpan(weeks: this);

  TimeSpan get week => weeks;

  TimeSpan get months => TimeSpan(months: this);

  TimeSpan get month => months;

  TimeSpan get years => TimeSpan(years: this);

  TimeSpan get year => years;
}

extension DurationExt on Duration {
  String format() {
    final micro = this.inMicroseconds;
    if (micro < 1000) {
      return "${micro}ns";
    }
    return "${inMilliseconds}ms";
  }

  Future<R?> then<R>(R block()?) async {
    await Future.delayed(this);
    return block?.call();
  }

  Future<R?> delay<R>([R block()?]) async {
    return await then(block);
  }

  Future<R?> pause<R>([R block()?]) async {
    return await then(block);
  }

  Duration operator /(double amount) {
    return Duration(microseconds: this.inMicroseconds ~/ amount);
  }
}

extension LoggerExtensions on Logger {
  void infoJson(String name, Map data) {
    info("$name --- ${data.toDebugString()}");
  }

  void fineJson(String name, Map data) {
    fine("$name --- ${data.toDebugString()}");
  }
}

extension MapDebug on Map {
  String toDebugString() {
    return "${entries.map((e) {
      var s = StringBuffer();
      s += (e.key ?? '-').toString().truncate(20).removeNewlines();
      s += ": ";
      s += (e.value ?? '-').toString().truncate(20).removeNewlines();
      return s;
    }).join(", ")}";
  }

  Map<String, String> toDebugMap() {
    return map((k, v) {
      return MapEntry((k ?? '-').toString().truncate(20).removeNewlines(),
          (v ?? '-').toString().truncate(20).removeNewlines());
    });
  }
}

extension MapListDebug<K, V> on Map<K, List<V>>? {
  Map<K, int> counts() {
    return {...?this?.map((k, v) => MapEntry(k, v.length))};
  }

  Map<K, List<V>> mergeWith(Map<K, List<V>?>? other) {
    final newMap = <K, List<V>>{...?this};
    other?.forEach((key, valueList) {
      newMap.putIfAbsent(key, () => <V>[]).addAll([...?valueList]);
    });
    return newMap;
  }
}
