import 'dart:ui';

/// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
Color colorFromHex(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

/// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
String? colorToHex(Color? color, {bool leadingHashSign = true}) {
  if (color == null) return null;
  return '${leadingHashSign ? '#' : ''}'
      '${color.alpha.toRadixString(16)}'
      '${color.red.toRadixString(16)}'
      '${color.green.toRadixString(16)}'
      '${color.blue.toRadixString(16)}';
}
