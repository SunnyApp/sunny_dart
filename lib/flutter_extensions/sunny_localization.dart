import 'dart:async';

import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart';

import '../platform/platform_interface.dart'
    if (dart.library.io) '../platform/platform_native.dart'
    if (dart.library.js) '../platform/platform_web.dart';

Future initializeTimeZones() async {
  final byteData = await rootBundle.load('packages/timezone/data/latest.tzf');
  final rawData = byteData.buffer.asUint8List();
  initializeDatabase(rawData);
}

Completer<SunnyLocalization> _sunnyLocalizationCompleter;
Future<SunnyLocalization> get sunnyLocalizationFuture {
  if (_sunnyLocalizationCompleter != null) {
    return _sunnyLocalizationCompleter.future;
  } else {
    return _loadSunnyLocalization();
  }
}

Location locationOf(name) {
  return sunnyLocalization.locationOf(name?.toString());
}

TimeZone timeZoneOf(name) {
  return sunnyLocalization.timeZoneOf(name?.toString());
}

SunnyLocalization _sunnyLocalization;
SunnyLocalization get sunnyLocalization {
  assert(_sunnyLocalization != null,
      "Sunny localization has not been initialized yet");
  return _sunnyLocalization;
}

Future<SunnyLocalization> _loadSunnyLocalization() async {
  _sunnyLocalizationCompleter ??= Completer<SunnyLocalization>();
  if (_sunnyLocalization != null) return _sunnyLocalization;
  final userTimeZoneName = await currentUserTimeZone;

  final userLocation = getLocation(userTimeZoneName);
  final userTimeZone = userLocation.currentTimeZone;
  _sunnyLocalization = SunnyLocalization(userTimeZone, userLocation);
  _sunnyLocalizationCompleter.complete(_sunnyLocalization);
  return _sunnyLocalization;
}

class SunnyLocalization {
  final TimeZone userTimeZone;
  Location userLocation;

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

  static void setUserLocation(Location location) {
    _sunnyLocalization.userLocation = location;
  }
}

extension SunnyLocalizationExt on Future<SunnyLocalization> {
  Future<TimeZone> get userTimeZone => then((_) => _.userTimeZone);
  Future<Location> get userLocation => then((_) => _.userLocation);
}

extension LocalizationDateTimeExt on DateTime {
  TZDateTime withTimeZone([Location location]) {
    assert(location != null);
    if (this is TZDateTime) return (this as TZDateTime);
    return TZDateTime.from(
        this, location ?? SunnyLocalization.userLocationOrNull);
  }
}