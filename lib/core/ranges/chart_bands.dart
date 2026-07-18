import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'reference_ranges_store.dart';

/// Colores por banda — la MISMA paleta semántica de los clasificadores/semáforo.
const Map<String, Color> _bandColors = {
  'VERY_LOW': Color(0xFF3B82F6),
  'LOW': Color(0xFF3B82F6),
  'UNDERWEIGHT': Color(0xFF3B82F6),
  'NEAR_OPTIMAL': Color(0xFF3B82F6),
  'NORMAL': Color(0xFF10B981),
  'OPTIMAL': Color(0xFF10B981),
  'PROTECTIVE': Color(0xFF10B981),
  'DESIRABLE': Color(0xFF10B981),
  'ELEVATED': Color(0xFFF59E0B),
  'BORDERLINE': Color(0xFFF59E0B),
  'OVERWEIGHT': Color(0xFFF59E0B),
  'PREDIABETES': Color(0xFFF59E0B),
  'HIGH': Color(0xFFF59E0B),
  'VERY_HIGH': Color(0xFFEF4444),
  'OBESE': Color(0xFFEF4444),
};

Color _colorFor(String bandCode) =>
    _bandColors[bandCode.toUpperCase()] ?? const Color(0xFF94A3B8);

/// Zonas de color de fondo para la gráfica de [indicatorCode]: las bandas del
/// servidor (dispositivo/sexo/edad del paciente, [ReferenceRangesStore]) recortadas
/// al dominio visible [minY, maxY]. Sin rangos aplicables → sin zonas (gráfica
/// normal): la interpretación NUNCA se inventa en el cliente.
RangeAnnotations bandRangeAnnotations(
  String indicatorCode, {
  required double minY,
  required double maxY,
  double opacity = 0.08,
}) {
  final bands = ReferenceRangesStore.instance.bandsOf(indicatorCode);
  final zones = <HorizontalRangeAnnotation>[];
  for (final b in bands) {
    final lo = b.minValue < minY ? minY : b.minValue;
    final hi = b.maxValue > maxY ? maxY : b.maxValue;
    if (hi <= lo) continue;
    zones.add(HorizontalRangeAnnotation(
      y1: lo,
      y2: hi,
      color: _colorFor(b.bandCode).withValues(alpha: opacity),
    ));
  }
  return RangeAnnotations(horizontalRangeAnnotations: zones);
}
