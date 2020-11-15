import 'dart:async';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:inflection2/inflection2.dart' as inflection;
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:recase/recase.dart';
import 'package:sunny_dart/json/json_path.dart';
import 'package:sunny_dart/time/time_span.dart';
import 'package:timezone/timezone.dart';

import '../helpers.dart';
import '../time.dart';

final _random = Random();

extension StringListExtension on List<String> {
  List<String> whereNotBlank() {
    return [
      ...where((item) => item.isNotNullOrBlank == true),
    ];
  }
}

extension ObjectToListExtension<T> on T {
  List<T> asList() {
    return [if (this != null) this];
  }

  int toInt() {
    final self = this;
    if (self == null) return null;
    if (self is int) return self;
    if (self is num) return self.toInt();
    assert(false, "Can't convert to int");
    return null;
  }
}

extension ObjectExtension on dynamic {
  int toInteger() {
    final self = this;
    if (self == null) return 0;
    if (self is int) return self;
    if (self is num) return self.toInt();
    if (self is String) return (self.ifBlank("0")).toInt();
    assert(false, "Can't convert to int");
    return null;
  }
}

extension EnumValueExtensions on Object {
  String get enumValue {
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

final typeParameters = RegExp("<(.*)>");
final newLinesPattern = RegExp("\\n");

extension IntList on List<int> {
  String sha256Hex() {
    return crypto.sha256.convert(this).toString();
  }

  crypto.Digest sha256() {
    return crypto.sha256.convert(this);
  }
}

extension AnyExtensions<T> on T {
  R let<R>(R block(T self)) {
    if (this == null) {
      return null;
    } else {
      return block(this);
    }
  }

  T also<R>(R block(T self)) {
    if (this == null) {
      return null;
    } else {
      block(this);
      return this;
    }
  }
}

extension AnyFutureExtensions<T> on Future<T> {
  Future<R> let<R>(R block(T self)) async {
    if (this == null) {
      return null;
    } else {
      return block(await this);
    }
  }

  Future<T> also<R>(R block(T self)) async {
    if (this == null) {
      return null;
    } else {
      block(await this);
      return this;
    }
  }
}

const _titles = {'dōTERRA'};

extension TypeExtensions on Type {
  String get name => "$this"
      .trimAround("_")
      .replaceAllMapped(
          typeParameters, (match) => "[${match.group(1).uncapitalize()}]")
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

extension NumExt on num {
  bool get isIntegral {
    return this is int || this?.roundToDouble() == this;
  }

  bool get isZero => this == 0.0;

  bool get isNotZero {
    if (this == null) return false;
    return this != 0.0;
  }

  void repeat(void forEach()) {
    assert(this > -1);
    for (int i = 0; i < this; i++) {
      forEach();
    }
  }

  String formatNumber({int fixed = 3, NumberFormat using}) {
    if (this == null) return null;
    if (using != null) return using.format(this);
    return isIntegral ? "${toInt()}" : toStringAsFixed(fixed);
  }

  int toIntSafe() {
    final i =
        this ?? nullPointer("Null receiver.  Attempting to call toIntSafe");
    if (i is int) {
      return i;
    } else if (i.isIntegral) {
      return i.toInt();
    } else {
      throw "Number $i could not be safely truncated to an int";
    }
  }

  double normalize(double end, [double start = 0]) {
    if (this <= start) return 0;
    if (this >= end) return 1;
    return (this - start) / (end - start);
  }

  double notZero([double alt = 0.00001]) {
    if (this == 0) {
      return alt;
    } else {
      return this.toDouble();
    }
  }

  n atLeast<n extends num>(n atLeast) {
    if (this == null) return atLeast;
    if (this < atLeast) return atLeast;
    return this as n;
  }

  double between(num low, num upper) {
    return min(upper.toDouble(), max(low.toDouble(), this.toDouble()));
  }

  String formatCurrency() => currencyFormat.format(this);

  double times(num other) {
    if (this == null) return null;
    if (other == null) return this.toDouble();
    return (this * other).toDouble();
  }

  bool get isGreaterThan0 {
    return this != null && this > 0;
  }
}

final currencyFormat = NumberFormat.simpleCurrency();

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

const _pluralStopWords = {"info", "information"};
final wordSeparator = RegExp('[\.\;\, ]');
final nameSeparator = RegExp('[@\.\; ]');
final isLetters = RegExp(r"^[A-Za-z]*$");

extension StringExtensions on String {
  String get firstWord {
    if (this == null) return null;
    return this.split(nameSeparator).firstOrNull();
  }

  String toPathName() {
    if (this == null) return null;
    if (!this.startsWith("/")) {
      return "/$this";
    } else {
      return this;
    }
  }

  List<String> toStringList() {
    if (this.isNotNullOrBlank) {
      return [this];
    } else {
      return const [];
    }
  }

  JsonPath toJsonPath() {
    return JsonPath.of(this.toPathName());
  }

  String ifThen(String ifString, String thenString) {
    if (this == null || this == ifString) return thenString;
    return this;
  }

  String plus(String after) {
    if (this.isNullOrBlank) return '';
    return "${this}$after";
  }

  Color toColor() => colorFromHex(this);

  Uri toUri() => this == null ? null : Uri.parse(this);

  String nullIfBlank() {
    if (isNullOrBlank) return null;
    return this;
  }

  String join(String other, [String separator = " "]) {
    if (this == null && other == null) return null;
    if (this == null || other == null) return this ?? other;
    return "${this}$separator$other";
  }

  String pluralize([int count = 2]) {
    return pluralizeIf(count != 1);
  }

  String toTitle([String def = ""]) {
    if (this == null) return def;
    if (_titles.contains(this)) return this;
    return tokenize(splitAll: true).map((_) => _.capitalize()).join(" ");
  }

  String article() {
    if (this.isNullOrBlank) return "";
    return this.first.isVowel ? "an $this" : "a $this";
  }

  bool get isVowel {
    switch (this) {
      case "a":
      case "e":
      case "i":
      case "o":
      case "u":
        return true;
      default:
        return false;
    }
  }

  List<String> get words {
    if (this == null) return const [];
    return [
      for (final word in this.split(wordSeparator))
        if (word.trim().isNotNullOrBlank) word,
    ];
  }

  /// Whether the string contains only letters
  bool get isLettersOnly {
    if (this.isNullOrBlank) return false;
    return isLetters.hasMatch(this);
  }

  bool get isNumeric => num.tryParse(this) != null;

  bool get isNullOrEmpty => this?.isNotEmpty != true;

  bool get isNotNullOrEmpty => !isNullOrEmpty;

  bool get isNullOrBlank => this == null || this.trim().isEmpty == true;

  bool get isNotNullOrBlank => !isNullOrBlank;

  String repeat(int count) {
    return buildString((str) {
      for (var i = 0; i < count; i++) {
        str += this;
      }
    });
  }

  String orEmpty() {
    if (this == null) return "";
    return this;
  }

  String pluralizeIf(bool condition) {
    if (_pluralStopWords.any((s) => this?.toLowerCase()?.endsWith(s) == true)) {
      return this;
    }
    return condition ? inflection.pluralize(this) : this;
  }

  String truncate(int length) {
    if (this.length <= length) {
      return this;
    } else {
      return this.substring(0, length);
    }
  }

  String get first {
    if (this?.isNotEmpty == true) return this[0];
    return null;
  }

  String trimAround(dynamic characters,
      {bool trimStart = true,
      bool trimEnd = true,
      bool trimWhitespace = true}) {
    final target = this;
    var manipulated = target;
    if (trimWhitespace) {
      manipulated = manipulated.trim();
    }

    final chars = characters is List<String> ? characters : ["$characters"];
    chars?.forEach((c) {
      if (trimEnd && manipulated.endsWith(c)) {
        manipulated = manipulated.substring(0, manipulated.length - c.length);
      }
      if (trimStart && manipulated.startsWith(c)) {
        manipulated = manipulated.substring(1);
      }
    });
    return manipulated;
  }

  String trimEnd(dynamic characters, {bool trimWhitespace = true}) =>
      trimAround(characters, trimWhitespace: trimWhitespace, trimStart: false);

  String trimStart(dynamic characters, {bool trimWhitespace = true}) =>
      trimAround(characters, trimWhitespace: trimWhitespace, trimEnd: false);

  String removeNewlines() {
    return removeAll(newLinesPattern);
  }

  String ifBlank(String then) {
    if (this.isNullOrBlank) return then;
    return this;
  }

  int toInt() => int.parse(this);

  int toIntOrNull() => int.tryParse(this);

  double toDouble() => double.parse(this);

  double toDoubleOrNull() => double.tryParse(this);

  String toSnakeCase() => ReCase(this).snakeCase.toLowerCase();

  String toCamelCase() => ReCase(this).camelCase.uncapitalize();

  String toTitleCase() {
    if (_titles.contains(this)) return this;
    return ReCase(this).titleCase;
  }

  ReCase get recase => ReCase(this);

  String removeAll(Pattern pattern) => this.replaceAll(pattern, "");

  String uncapitalize() {
    final source = this;
    if (source == null || source.isEmpty) {
      return source;
    } else {
      return source[0].toLowerCase() + source.substring(1);
    }
  }

  String capitalize() {
    final source = this;
    if (source == null || source.isEmpty) {
      return source;
    } else {
      return source[0].toUpperCase() + source.substring(1);
    }
  }

  List<String> dotSplit() => this.split("\.");

  List<String> tokenize({bool splitAll = false, Pattern splitOn}) {
    return tokenizeString(this, splitAll: splitAll, splitOn: splitOn);
  }

  String get extension {
    if (this == null) return null;
    return "$this".replaceAll(upToLastDot, '');
  }
}

List<String> tokenizeString(String input,
    {bool splitAll = false, Pattern splitOn}) {
  if (input == null) return [];
  splitOn ??=
      (splitAll == true) ? aggresiveTokenizerPattern : spaceTokenizerPattern;
  return input.toSnakeCase().split(splitOn).whereNotBlank();
}

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

extension IterableOfIntExtensions on Iterable<int> {
  int sum() {
    if (this == null) return 0;
    var i = 0;
    for (final x in this) {
      i += x;
    }
    return i;
  }
}

extension IterableOfDoubleExtensions on Iterable<double> {
  double sum() {
    if (this == null) return 0;
    var i = 0.0;
    for (final x in this) {
      i += x;
    }
    return i;
  }
}

extension ComparableIterableExtension<T extends Comparable> on Iterable<T> {
  T max([T ifNull]) {
    T _max;
    for (final t in this.orEmpty()) {
      if (_max == null || t.compareTo(_max) > 0) {
        _max = t;
      }
    }
    return _max ?? ifNull;
  }

  T min([T ifNull]) {
    T _min;
    for (final t in this.orEmpty()) {
      if (_min == null || t.compareTo(_min) < 0) {
        _min = t;
      }
    }
    return _min ?? ifNull;
  }

  List<T> sorted() {
    final buffer = [...this];
    buffer.sort((T a, T b) => a?.compareTo(b));
    return buffer;
  }
}

extension SetExtension<T> on Set<T> {
  bool containsAny(Iterable<T> toCompare) {
    return toCompare?.any((item) {
          return this.contains(item);
        }) ??
        false;
  }
}

extension IterableExtension<T> on Iterable<T> {
  /// No way to override the + operator for an iterable, so I use a downcast to iterable
  Iterable<T> operator +(item) {
    final self = this as List<T>;

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

  T random() {
    if (this == null || this.isEmpty) return null;
    final randomIdx = _random.nextInt(this.length);
    return this.toList()[randomIdx];
  }

  double sumBy(double toDouble(T t)) {
    if (this == null) return 0.0;
    return this.map(toDouble).sum();
  }

  int sumByInt(int toDouble(T t)) {
    if (this == null) return 0;
    return this.map(toDouble).sum();
  }

  // ignore: use_to_and_as_if_applicable
  List<T> freeze() {
    return List.unmodifiable(this);
  }

  List<R> mapIndexed<R>(R mapper(T item, int index)) {
    int i = 0;
    return [...this.map((T item) => mapper(item, i++))];
  }

  List<R> expandIndexed<R>(Iterable<R> mapper(T item, int index)) {
    int i = 0;
    return [...this.expand((T item) => mapper(item, i++))];
  }

  T maxBy<R extends Comparable<R>>(R by(T item), [T ifNull]) {
    T _max;
    for (final T t in (this ?? const [])) {
      if (_max == null || (by(t)?.compareTo(by(_max)) ?? 0) > 0) {
        _max = t;
      }
    }
    return _max ?? ifNull;
  }

  T minBy<R extends Comparable<R>>(R by(T item), [T ifNull]) {
    T _min;
    for (final T t in (this ?? const [])) {
      if (_min == null || (by(t)?.compareTo(by(_min)) ?? 0) < 0) {
        _min = t;
      }
    }
    return _min ?? ifNull;
  }

  @deprecated
  List<T> sorted([Comparator<T> compare]) {
    return sortedBy(compare);
  }

  List<T> sortedBy([Comparator<T> compare]) {
    final buffer = [...?this];
    buffer.sort(compare);
    return buffer;
  }

  List<T> sortedUsing(Comparable getter(T item)) {
    final List<T> ts = <T>[...?this];
    return ts.sortedBy((a, b) {
      final f1 = getter(a as T);
      final f2 = getter(b as T);
      return f1?.compareTo(f2) ?? -1;
    }).cast();
  }

  Iterable<T> uniqueBy(dynamic uniqueProp(T item)) {
    final mapping = <dynamic, T>{};
    for (final t in (this ?? <T>[])) {
      final unique = uniqueProp(t);
      mapping[unique] = t;
    }
    return mapping.values;
  }

  Stream<T> toStream() {
    return Stream.fromIterable(this ?? []);
  }

  Stream<T> forEachAsync(FutureOr onEach(T item)) async* {
    for (final item in (this ?? <T>[])) {
      await onEach(item);
      yield item;
    }
  }

  void forEachIndexed<R>(R mapper(T item, int index)) {
    if (this == null) return;
    int i = 0;

    for (final x in this) {
      mapper(x, i++);
    }
  }

  List<T> truncate([int length]) {
    if (this == null) return [];
    if (length == null) return [...this];
    return [...this.take(length)];
  }

  Iterable<T> orEmpty() => this ?? <T>[];

  List<T> orEmptyList() => this?.toList() ?? <T>[];

  List<R> mapNotNull<R>(R mapper(T item)) {
    return [
      ...map(mapper).where(notNull()),
    ];
  }

  Iterable<R> mapPos<R>(R mapper(T item, IterationPosition pos)) {
    int i = 0;

    final length = this.length;
    final isSingle = length == 1;
    return [
      ...this.map((T item) {
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

  String joinWithAnd([String formatter(T input)]) {
    formatter ??= (item) => item?.toString();
    if (length < 3) {
      return this.join(" and ");
    } else {
      return mapPos((item, pos) {
        String formatted = formatter(item);
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

  T lastOrNull() => this.lastWhere((_) => true, orElse: () => null);

  T firstOr([T ifEmpty]) => this.firstWhere((_) => true, orElse: () => ifEmpty);
}

extension IterableIterableExtension<T> on Iterable<Iterable<T>> {
  List<T> flatten() {
    return [...this.expand((i) => i)];
  }
}

extension CoreListExtension<T> on List<T> {
  T get(int index) => Lists.getOrNull(this, index);

  List<T> updateWhere(bool predicate(T check), dynamic mutate(T input)) {
    return this.mapIndexed((item, idx) {
      if (!predicate(item)) {
        return item;
      } else {
        final res = mutate(item);
        return res is T ? res : item;
      }
    });
  }

  // ignore: unnecessary_cast
  Iterable<T> get iterable => this as Iterable<T>;

  T tryGet(int index) {
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

  T tryRemove(int index) {
    if (length > index) {
      return this.removeAt(index);
    } else {
      return null;
    }
  }

  int get lastIndex => length - 1;

  bool removeLastWhere({bool removeIf(T item), T removeItem}) {
    assert(removeIf != null || removeItem != null);
    assert(removeIf == null || removeItem == null);

    if (this == null) return false;
    int lastIndex = this.lastIndexWhere((item) {
      return removeItem != null ? removeItem == item : removeIf(item);
    });

    if (lastIndex >= 0) {
      this.removeAt(lastIndex);
      return true;
    } else {
      return false;
    }
  }

  List<T> compact() {
    return [
      ...where((item) => item != null),
    ];
  }

  T firstOrNull([bool filter(T item)]) {
    Iterable<T> list = this;
    if (filter != null) {
      list = list?.where(filter);
    }
    return list?.isNotEmpty == true ? list.first : null;
  }

  Iterable<ListIndex<T>> indexed() {
    return this.mapIndexed((item, idx) => ListIndex<T>(idx, item));
  }

  Iterable<ListIndex<T>> whereIndexed([bool filter(T item)]) {
    Iterable<ListIndex<T>> indexed = this != null
        ? this.indexed() as Iterable<ListIndex<T>>
        : <ListIndex<T>>[];
    if (filter != null) {
      indexed = indexed?.where((li) => filter(li.value));
    }
    return indexed;
  }

  T lastOrNull({bool filter(T item)}) {
    Iterable<T> list = this;
    if (filter != null) {
      list = list?.where(filter);
    }
    return list?.isNotEmpty == true ? list.last : null;
  }

  List<T> tail([int i = 1]) {
    List<T> list = this;
    return list.sublist(list.length - min<int>(i, list.length));
  }

  List<T> head([int num = 1]) {
    List<T> list = this;
    return list.sublist(0, min(num, list.length));
  }

  T singleOrNull() {
    if (length != 1) return null;
    return first;
  }

  List<T> chop([int num = 1]) {
    final list = [...this];
    if (list.isEmpty) return list;

    return list.sublist(0, list.length - num);
  }

  @Deprecated("Use tryRemove")
  T safeRemove(int index) {
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

extension BoolExtension on bool {
  bool negate() {
    if (this == null) return null;
    return !this;
  }
}

extension DateTimeExtensions on DateTime {
  DateTime withoutTime() =>
      DateTime(this.year, this.month, this.day, 0, 0, 0, 0, 0);

  Duration sinceNow() => -(this.difference(DateTime.now()));

  int get yearsAgo => daysAgo ~/ 365;

  int get monthsAgo => daysAgo ~/ 30.3;

  int get daysAgo => max(sinceNow().inDays, 0);

  int get hoursAgo => max(sinceNow().inHours, 0);

  /// Returns how much time has elapsed since this date.  If the date is null
  /// or in the future, then [Duration.zero] will be returned
  Duration get elapsed {
    if (this == null) return Duration.zero;
    if (this.isFuture) return Duration.zero;
    return this.sinceNow();
  }

  int get yearsApart => daysApart ~/ 365;

  int get monthsApart => daysApart ~/ 30.3;

  int get daysApart => sinceNow().inDays;

  bool get hasTime =>
      this.second != 0 ||
      this.minute != 0 ||
      this.hour != 0 ||
      this.millisecond != 0;

  DateTime plusTimeSpan(TimeSpan span) {
    final duration = span.toDuration(this);
    return this.add(duration);
  }

  bool isSameDay(final other) {
    if (other is DateTime) {
      return this.year == other.year &&
          this.month == other.month &&
          this.day == other.day;
    } else if (other is DateComponents) {
      return (other.year == null || this.year == other.year) &&
          this.month == other.month &&
          this.day == other.day;
    }
    assert(false, 'Shouldnt get here');
    return false;
  }

  DateTime minusTimeSpan(TimeSpan span) {
    final duration = span.toDuration(this);
    return this.add(-duration);
  }

  bool get isFuture => this != null && this.isAfter(DateTime.now());

  bool get isPast => this != null && this.isBefore(DateTime.now());

  TZDateTime withTimeZone([Location location]) {
    assert(location != null);
    if (this is TZDateTime) return (this as TZDateTime);
    return TZDateTime.from(
        this, location ?? SunnyLocalization.userLocationOrNull);
  }

  DateTime atStartOfDay() {
    final t = this;
    if (t == null) return null;
    return DateTime(t.year, t.month, t.day);
  }

  DateTime atTime([int hour = 0, int minute = 0, int second = 0]) {
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
  DateTime get fromNow {
    if (this == null) return DateTime.now();
    return DateTime.now().plusTimeSpan(this.abs());
  }

  TimeSpan abs() {
    return this;
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

  Future<R> then<R>(R block()) async {
    await Future.delayed(this);
    return block?.call();
  }

  Future<R> delay<R>([R block()]) async {
    return await then(block);
  }

  Future<R> pause<R>([R block()]) async {
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

extension MapListDebug<K, V> on Map<K, List<V>> {
  Map<K, int> counts() {
    return {...?this.map((k, v) => MapEntry(k, v.length))};
  }

  Map<K, List<V>> mergeWith(Map<K, List<V>> other) {
    final newMap = <K, List<V>>{...?this};
    other?.forEach((key, valueList) {
      newMap.putIfAbsent(key, () => <V>[]).addAll([...?valueList]);
    });
    return newMap;
  }
}
