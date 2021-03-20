import 'dart:async';

import 'package:sunny_dart/helpers/strings.dart';

import '../extensions.dart';

enum BuildMode { release, profile, debug }

class DeviceInfo {
  final bool isSimulator;
  final String deviceId;
  final String deviceType;
  final String? deviceBrand;
  final String? software;
  final String? deviceModel;
  final String? softwareVersion;
  final String locale;
  final String language;
  final String? ipAddress;
  final GeoPoint? geo;

  const DeviceInfo(
      {required this.isSimulator,
      required this.ipAddress,
      required this.geo,
      required this.deviceId,
      required this.deviceType,
      required this.deviceModel,
      required this.deviceBrand,
      required this.software,
      required this.locale,
      required this.language,
      required this.softwareVersion});

  DeviceInfo.unknown(
      {required this.language,
      required this.locale,
      this.ipAddress,
      this.geo,
      required this.isSimulator})
      : deviceBrand = null,
        deviceType = "Unknown",
        deviceModel = null,
        software = null,
        deviceId = uuid(),
        softwareVersion = null;

  Map<String, dynamic> toMap() {
    return {
      'isSimulator': this.isSimulator,
      'locale': this.locale,
      'language': this.language,
      'deviceId': this.deviceId,
      'geo': this.geo?.toMap(),
      'ipAddress': this.ipAddress,
      'deviceType': this.deviceType,
      'software': this.software,
      'deviceBrand': this.deviceBrand,
      'deviceModel': this.deviceModel,
      'softwareVersion': this.softwareVersion,
    }.valuesNotNull();
  }

  dynamic toJson() => toMap();
}

extension PlatformInfoFuture on FutureOr<DeviceInfo> {
  DeviceInfo get() {
    assert(this is! Future<DeviceInfo>, "PlatformInfo is not resolved yet.");
    return this as DeviceInfo;
  }

  Future<String?> get ipAddress async => (await this).ipAddress;
  Future<bool> get isSimulator async => (await this).isSimulator;

  Future<String> get deviceUUID async => (await this).deviceId;

  Future<String> get deviceType async => (await this).deviceType;

  Future<String?> get deviceBrand async => (await this).deviceBrand;

  Future<String> get locale async => (await this).locale;

  Future<String> get language async => (await this).language;

  Future<String?> get deviceModel async => (await this).deviceModel;

  Future<String?> get softwareVersion async => (await this).softwareVersion;
  Future<GeoPoint> get location async => (await this).location;
}

class GeoPoint {
  final double? lat;
  final double? lon;

  static GeoPoint? of(double? lat, double? lon) {
    if (lat == null || lon == null) return null;
    return GeoPoint(lat, lon);
  }

  GeoPoint(this.lat, this.lon);

  factory GeoPoint.fromMap(Map<String, dynamic> map) {
    return GeoPoint(
      map['lat'] as double?,
      map['lon'] as double?,
    );
  }

  Map<String, dynamic> toMap() {
    // ignore: unnecessary_cast
    return {
      'lat': this.lat,
      'lon': this.lon,
    } as Map<String, dynamic>;
  }
}
