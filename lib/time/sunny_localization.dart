import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:sunny_dart/time/time_span.dart';
import 'package:timezone/timezone.dart';

Location locationOf(name) {
  return sunnyLocalization.locationOf(name?.toString());
}

TimeZone timeZoneOf(name) {
  return sunnyLocalization.timeZoneOf(name?.toString());
}

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

Completer<SunnyLocalization> _sunnyLocalizationCompleter;
Future<SunnyLocalization> get sunnyLocalizationFuture {
  if (_sunnyLocalizationCompleter != null) {
    return _sunnyLocalizationCompleter.future;
  } else {
    return _loadSunnyLocalization();
  }
}

SunnyLocalization _sunnyLocalization;
SunnyLocalization get sunnyLocalization {
  assert(_sunnyLocalization != null, "Sunny localization has not been initialized yet");
  return _sunnyLocalization;
}

Future<SunnyLocalization> _loadSunnyLocalization() async {
  _sunnyLocalizationCompleter ??= Completer<SunnyLocalization>();
  if (_sunnyLocalization != null) return _sunnyLocalization;
  final userTimeZoneName = (kIsWeb) ? "America/Chicago" : await FlutterNativeTimezone.getLocalTimezone();
  final byteData = await rootBundle.load('packages/timezone/data/latest.tzf');
  final rawData = byteData.buffer.asUint8List();
  initializeDatabase(rawData);
  final userLocation = getLocation(userTimeZoneName);
  final userTimeZone = userLocation.currentTimeZone;
  _sunnyLocalization = SunnyLocalization(userTimeZone, userLocation);
  _sunnyLocalizationCompleter.complete(_sunnyLocalization);
  return _sunnyLocalization;
}

class SunnyLocalization {
  final TimeZone userTimeZone;
  final Location userLocation;

  SunnyLocalization(this.userTimeZone, this.userLocation);

  TimeZone timeZoneOf(String name) {
    return getLocation(name).currentTimeZone;
  }

  Location locationOf(String name) {
    return getLocation(name);
  }

  static TimeZone get userTimeZoneOrNull {
    return _sunnyLocalization?.userTimeZone;
  }

  static Location get userLocationOrNull {
    return _sunnyLocalization?.userLocation;
  }
}

extension SunnyLocalizationExt on Future<SunnyLocalization> {
  Future<TimeZone> get userTimeZone => then((_) => _.userTimeZone);
  Future<Location> get userLocation => then((_) => _.userLocation);
}
