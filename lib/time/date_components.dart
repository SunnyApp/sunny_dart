import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:sunny_dart/helpers/lists.dart';
import 'package:timezone/timezone.dart';

import '../extensions.dart';
import '../helpers.dart';

final _log = Logger("dateComponents");

/// A flexible container for date components that provides a robust parsing/building mechanism.  If the input type is known
/// to be a [String], [Map] or [DateTime], then use the corresponding constructors.
///
/// [DateComponents.tryFrom] will / attempt to construct a [DateComponents] instance, and will return `null` if none could be constructed.
/// [DateComponents.from] will / attempt to construct a [DateComponents] instance, and will raise an exception if unable to create a [DateComponents] instance
///
class DateComponents with EquatableMixin {
  int? day;
  int? month;
  int? year;

  DateComponents({this.day, this.month = 1, this.year});

  factory DateComponents.fromDateTime(DateTime dateTime) {
    return DateComponents(
        day: dateTime.day, month: dateTime.month, year: dateTime.year);
  }

  factory DateComponents.now() => DateComponents.fromDateTime(DateTime.now());

  /// from a map, assuming keys [kday], [kmonth], [kyear]
  DateComponents.fromMap(Map toParse)
      : day = _tryParseInt(toParse[kday]),
        month = _tryParseInt(toParse[kmonth]),
        year = _tryParseInt(toParse[kyear]);

  static DateComponents? tryFrom(input) {
    try {
      if (input == null) return null;
      return DateComponents.from(input);
    } catch (e) {
      _log.finer("Date parse error: $e");
      return null;
    }
  }

  static DateComponents? from(input) {
    assert(input != null, "Input must not be null");
    if (input is DateComponents) return input;
    if (input is DateTime) return DateComponents.fromDateTime(input);
    if (input is Map) return DateComponents.fromMap(input);
    return DateComponents.parse("$input");
  }

  DateComponents copy() {
    return DateComponents(day: day, month: month, year: year);
  }

  static DateComponents? tryParse(String input) {
    try {
      return DateComponents.parse(input);
    } catch (e) {
      _log.finer("Date parse error: $e");
      return null;
    }
  }

  static DateComponents parse(String toParse) {
    final parseAttempt = DateTime.tryParse(toParse.trim());
    if (parseAttempt != null) {
      return DateComponents.fromDateTime(parseAttempt);
    }

    final input = "$toParse";
    final tokenized = tokenizeString(input, splitAll: true);
    final parts = tokenized
        .map((value) {
          if (value.isNumeric) {
            return value;
          } else {
            final month = DateFormat.MMMM().parseLoose(value);
            return "${month.month}";
          }
        })
        .map((value) => value.startsWith("0") ? value.substring(1) : value)
        .map((value) => int.tryParse(value))
        .toList();

    final length = parts.length;
    switch (length) {
      case 3:
        if (parts[0]! > 1000) {
          return DateComponents(year: parts[0], month: parts[1], day: parts[2]);
        } else if (parts[2]! > 1000) {
          return DateComponents(year: parts[2], month: parts[0], day: parts[1]);
        } else {
          return illegalState("Invalid date - can't find year");
        }
      case 2:
        if (parts[0]! > 1000) {
          return DateComponents(year: parts[0], month: parts[1]);
        } else if (parts[1]! > 1000) {
          return DateComponents(year: parts[1], month: parts[0]);
        } else {
          return DateComponents(month: parts[0], day: parts[1]);
        }
      case 1:
        if (parts[0]! < 1000) throw "Unable to find year within date";
        return DateComponents(year: parts[0]);
      default:
        throw "Unable to extract date parameters";
    }
  }

  static DateComponents? fromJson(json) {
    return DateComponents.from(json);
  }

  dynamic toJson() {
    return "$this";
  }

  Map<String, int?> toMap() {
    return {
      if (hasYear) kyear: year,
      if (hasMonth) kmonth: month,
      if (hasDay) kday: day,
    };
  }

  bool get isFullDate => year != null;

  bool get isFuture => isFullDate && toDateTime().isFuture;

  bool get hasMonth => month != null;

  bool get hasYear => year != null;

  bool get hasDay => day != null;

  @override
  String toString() => Lists.compact([year, month, day])
      .map((part) => part! < 10 ? "0$part" : "$part")
      .join("-");

  int millisecondsSinceEpoch([Location? location]) {
    return toDateTime(location).millisecondsSinceEpoch;
  }

  DateTime toDateTime([Location? location]) {
    if (location != null) {
      return TZDateTime(location, year ?? 1971, month ?? 1, day ?? 1);
    } else {
      return DateTime(year ?? 1971, month ?? 1, day ?? 1);
    }
  }

  DateComponents withoutDay() =>
      DateComponents(day: null, month: month, year: year);

  DateComponents withoutYear() =>
      DateComponents(day: day, month: month, year: null);

  @override
  List<Object?> get props => [year, month, day];
}

int? _tryParseInt(dyn) {
  if (dyn == null) return null;
  return int.tryParse("$dyn");
}

const kyear = 'year';
const kmonth = 'month';
const kday = 'day';

DateTime withoutTime(DateTime time) =>
    DateTime(time.year, time.month, time.day, 0, 0, 0, 0, 0);

bool hasTime(DateTime time) =>
    time.second != 0 ||
    time.minute != 0 ||
    time.hour != 0 ||
    time.millisecond != 0;

bool isFuture(DateTime? time) => time?.isAfter(DateTime.now()) == true;

bool isPast(DateTime? time) => time?.isBefore(DateTime.now()) == true;

extension DateComponentsComparisons on DateComponents {
  bool isSameMonth(DateTime date) {
    return this.month == date.month && this.year == date.year;
  }
}
