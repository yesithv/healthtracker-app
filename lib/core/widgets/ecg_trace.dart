import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

/// El electro de la marca, en los dos acabados que admite el sistema.
///
/// Vive aquí porque lo usan el arranque y la portada de bienvenida, y hasta
/// ahora cada una arrastraba su propia copia del `CustomPainter` —con la misma
/// función de onda escrita dos veces y dos criterios distintos de color—.
///
/// Qué acabado se dibuja lo dice el tema, no la pantalla:
/// `AppSurfaces.monitorBezel` decide si el trazo va enmarcado en cromo de
/// instrumental (bisel oscuro, rejilla y halo) o desnudo sobre el fondo, y
/// `dataStroke` / `chartLineWidth` ponen el color y el grosor.
class EcgTrace extends StatefulWidget {
  const EcgTrace({
    super.key,
    this.width = 240,
    this.bareHeight = 60,
    this.framedHeight = 140,
  });

  /// Ancho del trazo.
  final double width;

  /// Alto cuando el tema lo pide desnudo.
  final double bareHeight;

  /// Alto cuando el tema lo enmarca en un monitor.
  final double framedHeight;

  @override
  State<EcgTrace> createState() => _EcgTraceState();
}

class _EcgTraceState extends State<EcgTrace>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    final bezel = surfaces.monitorBezel;

    final trace = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        painter: EcgPainter(
          progress: _controller.value,
          color: surfaces.dataStroke,
          strokeWidth: surfaces.chartLineWidth,
          // Rejilla y halo son cromo de instrumental: acompañan al bisel.
          showGrid: bezel,
          glow: bezel,
        ),
        child: const SizedBox.expand(),
      ),
    );

    if (!bezel) {
      // Temas planos: el trazo respira sobre el lienzo de marca.
      return SizedBox(width: widget.width, height: widget.bareHeight, child: trace);
    }

    return Container(
      width: widget.width,
      height: widget.framedHeight,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        // Interior de la pantalla del monitor: constante del propio idioma de
        // instrumental, no de la paleta. Un monitor apagado es negro en
        // cualquier tema.
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(surfaces.radiusCard),
        border: Border.all(
          color: surfaces.onBrand.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: surfaces.onBrand.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: surfaces.dataStroke.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(surfaces.radiusCard - 4),
        child: trace,
      ),
    );
  }
}

/// Dibuja un latido que se desplaza. Público para que las pruebas puedan
/// instanciarlo sin pasar por el widget.
class EcgPainter extends CustomPainter {
  EcgPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 2.5,
    this.showGrid = true,
    this.glow = true,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  /// Rejilla de fondo estilo papel de electro.
  final bool showGrid;

  /// Halo alrededor del trazo, como el fósforo de un monitor.
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) _drawGrid(canvas, size);

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final midY = size.height / 2;

    for (double x = 0; x <= size.width; x++) {
      final relativeX = (x / size.width + (1 - progress)) % 1.0;
      // La amplitud escala con la altura disponible: el mismo trazo sirve para
      // el monitor de 140 px y para la línea desnuda de 60 px.
      final y = midY + _ecgHeight(relativeX * 10) * (size.height * 0.29);
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    if (glow) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = strokeWidth * 2.4
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawPath(path, glowPaint);
    }
  }

  /// Forma de onda de un latido, normalizada. El tramo P-QRS-T ocupa los
  /// primeros 3,5 de cada 10 unidades; el resto es línea de base.
  double _ecgHeight(double t) {
    t = t % 10;
    if (t < 0.5) return 0;
    if (t < 1.0) return -0.2 * math.sin((t - 0.5) * 2 * math.pi);
    if (t < 1.5) return 0;
    if (t < 1.6) return 0.2 * (t - 1.5) * 10;
    if (t < 1.8) return -1.5 * math.sin((t - 1.6) * 5 * math.pi / 2);
    if (t < 2.0) return 0.5 * math.sin((t - 1.8) * 5 * math.pi / 2);
    if (t < 2.5) return 0;
    if (t < 3.5) return -0.4 * math.sin((t - 2.5) * math.pi);
    return 0;
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;
    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(EcgPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.showGrid != showGrid ||
      old.glow != glow;
}
