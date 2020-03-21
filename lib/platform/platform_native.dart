import 'dart:io';

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
