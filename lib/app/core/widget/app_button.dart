import 'package:chys/app/core/const/app_text.dart';
import 'package:flutter/material.dart';

class Appbutton extends StatelessWidget {
  final String? label;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final Color? textColor;
  final double borderRadius;
  final FontWeight? fontWeight;
  final double fontSize;

  const Appbutton({
    Key? key,
    this.label,
    this.onPressed,
    this.width = 150,
    this.height = 56,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.5,
    this.textColor,
    this.borderRadius = 32.0,
    this.fontWeight,
    this.fontSize = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color bg = backgroundColor ?? Colors.transparent;
    final Color txtColor = textColor ?? Colors.black;
    final Color brdColor = borderColor ?? Colors.black;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: brdColor, width: borderWidth ?? 0),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: AppText(
          text:
          label ?? '',

            color: txtColor,
            fontSize: fontSize,
            fontWeight: fontWeight ?? FontWeight.w600,

        ),
      ),
    );
  }
}
