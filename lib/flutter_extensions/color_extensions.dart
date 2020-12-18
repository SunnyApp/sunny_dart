import 'dart:ui';
import 'colors.dart';

extension StringToColorExtensions on String {
  Color toColor() => colorFromHex(this);
}
