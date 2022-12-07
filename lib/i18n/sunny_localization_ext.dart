import 'package:info_x/info_x.dart';
import 'package:timezone/timezone.dart';

extension SunnyLocalizationExt on Future<SunnyLocalization> {
  Future<TimeZone> get userTimeZone => then((_) => _.userTimeZone!);
  Future<Location> get userLocation => then((_) => _.userLocation!);
}

extension LocalizationDateTimeExt on DateTime {
  TZDateTime withTimeZone([Location? location]) {
    if (this is TZDateTime) return (this as TZDateTime);
    return TZDateTime.from(this, location ?? sunnyLocalization.userLocation!);
  }
}

Location locationOf(name) {
  return sunnyLocalization.locationOf(name!.toString());
}

TimeZone timeZoneOf(name) {
  return sunnyLocalization.timeZoneOf(name!.toString());
}
