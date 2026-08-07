import 'package:myvitals_healthtracker_app/core/charts/chart_series.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/anthropometric_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/body_composition_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/lipid_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/vital_sign_record.dart';

/// Agregación PURA para el PDF consolidado de historia clínica.
///
/// Vive APARTE de la construcción del PDF y de los widgets —Dart puro, sin
/// `BuildContext` ni el paquete `pdf`— por la misma razón que
/// `chart_series.dart` y `demo_dataset.dart`: la aritmética que decide qué
/// entra en el documento (recorte por periodo, promedios, mínimos/máximos,
/// muestreo de la tendencia) se comprueba entera desde una prueba unitaria.
///
/// La CLASIFICACIÓN clínica (dentro/fuera de rango) NO se hace aquí: la resuelve
/// la capa de PDF con los clasificadores de `health_classifiers.dart`, que
/// necesitan `AppLocalizations` para las etiquetas y ya están cubiertos por su
/// propio test. Aquí solo vive lo numérico.
library;

/// Ventana temporal que el usuario elige antes de generar el documento.
enum ExportPeriod {
  sixMonths,
  oneYear,
  all;

  /// Días hacia atrás que abarca, o `null` para «todo el historial».
  int? get days => switch (this) {
    ExportPeriod.sixMonths => 180,
    ExportPeriod.oneYear => 365,
    ExportPeriod.all => null,
  };
}

/// Un punto de una serie temporal: una fecha y un valor numérico.
class SeriesPoint {
  final DateTime date;
  final double value;
  const SeriesPoint(this.date, this.value);
}

/// Estadísticas de un campo numérico dentro del periodo: último valor y su
/// fecha, promedio, mínimo, máximo y número de mediciones.
class Stats {
  final double latest;
  final DateTime latestDate;
  final double average;
  final double min;
  final double max;
  final int count;

  const Stats({
    required this.latest,
    required this.latestDate,
    required this.average,
    required this.min,
    required this.max,
    required this.count,
  });

  /// Calcula las estadísticas de una serie ordenada ASCENDENTEMENTE por fecha.
  /// Devuelve `null` si la serie está vacía (nada que resumir).
  static Stats? fromSeries(List<SeriesPoint> ascending) {
    if (ascending.isEmpty) return null;
    var min = ascending.first.value;
    var max = ascending.first.value;
    var sum = 0.0;
    for (final p in ascending) {
      if (p.value < min) min = p.value;
      if (p.value > max) max = p.value;
      sum += p.value;
    }
    final last = ascending.last;
    return Stats(
      latest: last.value,
      latestDate: last.date,
      average: sum / ascending.length,
      min: min,
      max: max,
      count: ascending.length,
    );
  }
}

/// Serie de un único campo (p. ej. «sistólica» o «peso»), lista para
/// graficarse y resumirse. Guarda la serie completa del periodo; la capa de PDF
/// la muestrea con [sampled] para dibujar sin ahogar la gráfica.
class MetricSeries {
  /// Identificador estable del campo, independiente del idioma
  /// (p. ej. `'bp_systolic'`, `'weight'`). No es texto de interfaz.
  final String key;
  final List<SeriesPoint> points;

  const MetricSeries(this.key, this.points);

  bool get isEmpty => points.isEmpty;
  bool get isNotEmpty => points.isNotEmpty;

  Stats? get stats => Stats.fromSeries(points);

  /// Serie reducida para la gráfica, conservando primer y último punto.
  /// Reutiliza el muestreo uniforme de las gráficas de pantalla.
  List<SeriesPoint> sampled({int maxPoints = 24}) =>
      downsample(points, maxPoints: maxPoints);
}

/// El resumen consolidado ya recortado al periodo y ordenado. Conserva los
/// registros tipados (con su `comment`) para que la capa de PDF pinte las
/// tablas y clasifique cada valor.
class ClinicalSummary {
  final ExportPeriod period;

  /// Instante de generación (inyectado, nunca `DateTime.now()` interno) para
  /// que el resultado sea determinista y testeable.
  final DateTime generatedAt;

  /// Extremos del rango de datos realmente incluido (la medición más antigua y
  /// la más reciente de cualquier indicador). `null` si no hay ningún dato.
  final DateTime? periodStart;
  final DateTime? periodEnd;

  /// Registros del periodo, ordenados ASCENDENTEMENTE por fecha.
  final List<VitalSignRecord> vitals;
  final List<AnthropometricRecord> anthropometry;
  final List<LipidRecord> lipids;
  final List<BodyCompositionRecord> bodyComposition;

  const ClinicalSummary({
    required this.period,
    required this.generatedAt,
    required this.periodStart,
    required this.periodEnd,
    required this.vitals,
    required this.anthropometry,
    required this.lipids,
    required this.bodyComposition,
  });

