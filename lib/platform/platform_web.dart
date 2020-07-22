import 'dart:async';
import 'dart:typed_data';

import 'package:devicelocale/devicelocale.dart';
import 'package:platform_detect/platform_detect.dart';
import 'package:sunny_dart/helpers/strings.dart';
import 'package:sunny_dart/platform/device_info.dart';

import '../extensions.dart';

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
  List languages = await Devicelocale.preferredLanguages;
  String locale = await Devicelocale.currentLocale;
  return DeviceInfo(
    ipAddress: null,
    isSimulator: buildMode == BuildMode.debug,
    locale: locale,
    language: languages?.firstOrNull?.toString(),
    deviceType: "browser",
    software: "browser",
    deviceBrand: browser.name,
    deviceModel: browser.className,
    deviceId: uuid(),
    softwareVersion: "${browser.version}",
  );
}

abstract class File {
  factory File(String path) => _HtmlNoopFile(path);
  File get absolute;
  bool existsSync();
  String readAsStringSync();
  void writeAsStringSync(String data);
  Uint8List readAsBytesSync();
  int lengthSync();
  Stream<List<int>> openRead();
  String get path;
  void writeAsBytesSync(List<int> bytes, {bool flush = false});
}

class _HtmlNoopFile implements File {
  @override
  final String path;

  _HtmlNoopFile(this.path);

  @override
  File get absolute => this;

  @override
  bool existsSync() {
    return false;
  }

  @override
  int lengthSync() {
    return 0;
  }

  @override
  Stream<List<int>> openRead() {
    return Stream.empty();
  }

  @override
  Uint8List readAsBytesSync() {
    return null;
  }

  @override
  String readAsStringSync() {
    return null;
  }

  @override
  void writeAsBytesSync(List<int> bytes, {bool flush = false}) {}

  @override
  void writeAsStringSync(String data, {bool flush}) {}
}
