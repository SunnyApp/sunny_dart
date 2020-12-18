import 'package:sunny_dart/time/time_span.dart';

DateTime dateTimeOf(json) {
  if (json == null) return null;
  return DateTime.parse(json.toString());
}

Uri uriOf(json) {
  if (json == null) return null;
  return Uri.parse(json.toString());
}

TimeSpan timeSpanOf(String duration) {
  return TimeSpan.ofISOString(duration);
}
