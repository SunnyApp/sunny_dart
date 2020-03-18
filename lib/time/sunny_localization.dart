import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:logging/logging.dart';
import 'package:sunny_dart/time/time_span.dart';
import 'package:timezone/timezone.dart';

import '../helpers.dart';

Location locationOf(name) {
  return SunnyLocalization.getLoc(name?.toString());
}

TimeZone timeZoneOf(name) {
  return SunnyLocalization.getTimeZoneSync(name?.toString());
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

class SunnyLocalization {
  static Location _userLocation;
  static Logger log = Logger("sunny_localization");

  static set userLocation(Location location) {
    if (location != null && location != _userLocation) {
      log.info("User location set to $location");
      log.info("User timezone set to ${location.currentTimeZone}");
      _userLocation = location;
      setLocalLocation(_userLocation);
    }
  }

  static Future<String> getNativeTimeZone() async {
    if (kIsWeb) return "America/Chicago";
    return await FlutterNativeTimezone.getLocalTimezone();
  }

  static Future<Location> get userLocationAsync async {
    final timeZoneName = await getNativeTimeZone();
    return userLocation = await SunnyLocalization.getLocAsync(timeZoneName);
  }

  static TimeZone get userTimeZone {
    return userLocation.currentTimeZone;
  }

  static Location get userLocation {
    if (_userLocation == null) {
      userLocationAsync.then((_) {});
      log.warning("Time zone not loaded yet.  Returning fallback of UTC");
      return UTC;
    }
    return _userLocation;
  }

  static FutureOr<TimeZone> getTimeZone(String name) {
    if (!_loaded) {
      return _loadTimeZoneData().then((_) => getLocation(name).currentTimeZone);
    }
    return getLocation(name).currentTimeZone;
  }

  static Future _loadTimeZoneData() {
    if (!_loaded) {
      return rootBundle.load('packages/timezone/data/latest.tzf').then((byteData) {
        final rawData = byteData.buffer.asUint8List();
        initializeDatabase(rawData);
        _loaded = true;
      });
    } else {
      return Future.value(true);
    }
  }

  static TimeZone getTimeZoneSync(String name) {
    if (!_loaded) {
      _loadTimeZoneData();
      throw illegalState("Timezones not loaded");
    }
    return getLocation(name).currentTimeZone;
  }

  static FutureOr<Location> getLocAsync(String name) {
    if (!_loaded) {
      return rootBundle.load('packages/timezone/data/latest.tzf').then((byteData) {
        final rawData = byteData.buffer.asUint8List();
        initializeDatabase(rawData);
        _loaded = true;
        return getLocation(name);
      });
    }
    return getLocation(name);
  }

  static Location getLoc(String name) {
    if (!_loaded) {
      rootBundle.load('packages/timezone/data/latest.tzf').then((byteData) {
        final rawData = byteData.buffer.asUint8List();
        initializeDatabase(rawData);
        _loaded = true;
        return getLocation(name);
      });
      log.warning("Locations not loaded.  Returning default");
      return UTC;
    }
    return getLocation(name);
  }

  static bool _loaded = false;
  static final locations = SunnyLocalization._();

  SunnyLocalization._() {
    initialize();
  }

  static Future initialize() {
    return getNativeTimeZone().then((timezone) {
      if (_userLocation == null) {
        SunnyLocalization.userLocationAsync.then((_) {});
      }
    });
  }
}
