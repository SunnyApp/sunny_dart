import 'dart:async';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:inflection2/inflection2.dart' as inflection;
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:recase/recase.dart';
import 'package:sunny_dart/time/time_span.dart';
import 'package:timezone/timezone.dart';

import '../helpers.dart';
import '../time.dart';

extension StringListExtension on List<String> {
  List<String> whereNotBlank() {
    return [
      ...where((item) => item.isNotNullOrBlank == true),
    ];
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
}

const _titles = {'dōTERRA'};

extension TypeExtensions on Type {
  String get name => "$this"
      .trimAround("_")
      .replaceAllMapped(typeParameters, (match) => "[${match.group(1).uncapitalize()}]")
      .uncapitalize();

  String get simpleName => "$this".removeAll(typeParameters).uncapitalize();
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
    final i = this ?? nullPointer("Null receiver.  Attempting to call toIntSafe");
    if (i is int) {
      return i;
    } else if (i.isIntegral) {
      return i.toInt();
    } else {
      throw "Number $i could not be safely truncated to an int";
    }
  }

  String formatCurrency() => currencyFormat.format(this);
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

extension StringExt on String {
  String ifThen(String ifString, String thenString) {
    if (this == null || this == ifString) return thenString;
    return this;
  }

  Color toColor() => colorFromHex(this);

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

  bool get isNumeric => num.tryParse(this) != null;

  bool get isNullOrEmpty => this?.isNotEmpty != true;

  bool get isNotNullOrEmpty => !isNullOrEmpty;

  bool get isNullOrBlank => this == null || this.trim().isEmpty == true;

  bool get isNotNullOrBlank => !isNullOrBlank;

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

  String trimAround(dynamic characters, {bool trimStart = true, bool trimEnd = true, bool trimWhitespace = true}) {
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
}

List<String> tokenizeString(String input, {bool splitAll = false, Pattern splitOn}) {
  if (input == null) return [];
  splitOn ??= (splitAll == true) ? aggresiveTokenizerPattern : spaceTokenizerPattern;
  return input.toSnakeCase().split(splitOn).whereNotBlank();
}

const aggresiveTokenizer = "(,|\\/|_|\\.|-|\\s)";
final aggresiveTokenizerPattern = RegExp(aggresiveTokenizer);

const spaceTokenizer = "(\s)";
final spaceTokenizerPattern = RegExp(spaceTokenizer);

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

extension IterableExtension<T> on Iterable<T> {
  List<T> freeze() {
    return List.unmodifiable(this);
  }

  List<R> mapIndexed<R>(R mapper(T item, int index)) {
    int i = 0;
    return [...this.map((T item) => mapper(item, i++))];
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

  List<R> mapNotNull<R>(R mapper(T item)) {
    return [
      ...map(mapper).where(notNull()),
    ];
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

  T safeRemove(int index) {
    if (this.length > index) {
      return removeAt(index);
    } else {
      return null;
    }
  }
}

class ListIndex<T> {
  final int index;
  final T value;

  const ListIndex(this.index, this.value);
}

extension ListExtension<T> on List<T> {
  T tryGet(int index) {
    if (length > index) {
      return this[index];
    } else {
      return null;
    }
  }

  T tryRemove(int index) {
    if (length > index) {
      return this.removeAt(index);
    } else {
      return null;
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
    var indexed = this?.indexed() ?? [];
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
}

extension BoolExtension on bool {
  bool negate() {
    if (this == null) return null;
    return !this;
  }
}

extension DateTimeExtensions on DateTime {
  DateTime withoutTime() => DateTime(this.year, this.month, this.day, 0, 0, 0, 0, 0);

  Duration sinceNow() => -(this.difference(DateTime.now()));

  int get yearsAgo => daysAgo ~/ 365;

  int get monthsAgo => daysAgo ~/ 30.3;

  int get daysAgo => max(sinceNow().inDays, 0);

  int get yearsApart => daysApart ~/ 365;

  int get monthsApart => daysApart ~/ 30.3;

  int get daysApart => sinceNow().inDays;

  bool get hasTime => this.second != 0 || this.minute != 0 || this.hour != 0 || this.millisecond != 0;

  DateTime plusTimeSpan(TimeSpan span) {
    final duration = span.toDuration(this);
    return this.add(duration);
  }

  bool get isFuture => this != null && this.isAfter(DateTime.now());

  bool get isPast => this != null && this.isBefore(DateTime.now());

  TZDateTime withTimeZone([Location location]) {
    assert(location != null);
    return TZDateTime.from(this, location ?? SunnyLocalization.userLocation);
  }
}

extension Multiples on int {
  int get million => this * 1000000;

  int get thousand => this * 1000;
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
}

extension DurationExt on Duration {
  String format() {
    final micro = this.inMicroseconds;
    if (micro < 1000) {
      return "${micro}ns";
    }
    return "${inMilliseconds}ms";
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
      return MapEntry(
          (k ?? '-').toString().truncate(20).removeNewlines(), (v ?? '-').toString().truncate(20).removeNewlines());
    });
  }
}

extension MapListDebug<K, V> on Map<K, List<V>> {
  Map<K, int> counts() {
    return {...?this.map((k, v) => MapEntry(k, v.length))};
  }
}
