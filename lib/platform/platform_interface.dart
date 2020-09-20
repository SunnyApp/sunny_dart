import 'dart:async';
import 'dart:typed_data';

import 'package:sunny_dart/platform/device_info.dart';

/// Since dart:io doesn't work on the web, this library creates an abstraction of the most common access point in io,
/// and causes them to silently fail on the web

bool get isPlatformIOS => throw "Not implemented";

bool get isPlatformAndroid => throw "Not implemented";

bool get isPlatformMacOS => throw "Not implemented";

bool get isPlatformWindows => throw "Not implemented";
bool get isPlatformLinux => throw "Not implemented";
bool get isPlatformWeb => throw "Not implemented";
String get platformName => throw "Not implemented";

Map<String, String> get platformEnvironment => throw "Not implemented";

bool get canPlatformReadFiles => throw "Not implemented";

abstract class File {
  factory File(String path) => throw "Not implemented: $path";
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

Future<DeviceInfo> loadPlatformInfo() => throw "Not implemented";
