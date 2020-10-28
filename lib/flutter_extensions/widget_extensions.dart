import 'package:flutter/material.dart';

extension TextStyleExtensions on TextStyle {
  TextStyle transparent([double opacity = 0.0]) {
    return this.copyWith(color: this.color.withOpacity(opacity));
  }

  TextStyle get white {
    return this.copyWith(color: Colors.white);
  }

  TextStyle scaled(double scaledBy) {
    assert(this.fontSize != null);
    return copyWith(fontSize: fontSize * scaledBy);
  }
}