  bool get isEmpty =>
      vitals.isEmpty &&
      anthropometry.isEmpty &&
      lipids.isEmpty &&
      bodyComposition.isEmpty;

  bool get hasData => !isEmpty;

  // ── Series por campo (para las gráficas y las estadísticas del PDF) ────────

  MetricSeries get systolicSeries =>
      _series('bp_systolic', vitals, (r) => r.systolic.toDouble());
  MetricSeries get diastolicSeries =>
      _series('bp_diastolic', vitals, (r) => r.diastolic.toDouble());
  MetricSeries get heartRateSeries =>
      _series('heart_rate', vitals, (r) => r.heartRate.toDouble());

  MetricSeries get weightSeries =>
      _series('weight', anthropometry, (r) => r.weight);
  MetricSeries get bmiSeries => _series('bmi', anthropometry, (r) => r.bmi);

  MetricSeries get totalCholesterolSeries =>
      _series('chol_total', lipids, (r) => r.totalCholesterol);
  MetricSeries get ldlSeries => _series('chol_ldl', lipids, (r) => r.ldl);
  MetricSeries get hdlSeries => _series('chol_hdl', lipids, (r) => r.hdl);
  MetricSeries get triglyceridesSeries =>
      _series('triglycerides', lipids, (r) => r.triglycerides);

  MetricSeries get bodyFatSeries =>
      _series('body_fat', bodyComposition, (r) => r.bodyFatPercent);
  MetricSeries get visceralFatSeries => _series(
    'visceral_fat',
    bodyComposition,
    (r) => r.visceralFatLevel?.toDouble(),
  );

  /// Construye una [MetricSeries] a partir de una lista ascendente, saltando
  /// los registros cuyo valor es `null` (campos opcionales como el colesterol).
  static MetricSeries _series<T>(
    String key,
    List<T> ascending,
    double? Function(T) valueOf, {
    DateTime Function(T)? dateOf,
  }) {
    final resolveDate = dateOf ?? ((r) => (r as dynamic).date as DateTime);
    final points = <SeriesPoint>[];
    for (final r in ascending) {
      final v = valueOf(r);
      if (v == null) continue;
      points.add(SeriesPoint(resolveDate(r), v));
    }
    return MetricSeries(key, points);
  }
}

/// Recorta [records] al [period] respecto de [now] y los devuelve ordenados
/// ascendentemente por fecha. `ExportPeriod.all` no filtra. Función pura.
List<T> withinPeriod<T>(
  List<T> records,
  DateTime Function(T) dateOf,
  ExportPeriod period,
  DateTime now,
) {
  final days = period.days;
  Iterable<T> filtered = records;
  if (days != null) {
    final cutoff = now.subtract(Duration(days: days));
    // `isBefore` estricto excluiría un registro tomado justo en el corte; se usa
    // «no anterior al corte» para incluir el borde.
    filtered = records.where((r) => !dateOf(r).isBefore(cutoff));
  }
  final list = filtered.toList()
    ..sort((a, b) => dateOf(a).compareTo(dateOf(b)));
  return list;
}

/// Construye el [ClinicalSummary] a partir de las cuatro listas crudas de los
/// repositorios (en cualquier orden). Puro: [now] se inyecta.
ClinicalSummary buildClinicalSummary({
  required ExportPeriod period,
  required DateTime now,
  required List<VitalSignRecord> vitals,
  required List<AnthropometricRecord> anthropometry,
  required List<LipidRecord> lipids,
  required List<BodyCompositionRecord> bodyComposition,
}) {
  final v = withinPeriod<VitalSignRecord>(vitals, (r) => r.date, period, now);
  final a = withinPeriod<AnthropometricRecord>(
    anthropometry,
    (r) => r.date,
    period,
    now,
  );
  final l = withinPeriod<LipidRecord>(lipids, (r) => r.date, period, now);
  final b = withinPeriod<BodyCompositionRecord>(
    bodyComposition,
    (r) => r.date,
    period,
    now,
  );

  final allDates = <DateTime>[
    ...v.map((r) => r.date),
    ...a.map((r) => r.date),
    ...l.map((r) => r.date),
    ...b.map((r) => r.date),
  ];
  DateTime? start;
  DateTime? end;
  for (final d in allDates) {
    if (start == null || d.isBefore(start)) start = d;
    if (end == null || d.isAfter(end)) end = d;
  }

  return ClinicalSummary(
    period: period,
    generatedAt: now,
    periodStart: start,
    periodEnd: end,
    vitals: v,
    anthropometry: a,
    lipids: l,
    bodyComposition: b,
  );
}
