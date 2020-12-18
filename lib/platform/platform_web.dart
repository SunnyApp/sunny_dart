import 'dart:async';

import 'package:platform_detect/platform_detect.dart';
import 'package:sunny_dart/helpers/strings.dart';
import 'package:sunny_dart/platform/device_info.dart';

bool get isPlatformIOS => false;

bool get isPlatformAndroid => false;

bool get isPlatformMacOS => false;

bool get isPlatformWindows => false;

bool get isPlatformLinux => false;

bool get isPlatformWeb => true;

String get platformName => "web";

Map<String, String> get platformEnvironment => {};

bool get canPlatformReadFiles => false;

Future<DeviceInfo> loadPlatformInfo() async {
  // List languages = await Devicelocale.preferredLanguages;
  // String locale = await Devicelocale.currentLocale;
  return DeviceInfo(
    ipAddress: null,
    isSimulator: false,
    locale: "US",
    language: "en",
    deviceType: "browser",
    software: "browser",
    deviceBrand: browser.name,
    deviceModel: browser.className,
    deviceId: uuid(),
    softwareVersion: "${browser.version}",
  );
}

Future<String> get currentUserTimeZone async {
  return "Chicago/America";
}
