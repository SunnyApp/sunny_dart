import 'package:sunny_dart/extensions.dart';
import 'package:sunny_dart/time/time_span.dart';

List<TimeSpan> parseTimeSpans(String query) {
  var q = query.orEmpty().toLowerCase();
  Iterable<TimeSpan> results;
  if (q.isNumeric || q.contains(":")) {
    final parts = q
        .split(":")
        .map((p) {
          return (p.ifBlank("00")).toInt();
        })
        .toList()
        .reversed
        .toList();
    int seconds = parts.tryGet(0) ?? 0;
    int minutes = parts.tryGet(1) ?? 0;
    int hours = parts.tryGet(2) ?? 0;
    results = [TimeSpan(seconds: seconds, minutes: minutes, hours: hours)];
  } else {
    q = q
        .replaceAll("one", "1")
        .replaceAll("other", "2")
        .replaceAll("third", "3")
        .replaceAll("two", "2")
        .replaceAll("three", "3")
        .replaceAll("four", "4")
        .replaceAll("five", "5")
        .replaceAll("six", "6")
        .replaceAll("seven", "7")
        .replaceAll("eight", "8")
        .replaceAll("nine", "9")
        .replaceAll("ten", "10");

    final words = q.split(" ");
    final iter = words.iterator;

    while (iter.moveNext()) {
      final match = spanRegex.firstMatch(iter.current);
      final iterMatches = <TimeSpan>[];
      final knownUnits = knownSpans[iter.current];
      if (match != null) {
        final amount = match.group(1).toDoubleOrNull();
        if (amount != null) {
          final period = match.group(2);
          iterMatches.addAll(tryParseTimeSpanUnit(period).map((unit) {
            return TimeSpan.ofSingleField(unit, amount);
          }));
        }
      } else if (knownUnits != null) {
        iterMatches.add(knownUnits);
      } else {
        final amount = iter.current.toIntOrNull();
        if (amount == null) {
          tryParseTimeSpanUnit(iter.current).forEach((unit) {
            iterMatches.add(TimeSpan.ofSingleField(unit, 1));
          });
        } else {
          if (iter.moveNext()) {
            final dest = iter.current;
            iterMatches.addAll(tryParseTimeSpanUnit(dest)
                .map((unit) => TimeSpan.ofSingleField(unit, amount)));
          }
        }
      }
      if (iterMatches.isEmpty) continue;
      if (results == null) {
        results = [...iterMatches];
      } else {
        results = results.expand((result) => iterMatches.map((parsed) {
              return result + parsed;
            }));
      }
    }
  }
  return [...?results];
}
