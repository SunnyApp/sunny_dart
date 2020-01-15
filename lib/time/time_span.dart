import 'package:collection/collection.dart';

import '../extensions.dart';
import '../helpers.dart';

final equalsChecker = DeepCollectionEquality.unordered();

/// Represents a user-defined duration.  Unlike [Duration], this class does not normalize down to microseconds value,
/// but preserves the original precision.
class TimeSpan {
  final bool negated;
  final List<double> _values;

  TimeSpan(
      {bool negated = false,
      int years = 0,
      int months = 0,
      int weeks = 0,
      int days = 0,
      int hours = 0,
      int minutes = 0,
      int seconds = 0,
      int millis = 0,
      int micros = 0})
      : this.ofParts(<double>[
          years.toDouble(),
          months.toDouble(),
          weeks.toDouble(),
          days.toDouble(),
          hours.toDouble(),
          minutes.toDouble(),
          _secondsDecimal(seconds: seconds, millis: millis, micros: micros).toDouble(),
        ], negated: negated);

  factory TimeSpan.fromJson(value) {
    if (value == null) return null;
    if (value is TimeSpan) return value;
    if (value is String) return TimeSpan.ofISOString(value);
    if (value is List<num>) return TimeSpan.ofParts(value);
    throw "Invalid value for TimeSpan";
  }

  factory TimeSpan.ofSingleField(dynamic field, num value) {
    final unit = timeSpanUnitOf(field) ?? illegalState("Invalid time span $field");
    return unit.toTimeSpan(value);
  }

  TimeSpan.ofParts(List<num> parts, {this.negated = false})
      : assert(parts.length == 7),
        _values = List.unmodifiable([
          for (var value in parts) value?.toDouble() ?? 0.0,
        ]);

  factory TimeSpan.ofISOString(String isoString) {
    if (isoString?.isNotEmpty != true) return TimeSpan.zero;
    final match = durationRegex.firstMatch(isoString);
    if (match == null) return TimeSpan.zero;
    final parts = _newTimeSpanList();
    final bool negated = "-" == match.group(1);

    for (var g = 2; g < 9; g++) {
      final matchGroup = match.group(g);
      if (matchGroup == null) continue;
      parts[g - 2] = matchGroup.toDoubleOrNull() ?? illegalState("Unable to parse $matchGroup");
    }

    return TimeSpan.ofParts(parts, negated: negated);
  }

  TimeSpan operator +(TimeSpan other) {
    return TimeSpan(
        negated: this.negated ^ other.negated,
        years: years + other.years,
        months: months + other.months,
        weeks: weeks + other.weeks,
        days: days + other.days,
        hours: hours + other.hours,
        minutes: minutes + other.minutes,
        seconds: seconds + other.seconds,
        millis: millis + other.millis,
        micros: micros + other.micros);
  }

  int operator [](key) {
    final unit = timeSpanUnitOf(key);
    return unit.get(this);
  }

  dynamic toJson() => "$this";

  int get years => _values[0].toIntSafe();

  int get months => _values[1].toIntSafe();

  int get weeks => _values[2].toIntSafe();

  int get days => _values[3].toIntSafe();

  int get hours => _values[4].toIntSafe();

  int get minutes => _values[5].toIntSafe();

  int get seconds => _values[6].toInt();

  num get secondsDouble => _values[6];

  double get _millisDouble => (_values[6].toDouble().fractional * Duration.millisecondsPerSecond);

  int get millis {
    return _millisDouble.truncate();
  }

  int get micros {
    return (_millisDouble.fractional * Duration.microsecondsPerMillisecond).truncate();
  }

  @override
  String toString() => toIso8601String();

  String format({
    Map<TimeSpanUnit, String> labels,
    String separator = " ",
    bool pluralize = true,
    bool separateLabel = true,
  }) {
    labels ??= defaultLabels;
    return TimeSpanUnit.values.where((u) => u.get(this).isNotZero).map((unit) {
      final value = unit.get(this);
      return "$value${separateLabel ? " " : ""}${labels[unit].pluralizeIf(value != 1 && pluralize)}";
    }).join(" ");
  }

  String formatCondensed([String separator = " "]) =>
      format(labels: shortLabels, separator: separator, pluralize: false, separateLabel: false);

