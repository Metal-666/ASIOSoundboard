import 'package:flutter/material.dart';

extension HexColor on Color {
  /// Converts a hex string to a color.
  ///
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  /// Written by some random guy on StackOverflow. Thanks random guy!
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Converts this color to hex representation.
  ///
  /// Prefixes a hash sign if [leadingHashSign] is set to `true`.
  String toHex({bool leadingHashSign = false}) =>
      '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}

/// These are my text extensions to make styling easier.
extension CustomStyles on TextTheme {
  TextStyle get tile => const TextStyle(fontSize: 20);
}
