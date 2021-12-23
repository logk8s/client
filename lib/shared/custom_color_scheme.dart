import 'package:flutter/material.dart';

extension CustomColorScheme on ColorScheme {
  Color? get editBackground => brightness == Brightness.light
      ? Colors.brown[100]
      : const Color(0x2228a745);
}
