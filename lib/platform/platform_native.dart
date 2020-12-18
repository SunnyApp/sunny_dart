import 'dart:async';
import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:get_ip/get_ip.dart';
import 'package:sunny_dart/platform/device_info.dart';
import 'package:timezone/timezone.dart';

import '../extensions.dart';

export 'dart:io';

bool get isPlatformIOS => Platform.isIOS;

bool get isPlatformAndroid => Platform.isAndroid;

bool get isPlatformMacOS => Platform.isMacOS;

bool get isPlatformWindows => Platform.isWindows;

bool get isPlatformLinux => Platform.isLinux;

bool get isPlatformWeb => false;

String get platformName => Platform.operatingSystem;

Map<String, String> get platformEnvironment => Platform.environment;

bool get canPlatformReadFiles => true;

Future<DeviceInfo> loadPlatformInfo() async {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo android;
  IosDeviceInfo ios;
  try {
    android = await deviceInfo.androidInfo;
  } on MissingPluginException {
    // Doesn't exist
  }
  try {
    ios = await deviceInfo.iosInfo;
  } on MissingPluginException {
    // Doesn't exist
  }
  String ip;
  try {
    ip = await GetIp.ipAddress;
  } catch (e) {
    ip = null;
  }

  final languages = (await Devicelocale.preferredLanguages)
      .map((language) => language?.toString())
      .whereNotNull();
  String locale = await Devicelocale.currentLocale;
  if (android != null) {
    return DeviceInfo(
      ipAddress: ip,
      isSimulator: android.isPhysicalDevice != true,
      deviceId: android.androidId,
      locale: locale,
      language: languages?.firstOrNull?.toString(),
      deviceModel: android.device,
      deviceBrand: android.brand,
      softwareVersion: "${android.version}",
      deviceType: "android",
      software: android.version.baseOS,
    );
  } else if (ios != null) {
    return DeviceInfo(
      ipAddress: ip,
      isSimulator: ios.isPhysicalDevice != true,
      deviceId: ios.identifierForVendor,
      deviceModel: ios.model,
      locale: locale,
      language: languages?.firstOrNull,
      deviceBrand: "Apple",
      softwareVersion: "${ios.systemVersion}",
      deviceType: "iOS",
      software: "iOS",
    );
  } else {
    return DeviceInfo.unknown(
      isSimulator: false,
      ipAddress: ip,
      locale: locale,
      language: languages?.firstOrNull?.toString(),
    );
  }
}

// Future initializeTimeZones() async {
//   final byteData = await rootBundle.load('packages/timezone/data/latest.tzf');
//   final rawData = byteData.buffer.asUint8List();
//   initializeDatabase(rawData);
// }

Future<String> get currentUserTimeZone =>
    FlutterNativeTimezone.getLocalTimezone();
