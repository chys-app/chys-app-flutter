import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomSvgIcon extends StatelessWidget {
  final String assetName;
  final Color? color;
  final double? width;
  final double? height;

  const CustomSvgIcon({
    super.key,
    required this.assetName,
    this.color,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: SvgPicture.asset(
        assetName,
        colorFilter:
            color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
        fit: BoxFit.contain, // Ensure proper scaling
      ),
    );
  }
}
