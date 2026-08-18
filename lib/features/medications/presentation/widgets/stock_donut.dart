import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';

/// Anillo de inventario: la fracción de stock que queda, dibujada como un arco
/// sobre un riel. El color del arco lo pasa quien lo usa (azul de marca cuando
/// hay de sobra, ámbar de `caution` cuando está por acabarse), nunca un literal.
class StockDonut extends StatelessWidget {
  const StockDonut({
    super.key,
    required this.value,
    required this.total,
    required this.color,
    this.size = 96,
    this.stroke = 10,
    this.centerTop,
    this.centerBottom,
  });

  final int value;
  final int total;
  final Color color;
  final double size;
  final double stroke;

  /// Texto grande del centro (por defecto, [value]).
  final String? centerTop;

  /// Texto pequeño bajo el número (por defecto, "de [total]").
  final String? centerBottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final fraction = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          fraction: fraction,
          color: color,
          track: surfaces.track,
          stroke: stroke,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerTop ?? '$value',
                style: theme.type.numeral.copyWith(fontSize: size * 0.26),
              ),
              Text(
                centerBottom ?? 'de $total',
                style: theme.type.meta.copyWith(fontSize: size * 0.11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.fraction,
    required this.color,
    required this.track,
    required this.stroke,
  });

  final double fraction;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (fraction <= 0) return;
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, fraction * 2 * math.pi, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.track != track ||
      old.stroke != stroke;
}
