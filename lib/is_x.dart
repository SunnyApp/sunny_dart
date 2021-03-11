import 'xfo/info_x.dart';
import 'xfo/sunny_get.dart';
export 'xfo/info_x.dart';

/// Makes it easier to import
class IsX {}

@deprecated
SunnyGet get Sunny => sunny;

/// Use infoX.isIOS
@deprecated
bool get isIOS => infoX.isIOS;

@deprecated
bool get isAndroid => infoX.isAndroid;

@deprecated
bool get isMacOS => infoX.isMacOS;

@deprecated
bool get isWindows => infoX.isWindows;

@deprecated
bool get isLinux => infoX.isLinux;

@deprecated
bool get isWeb => infoX.isWeb;

@deprecated
String get operatingSystem => infoX.operatingSystem;

@deprecated
Map<String, String> get environment => infoX.environment;

@deprecated
bool get canReadFiles => infoX.canReadFiles;
