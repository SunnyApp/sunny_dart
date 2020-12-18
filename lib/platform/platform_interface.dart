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
Future<String> get currentUserTimeZone => throw "Not implemented";

Map<String, String> get platformEnvironment => throw "Not implemented";

bool get canPlatformReadFiles => throw "Not implemented";

Future<DeviceInfo> loadPlatformInfo() => throw "Not implemented";
