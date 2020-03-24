import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:sunny_dart/helpers/failures.dart';
import 'package:sunny_dart/helpers/lists.dart';

import '../extensions.dart';

final _log = Logger("dateComponents");

/// A flexible container for date components that provides a robust parsing/building mechanism.  If the input type is known
/// to be a [Map] or [DateTime], then use the corresponding constructors.
///
/// [DateComponents.tryParse] will / attempt to construct a [DateComponents] instance, and will return `null` if none could be constructed.
/// [DateComponents.parse] will / attempt to construct a [DateComponents] instance, and will raise an exception if unable to create a [DateComponents] instance
///
class DateComponents {
  int day;
  int month;
  int year;

  DateComponents({this.day, this.month = 1, this.year});

  factory DateComponents.fromDateTime(DateTime dateTime) {
    if (dateTime == null) return null;
    return DateComponents(day: dateTime?.day, month: dateTime?.month, year: dateTime?.year);
  }

  DateComponents.fromMap(Map toParse)
      : day = _tryParseInt(toParse[kday]),
        month = _tryParseInt(toParse[kmonth]),
        year = _tryParseInt(toParse[kyear]);

  factory DateComponents.tryParse(input) {
    try {
      return DateComponents.parse(input);
    } catch (e) {
      _log.finer("Date parse error: $e");
      return null;
    }
  }

  factory DateComponents.parse(toParse) {
    assert(toParse != null, "Input must not be null");
    if (toParse is DateComponents) return toParse;
    if (toParse is DateTime) return DateComponents.fromDateTime(toParse);
    if (toParse is Map) return DateComponents.fromMap(toParse);

    final parseAttempt = DateTime.tryParse("$toParse".trim());
    if (parseAttempt != null) {
      return DateComponents.fromDateTime(parseAttempt);
    }

    final input = "$toParse";
    final tokenized = tokenizeString(input, splitAll: true);
    final parts = tokenized
            ?.map((value) {
              if (value.isNumeric) {
                return value;
              } else {
                final month = DateFormat.MMMM().parseLoose(value);
                return "${month.month}";
              }
            })
            ?.map((value) => value.startsWith("0") ? value.substring(1) : value)
            ?.map((value) => int.tryParse(value))
            ?.toList() ??
        [];

    final length = parts.length;
    switch (length) {
      case 3:
        if (parts[0] > 1000) {
          return DateComponents(year: parts[0], month: parts[1], day: parts[2]);
        } else if (parts[2] > 1000) {
          return DateComponents(year: parts[2], month: parts[0], day: parts[1]);
        } else {
          return illegalState("Invalid date - can't find year");
        }
        break;
      case 2:
        if (parts[0] > 1000) {
          return DateComponents(year: parts[0], month: parts[1]);
        } else if (parts[1] > 1000) {
          return DateComponents(year: parts[1], month: parts[0]);
        } else {
          return DateComponents(month: parts[0], day: parts[1]);
        }
        break;
      case 1:
        if (parts[0] < 1000) return null;
        return DateComponents(year: parts[0]);
      default:
        return null;
    }
  }

  factory DateComponents.fromJson(json) {
    return DateComponents.parse(json);
  }

  toJson() {
    return "$this";
  }

  bool get isFullDate => year != null;

  bool get isFuture => isFullDate && toDateTime().isFuture;

  bool get hasMonth => month != null;

  bool get hasYear => year != null;

  bool get hasDay => day != null;

  @override
  String toString() => Lists.compact([year, month, day]).map((part) => part < 10 ? "0$part" : "$part").join("-");

  DateTime toDateTime() => DateTime(year ?? 1971, month ?? 1, day ?? 1);

  DateComponents withoutDay() => DateComponents(day: null, month: month, year: year);

  DateComponents withoutYear() => DateComponents(day: day, month: month, year: null);

  factory DateComponents.now() => DateComponents.fromDateTime(DateTime.now());
}

int _tryParseInt(dyn) {
  if (dyn == null) return null;
  return int.tryParse("$dyn");
}

const kyear = 'year';
const kmonth = 'month';
const kday = 'day';
