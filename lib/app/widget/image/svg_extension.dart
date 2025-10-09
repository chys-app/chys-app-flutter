import 'package:flutter/material.dart';

import 'custom_svg_image.dart';

extension SvgExtension on String {
  /// Returns a CustomSvgIcon with optional color, width, and height
  Widget toSvg({
    Color? color,
    double? width,
    double? height,
  }) {
    return CustomSvgIcon(
      assetName: this,
      color: color,
      width: width,
      height: height,
    );
  }
}
