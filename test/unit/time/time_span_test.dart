import 'package:flutter_test/flutter_test.dart';
import 'package:sunny_dart/time.dart';

void main() {
  test("Simple parse", () {
    final result = TimeSpan.ofISOString("P34D");
    expect(result, equals(TimeSpan(days: 34)));
  });

  test("All Fields", () {
    var str = "-P2Y03M1W23DT13H03M3.011032S";
    final result = TimeSpan.ofISOString(str);
    expect(result.negated, isTrue, reason: "negated");
    expect(result.years, 2, reason: "years");
    expect(result.months, 3, reason: "months");
    expect(result.weeks, 1, reason: "weeks");
    expect(result.days, 23, reason: "days");
    expect(result.hours, 13, reason: "hours");
    expect(result.seconds, 3, reason: "seconds");
    expect(result.millis, 11, reason: "millis");
    expect(result.micros, 32, reason: "micros");
  });

  test("Leap Year Duration", () {
    final oneYear = TimeSpan(years: 1);
    final leapYearDuration = oneYear.toDuration(DateTime(2020, 1, 1));
    expect(leapYearDuration.inDays, equals(366));
  });

  test("Month Duration - Leap Year", () {
    final oneYear = TimeSpan(months: 1);
    final february = oneYear.toDuration(DateTime(2020, 2, 1));
    expect(february.inDays, equals(29));
  });

  test("Month Duration", () {
    final oneYear = TimeSpan(months: 1);
    final february = oneYear.toDuration(DateTime(2019, 2, 1));
    expect(february.inDays, equals(28));
  });

  test("Single Field Second", () {
    final seconds = TimeSpan.ofSingleField(TimeSpanUnit.second, 32.2200142);
    expect(seconds.seconds, equals(32));
    expect(seconds.millis, equals(220));
    expect(seconds.micros, equals(14));
    expect(seconds.secondsDouble, equals(32.2200142));
  });

  test("Single Field Millis", () {
    final seconds = TimeSpan.ofSingleField(TimeSpanUnit.millisecond, 220.199);
    expect(seconds.seconds, equals(0));
    expect(seconds.millis, equals(220));
    expect(seconds.micros, equals(199));
    expect(seconds.secondsDouble, equals(0.220199));
  });

  test("Non Leap Year Duration", () {
    final oneYear = TimeSpan(years: 1);
    final leapYearDuration = oneYear.toDuration(DateTime(2019, 1, 1));
    expect(leapYearDuration.inDays, equals(365));
  });

  test("Format normal", () {
    final span = TimeSpan.ofISOString("P2Y3M1W23DT13H33M55.011932S");
    expect(
        span.format(),
        equals(
            "2 years 3 months 1 week 23 days 13 hours 33 minutes 55 seconds 11 milliseconds 932 microseconds"));
  });

  test("Format condensed", () {
    final span = TimeSpan.ofISOString("P2Y3M1W23DT13H33M55.011932S");
    expect(
        span.formatCondensed(), equals("2y 3m 1w 23d 13h 33m 55s 11ms 932ns"));
  });

  test("Seconds Handling", () {
    final span = TimeSpan(
      years: 2,
      months: 3,
      weeks: 1,
      days: 23,
      hours: 13,
      minutes: 33,
      seconds: 55,
      millis: 11,
      micros: 932,
    );
    expect(span.seconds, equals(55));
    expect(span.millis, equals(11));
    expect(span.micros, equals(932));
    expect(span.secondsDouble, equals(55.011932));
  });
}
