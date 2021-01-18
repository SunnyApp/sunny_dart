import 'package:timezone/timezone.dart';
import '../xfo/sunny_get.dart';

SunnyLocalization get sunnyLocalization => sunny.get();

class SunnyLocalization {
  TimeZone userTimeZone;
  Location userLocation;

  SunnyLocalization({this.userTimeZone, this.userLocation});

  TimeZone timeZoneOf(String name) {
    return getLocation(name).currentTimeZone;
  }

  Location locationOf(String name) {
    return getLocation(name);
  }
}
