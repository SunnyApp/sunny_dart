import 'package:flutter/rendering.dart';

extension TextStyleExtensions on TextStyle {
  TextStyle transparent([double opacity = 0.0]) {
    return this.copyWith(color: this.color.withOpacity(opacity));
  }
}
