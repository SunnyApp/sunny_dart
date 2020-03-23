import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sunny_dart/helpers/strings.dart';

import '../extensions.dart';
import 'platform_interface.dart'
    if (dart.library.io) 'platform_native.dart'
    if (dart.library.html) 'platform_web.dart';

enum BuildMode { release, profile, debug }

class DeviceInfo {
  final bool isSimulator;
  final String deviceId;
  final String deviceType;
  final String deviceBrand;
  final String software;
  final String deviceModel;
  final String softwareVersion;
  final String locale;
  final String language;

  const DeviceInfo(
      {@required this.isSimulator,
      @required this.deviceId,
      @required this.deviceType,
      @required this.deviceModel,
      @required this.deviceBrand,
      @required this.software,
      @required this.locale,
      @required this.language,
      @required this.softwareVersion});

  DeviceInfo.unknown(
      {@required this.language,
      @required this.locale,
      @required this.isSimulator})
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
      'deviceType': this.deviceType,
      'software': this.software,
      'deviceBrand': this.deviceBrand,
      'deviceModel': this.deviceModel,
      'softwareVersion': this.softwareVersion,
    }.whereValuesNotNull();
  }

  dynamic toJson() => toMap();
}

FutureOr<DeviceInfo> _deviceInfo;

FutureOr<DeviceInfo> get deviceInfo {
  if (_deviceInfo != null) return _deviceInfo;
  _deviceInfo = loadPlatformInfo().then((_) {
    return _deviceInfo = _;
  });
  return _deviceInfo;
}

set deviceInfo(DeviceInfo info) {
  _deviceInfo = info;
}

extension PlatformInfoFuture on FutureOr<DeviceInfo> {
  DeviceInfo get() {
    assert(this is! Future<DeviceInfo>, "PlatformInfo is not resolved yet.");
    return this as DeviceInfo;
  }

  Future<bool> get isSimulator async => (await this).isSimulator;

  Future<String> get deviceUUID async => (await this).deviceId;

  Future<String> get deviceType async => (await this).deviceType;

  Future<String> get deviceBrand async => (await this).deviceBrand;

  Future<String> get locale async => (await this).locale;

  Future<String> get language async => (await this).language;

  Future<String> get deviceModel async => (await this).deviceModel;

  Future<String> get softwareVersion async => (await this).softwareVersion;
}

const buildMode = const bool.fromEnvironment('dart.vm.product')
    ? BuildMode.release
    : kDebugMode ? BuildMode.debug : BuildMode.profile;
