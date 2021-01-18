import '../i18n/sunny_localization.dart';
import '../platform/device_info.dart';
import 'sunny_get.dart';

InfoX get infoX => sunny.get();

abstract class InfoX {
  Future<SunnyLocalization> initializeLocalization();
  Future<DeviceInfo> loadDeviceInfo();
  Future<DeviceInfo> get deviceInfo;
  Future<String> get currentTimeZone;

  bool get isIOS;

  bool get isAndroid;

  bool get isMacOS;

  bool get isWindows;

  bool get isLinux;

  bool get isWeb;

  String get operatingSystem;

  Map<String, String> get environment;

  bool get canReadFiles;
}