  String toIso8601String() {
    var str = "";
    if (negated) str += "-";
    str += "P";
    bool hasTime = false;
    for (final unit in TimeSpanUnit.values) {
      final section = unit.append(this);
      if (section.isNotEmpty && unit.isTimeField && !hasTime) {
        hasTime = true;
        str += "T";
      }
      str += section;
    }
    return str;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSpan &&
          runtimeType == other.runtimeType &&
          negated == other.negated &&
          equalsChecker.equals(_values, other._values);

  @override
  int get hashCode => negated.hashCode ^ _values.hashCode;

  static final TimeSpan zero = TimeSpan(days: 0);

  Duration toDuration([DateTime reference]) {
    int days = (7 * this.weeks) + this.days;
    reference ??= DateTime.now();

    if (this.months > 0) {
      final int numMonths = this.months.toInt() + reference.month.toInt();
      final DateTime monthsAdjusted = cloneDate(reference, month: numMonths);
      days += monthsAdjusted.difference(reference).inDays;
    }

    if (this.years > 0) {
      final int numYears = reference.year + this.years;
      final DateTime adjusted = cloneDate(reference, year: numYears);
      days += adjusted.difference(reference).inDays;
    }

    return Duration(
      days: days,
      minutes: minutes,
      hours: hours,
      seconds: seconds,
      milliseconds: millis,
      microseconds: micros,
    );
  }
}

typedef TimeSpanValue = num Function(TimeSpan span);

num _secondsDecimal({num seconds, num millis, num micros}) {
  seconds ??= 0;
  millis ??= 0;
  micros ??= 0;
  return (seconds ?? 0) +
      ((millis ?? 0.0) / Duration.millisecondsPerSecond) +
      ((micros ?? 0.0) / Duration.microsecondsPerSecond);
}

enum TimeSpanUnit {
  year,
  month,
  week,
  day,
  hour,
  minute,
  second,
  millisecond,
  microsecond,
}

final dateUnits = [...TimeSpanUnit.values.where((u) => !u.isTimeField)];
final timeUnits = [...TimeSpanUnit.values.where((u) => u.isTimeField)];

TimeSpanUnit timeSpanUnitOf(input) {
  if (input is TimeSpanUnit) return input;
  final lc = "$input".toLowerCase().trimEnd("s");
  return TimeSpanUnit.values.where((unit) => unit.name == lc).firstOrNull;
}

List<TimeSpanUnit> tryParseTimeSpanUnit(input) {
  if (input is TimeSpanUnit) return [input];
  var lc = "$input".toLowerCase();
  if (lc.isEmpty == true) return [];
  final knownUnit = knownSpanUnits[lc];
  if (knownUnit != null) return [knownUnit];
  if (lc == "m") {
    return [TimeSpanUnit.minute];
  }
  if (lc.length > 3) lc.trimEnd("s");
  final timeSpan = timeSpanUnitOf(input);
  if (timeSpan != null) return [timeSpan];

  return [
    ...TimeSpanUnit.values.where((unit) {
      return unit.index < 7 && (unit.label.startsWith(lc) || unit.shortLabel.startsWith(lc));
    })
  ];
}

final knownSpans = <String, TimeSpan>{
  "monthly": TimeSpan(months: 1),
  "yearly": TimeSpan(years: 1),
  "daily": TimeSpan(days: 1),
};

final knownSpanUnits = <String, TimeSpanUnit>{
  "m": TimeSpanUnit.minute,
  "monthly": TimeSpanUnit.month,
  "yearly": TimeSpanUnit.year,
  "daily": TimeSpanUnit.day
};

DateTime cloneDate(
  DateTime orig, {
  int year,
  int month,
  int day,
  int hour,
  int minute,
  int second,
  int millisecond,
  int microsecond,
}) {
  return DateTime(
    year ?? orig.year,
    month ?? orig.month,
    day ?? orig.day,
    hour ?? orig.hour,
    minute ?? orig.minute,
    second ?? orig.second,
    millisecond ?? orig.millisecond,
    microsecond ?? orig.microsecond,
  );
}

final Map<TimeSpanUnit, String> defaultLabels = Map.fromEntries(TimeSpanUnit.values.map((v) => MapEntry(v, v.label)));
final Map<TimeSpanUnit, String> shortLabels =
    Map.fromEntries(TimeSpanUnit.values.map((v) => MapEntry(v, v.shortLabel)));

extension TimeSpanUnitExt on TimeSpanUnit {
  bool get isTimeField => index > 3;

