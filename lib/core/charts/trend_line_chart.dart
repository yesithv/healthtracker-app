import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/theme_context.dart';

/// Helpers compartidos para las gráficas de línea de los historiales.
///
/// Signos vitales ya tenía estos ayudantes (`_gridData`, `_axisTitles`,
/// `_lineBar`, `_dotPainter`) como métodos privados; antropometría los repetía en
/// línea dentro de su `LineChart`. Aquí viven una sola vez y toman el `ThemeData`
/// como argumento para que cualquier `chartBuilder` los use sin volver a copiarlos.

/// Rejilla horizontal (sin líneas verticales) del color de divisor del tema.
FlGridData trendGridData(ThemeData theme) => FlGridData(
  show: true,
  drawVerticalLine: false,
  getDrawingHorizontalLine: (value) =>
      FlLine(color: theme.surfaces.divider, strokeWidth: 1),
);

/// Ejes comunes: fechas muestreadas abajo (una etiqueta cada [labelStep] más la
/// última) y el valor numérico a la izquierda con paso [leftInterval].
///
/// Se pasa [dates] (y no una lista de registros de un tipo concreto) para que el
/// helper sirva a cualquier indicador. [yDecimals] rotula el eje izquierdo: 0
/// para IMC/perímetros/vitales, 2 para los ratios (ICA/ICC).
FlTitlesData trendAxisTitles(
  ThemeData theme, {
  required List<DateTime> dates,
  required DateFormat fmt,
  required int labelStep,
  required double leftInterval,
  int yDecimals = 0,
}) {
  return FlTitlesData(
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 30,
        interval: 1,
        getTitlesWidget: (value, meta) {
          final index = value.toInt();
          final isLast = index == dates.length - 1;
          // Solo una etiqueta cada `labelStep` (más la última) para no
          // amontonarlas cuando hay muchos puntos.
          if (index >= 0 &&
              index < dates.length &&
              (index % labelStep == 0 || isLast)) {
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                fmt.format(dates[index]),
                style: theme.type.numeralUnit.copyWith(fontSize: 10),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    ),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 30,
        interval: leftInterval,
        getTitlesWidget: (value, meta) => Text(
          value.toStringAsFixed(yDecimals),
          style: theme.type.numeralUnit.copyWith(fontSize: 10),
        ),
      ),
    ),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  );
}

/// Pinta cada punto de una serie. Los índices en [flagged] (lecturas con contexto
/// relevante, p. ej. un síntoma) salen como un círculo ÁMBAR más grande con un aro
/// del color de la tarjeta; el resto, el punto normal del color [base].
FlDotPainter Function(FlSpot, double, LineChartBarData, int) trendDotPainter(
  ThemeData theme,
  Color base, {
  Set<int> flagged = const {},
}) {
  final marker = theme.clinical.caution.accent;
  final ring = theme.surfaces.card;
  return (spot, percent, bar, i) => flagged.contains(i)
      ? FlDotCirclePainter(
          radius: 5,
          color: marker,
          strokeColor: ring,
          strokeWidth: 2,
        )
      : FlDotCirclePainter(radius: 4, color: base, strokeWidth: 0);
}

/// Serie de línea con puntos, del color dado. [flagged] marca las lecturas con
/// contexto; [belowBarData] pinta el relleno bajo la línea; [isCurved] la curva
/// (vitales sí, antropometría no).
LineChartBarData trendLineBar(
  ThemeData theme,
  List<FlSpot> spots,
  Color color, {
  bool isCurved = true,
  Set<int> flagged = const {},
  BarAreaData? belowBarData,
}) {
  return LineChartBarData(
    spots: spots,
    isCurved: isCurved,
    color: color,
    barWidth: theme.surfaces.chartLineWidth,
    isStrokeCapRound: true,
    dotData: FlDotData(
      show: true,
      getDotPainter: trendDotPainter(theme, color, flagged: flagged),
    ),
    belowBarData: belowBarData ?? BarAreaData(),
  );
}
