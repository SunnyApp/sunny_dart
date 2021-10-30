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
    if (self is String) return int.tryParse(self.trimStart('0'));
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

extension StringTitleExt on String? {
  String toTitle([String def = ""]) {
    if (this == null) return def;
    return tokenize(splitAll: true).map((_) => _.capitalize()).join(" ");
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

extension SunnyIterableSafeExtensionExt<T> on Iterable<T> {}

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

extension CoreListExtension<T extends Object> on List<T> {
  T? get(int index) => Lists.getOrNull(this, index);

  List<T> updateWhere(bool predicate(T check), dynamic mutate(T input)) {
    return this.notNull().mapIndexed((T item, idx) {
          if (!predicate(item)) {
            return item;
          } else {
            final res = mutate(item);
            return res is T ? res : item;
          }
        });
  }

  Stream<List<T>> chunkedStream(int chunkSize) {
    return asChunkedStream(chunkSize, Stream.fromIterable(this));
  }

  Iterable<T> get iterable => this as Iterable<T>;

  T? tryGet(int index) {
    if (length > index && index >= 0) {
      return this[index];
    } else {
      return null;
    }
  }

  T? tryEnd(int index) {
    return tryGet(length - 1 + index);
  }

  T end(int index) {
    return this[length - 1 + index];
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

  T? firstOrNull([bool filter(T item)?]) {
    Iterable<T> list = this;
    if (filter != null) {
      list = list.where(filter);
    }
    return list.isNotEmpty == true ? list.first : null;
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