  bool get isVirtual => index > 6;

  int get(TimeSpan span) {
    switch (this) {
      case TimeSpanUnit.microsecond:
        return span.micros;
      case TimeSpanUnit.millisecond:
        return span.millis;
      case TimeSpanUnit.second:
        return span.seconds;
      default:
        return span._values[this.index].toIntSafe();
    }
  }

  String append(TimeSpan self) {
    if (isVirtual) return "";
    final value = self._values[this.index];
    if (value.isZero || isVirtual) return "";
    String numFormat = this == TimeSpanUnit.second ? value.formatNumber(fixed: 6) : value.formatNumber();
    return "$numFormat$marker";
  }

  String get marker => label.first.toUpperCase();

  String get name {
    final str = "$this";
    return str.replaceAll("TimeSpanUnit.", "");
  }

  String get label => name;

  String get shortLabel {
    switch (this) {
      case TimeSpanUnit.millisecond:
        return "ms";
      case TimeSpanUnit.microsecond:
        return "ns";
      default:
        return label.first;
    }
  }

  TimeSpan toTimeSpan(num amount) {
    switch (this) {
      case TimeSpanUnit.year:
        return TimeSpan(years: amount.toIntSafe());
      case TimeSpanUnit.month:
        return TimeSpan(months: amount.toIntSafe());
      case TimeSpanUnit.week:
        return TimeSpan(weeks: amount.toIntSafe());
      case TimeSpanUnit.day:
        return TimeSpan(days: amount.toIntSafe());
      case TimeSpanUnit.hour:
        return TimeSpan(hours: amount.toIntSafe());
      case TimeSpanUnit.minute:
        return TimeSpan(minutes: amount.toIntSafe());
      case TimeSpanUnit.second:
        return TimeSpan.ofParts(_newTimeSpanList(TimeSpanUnit.second, amount.toDouble()));
      case TimeSpanUnit.millisecond:
        final amt = _secondsDecimal(millis: amount);
        return TimeSpan.ofParts(_newTimeSpanList(TimeSpanUnit.second, amt.toDouble()));
      case TimeSpanUnit.microsecond:
        final amt = _secondsDecimal(micros: amount);
        return TimeSpan.ofParts(_newTimeSpanList(TimeSpanUnit.second, amt.toDouble()));
      default:
        return illegalState("Invalid time span unit: ${this}");
    }
  }

  int get index {
    switch (this) {
      case TimeSpanUnit.year:
        return 0;
      case TimeSpanUnit.month:
        return 1;
      case TimeSpanUnit.week:
        return 2;
      case TimeSpanUnit.day:
        return 3;
      case TimeSpanUnit.hour:
        return 4;
      case TimeSpanUnit.minute:
        return 5;
      case TimeSpanUnit.second:
        return 6;
      case TimeSpanUnit.millisecond:
        return 7;
      case TimeSpanUnit.microsecond:
        return 8;
      default:
        return illegalState("Invalid unit: $this");
    }
  }
}

List<double> _newTimeSpanList([index, double value]) {
  final list = List<double>(7);
  if (index != null && value != null) {
    final idx = index is TimeSpanUnit ? index.index : (index as int);
    list[idx] = value;
  }
  return list;
}

const numberPattern = "?:([-+]?[0-9]+(?:[.,][0-9]{0,9})?)";
const spanPattern = "($numberPattern)([a-z]+)";
final durationPattern = "([-+]?)P${dateUnits.map(_unitRegex).join()}(?:T${timeUnits.map(_unitRegex).join()})?";
final durationRegex = RegExp(durationPattern);

/// Not used for the ISO parsing, but this helps us in our parsing to find tokens like "3y"
final spanRegex = RegExp(spanPattern);

String _unitRegex(TimeSpanUnit unit) {
  return "($numberPattern?${unit.marker})?";
}
