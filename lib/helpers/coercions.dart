import 'package:flexidate/flexidate.dart';

DateTime? dateTimeOf(json) {
  if (json == null) return null;
  if (json is num) {
    DateTime.fromMillisecondsSinceEpoch(json.toInt(), isUtc: true);
  } else {
    return DateTime.parse(json.toString());
  }
  return null;
}

Uri? uriOf(json) {
  if(json is Uri) return json;
  if (json == null) return null;
  return Uri.parse(json.toString());
}

TimeSpan? timeSpanOf(String duration) {
  return TimeSpan.ofISOString(duration);
}
