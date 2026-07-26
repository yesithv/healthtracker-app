import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

class DashedBorderContainer extends StatelessWidget {
  final Widget child;
  final Color color;
  final double borderRadius;

  const DashedBorderContainer({
    super.key,
    required this.child,
    required this.color,
    this.borderRadius = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).surfaces.card,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: CustomPaint(
        painter: _DashedRectPainter(color: color, borderRadius: borderRadius),
        child: Padding(padding: const EdgeInsets.all(24.0), child: child),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  _DashedRectPainter({required this.color, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    var rect = Rect.fromLTWH(0, 0, size.width, size.height);
    var rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    var path = Path()..addRRect(rrect);
    var dashedPath = Path();

    double dashWidth = 6.0;
    double dashSpace = 4.0;

    for (var pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        var extractPath = pathMetric.extractPath(
          distance,
          distance + dashWidth,
        );
        dashedPath.addPath(extractPath, Offset.zero);
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
