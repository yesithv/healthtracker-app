import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/charts/chart_series.dart';

/// Mini‑gráfica de tendencia (sparkline) para las tarjetas del inicio.
///
/// Es una línea desnuda —sin ejes, rejilla, etiquetas ni interacción— con un
/// relleno degradado suave y el último punto resaltado, pensada para leerse «de
/// reojo» junto a la cifra: dice hacia dónde va el indicador sin robarle
/// protagonismo al número.
///
/// La serie va en el acento de la FAMILIA (no de un estado): una tendencia no es
/// buena ni mala, solo cuenta el recorrido. Reutiliza [downsample] para que una
/// serie de dos años no dibuje un punto por medición.
class MetricSparkline extends StatelessWidget {
  const MetricSparkline({
    super.key,
    required this.values,
    required this.color,
    this.width = 92,
    this.height = 40,
  });

  /// Valores en orden CRONOLÓGICO (más antiguo primero). El llamante ya filtró
  /// los nulos.
  final List<double> values;

  /// Acento de la familia del indicador.
  final Color color;

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    // Con menos de dos puntos no hay «tendencia» que dibujar.
    if (values.length < 2) return const SizedBox.shrink();

    final pts = downsample(values, maxPoints: 24);
    double minV = pts.first;
    double maxV = pts.first;
    for (final v in pts) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    // Serie plana: se abre un margen simétrico para que la línea quede centrada
    // en vez de pegada a un borde.
    if (minV == maxV) {
      minV -= 1;
      maxV += 1;
    }
    // Aire arriba y abajo para que la línea no toque los bordes del recuadro.
    final pad = (maxV - minV) * 0.15;

    final spots = <FlSpot>[
      for (var i = 0; i < pts.length; i++) FlSpot(i.toDouble(), pts[i]),
    ];
    final lastIndex = pts.length - 1;

    return SizedBox(
      width: width,
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: lastIndex.toDouble(),
          minY: minV - pad,
          maxY: maxV + pad,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.28,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                // Solo el ÚLTIMO punto lleva marcador: es la lectura vigente.
                checkToShowDot: (spot, _) => spot.x == lastIndex.toDouble(),
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: 3,
                      color: color,
                      strokeColor: color,
                      strokeWidth: 0,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.18),
                    color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
