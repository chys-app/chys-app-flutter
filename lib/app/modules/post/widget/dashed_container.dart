import 'dart:ui';

import 'package:flutter/material.dart';

class DashedContainer extends StatelessWidget {
  final Widget child;
  final Color dashColor;
  final double dashWidth;
  final double dashHeight;
  final double spacing;
  final BorderRadius borderRadius;

  const DashedContainer({
    Key? key,
    required this.child,
    this.dashColor = Colors.black,
    this.dashWidth = 5.0,
    this.dashHeight = 1.5,
    this.spacing = 3.0,
    this.borderRadius = BorderRadius.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: dashColor,
        dashWidth: dashWidth,
        dashHeight: dashHeight,
        spacing: spacing,
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashHeight;
  final double spacing;
  final BorderRadius borderRadius;

  _DashedBorderPainter({
    required this.color,
    required this.dashWidth,
    required this.dashHeight,
    required this.spacing,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = dashHeight
      ..style = PaintingStyle.stroke;

    final rect = Offset.zero & size;
    final rRect = borderRadius.toRRect(rect);
    final path = Path()..addRRect(rRect);

    final dashPath = _createDashedPath(path, dashWidth, spacing);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source, double dashWidth, double spacing) {
    final Path dest = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        dest.addPath(
          metric.extractPath(distance, next),
          Offset.zero,
        );
        distance += dashWidth + spacing;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
