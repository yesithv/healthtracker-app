import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/core/export/clinical_summary.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/anthropometric_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/body_composition_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/lipid_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/vital_sign_record.dart';

/// La agregación del PDF consolidado es Dart puro (recorte por periodo,
/// estadísticas, series), así que se comprueba entera sin levantar un widget ni
/// tocar el paquete `pdf` — mismo espíritu que `chart_series_test.dart`.
void main() {
  // Instante fijo: nada depende del reloj real, así el resultado es determinista.
  final now = DateTime(2026, 8, 7, 10, 0);

  VitalSignRecord vital(DateTime d, int s, int di, int hr) =>
      VitalSignRecord(date: d, systolic: s, diastolic: di, heartRate: hr);

  group('withinPeriod ·', () {
    final records = [
      vital(DateTime(2024, 1, 1), 120, 80, 70), // >1 año
      vital(DateTime(2026, 3, 1), 118, 78, 66), // dentro de 1 año y 6 meses
      vital(DateTime(2026, 7, 1), 116, 76, 64), // dentro de todo
      vital(
        DateTime(2025, 10, 1),
        122,
        82,
        72,
      ), // dentro de 1 año, fuera 6 meses
    ];

    test('«todo» no filtra y ordena ascendente por fecha', () {
      final out = withinPeriod(records, (r) => r.date, ExportPeriod.all, now);
      expect(out, hasLength(4));
      for (var i = 1; i < out.length; i++) {
        expect(out[i].date.isAfter(out[i - 1].date), isTrue);
      }
    });

    test('«1 año» excluye lo anterior al corte', () {
      final out = withinPeriod(
        records,
        (r) => r.date,
        ExportPeriod.oneYear,
        now,
      );
      expect(out, hasLength(3));
      expect(out.every((r) => r.date.year >= 2025), isTrue);
    });

    test('«6 meses» deja solo lo reciente', () {
      final out = withinPeriod(
        records,
        (r) => r.date,
        ExportPeriod.sixMonths,
        now,
      );
      // Solo marzo y julio de 2026 caen dentro de 180 días de 2026-08-07.
      expect(out, hasLength(2));
      expect(out.first.date, DateTime(2026, 3, 1));
      expect(out.last.date, DateTime(2026, 7, 1));
    });

    test('incluye el registro tomado justo en el corte', () {
      final cutoff = now.subtract(const Duration(days: 180));
      final out = withinPeriod(
        [vital(cutoff, 120, 80, 70)],
        (r) => r.date,
        ExportPeriod.sixMonths,
        now,
      );
      expect(out, hasLength(1));
    });
  });

  group('Stats.fromSeries ·', () {
    test('promedio, mínimo, máximo, último y conteo', () {
      final series = [
        SeriesPoint(DateTime(2026, 1, 1), 10),
        SeriesPoint(DateTime(2026, 2, 1), 30),
        SeriesPoint(DateTime(2026, 3, 1), 20),
      ];
      final s = Stats.fromSeries(series)!;
      expect(s.count, 3);
      expect(s.average, closeTo(20, 1e-9));
      expect(s.min, 10);
      expect(s.max, 30);
      expect(s.latest, 20); // el último por orden de la serie
      expect(s.latestDate, DateTime(2026, 3, 1));
    });

    test('serie vacía devuelve null', () {
      expect(Stats.fromSeries(const []), isNull);
    });
  });

  group('buildClinicalSummary ·', () {
    final vitals = [
      vital(DateTime(2026, 6, 1), 130, 85, 72),
      vital(DateTime(2026, 7, 1), 120, 80, 68),
    ];
    final anthro = [
      AnthropometricRecord(
        date: DateTime(2026, 5, 1),
        weight: 80,
        height: 175,
        bmi: 26.1,
      ),
      AnthropometricRecord(
        date: DateTime(2026, 7, 15),
        weight: 77,
        height: 175,
        bmi: 25.1,
      ),
    ];
    final lipids = [
      LipidRecord(date: DateTime(2026, 4, 1), totalCholesterol: 210, ldl: 130),
      LipidRecord(date: DateTime(2026, 7, 1), totalCholesterol: 185),
    ];
    final body = [
      BodyCompositionRecord(
        date: DateTime(2026, 7, 1),
        bodyFatPercent: 22.5,
        visceralFatLevel: 8,
      ),
    ];

    test('recorta, ordena y marca los extremos del periodo', () {
      final s = buildClinicalSummary(
        period: ExportPeriod.oneYear,
        now: now,
        vitals: vitals,
        anthropometry: anthro,
        lipids: lipids,
        bodyComposition: body,
      );
      expect(s.hasData, isTrue);
      expect(s.periodStart, DateTime(2026, 4, 1)); // el lípido más antiguo
      expect(s.periodEnd, DateTime(2026, 7, 15)); // la antropometría más nueva
      expect(s.vitals.first.date.isBefore(s.vitals.last.date), isTrue);
    });

    test('las series saltan los campos null (colesterol total)', () {
      final s = buildClinicalSummary(
        period: ExportPeriod.all,
        now: now,
        vitals: const [],
        anthropometry: const [],
        lipids: lipids,
        bodyComposition: const [],
      );
      // Ambos lípidos traen colesterol total → 2 puntos.
      expect(s.totalCholesterolSeries.points, hasLength(2));
      // Solo uno trae LDL → 1 punto.
      expect(s.ldlSeries.points, hasLength(1));
    });

    test('resumen vacío cuando no hay datos', () {
      final s = buildClinicalSummary(
        period: ExportPeriod.all,
        now: now,
        vitals: const [],
        anthropometry: const [],
        lipids: const [],
        bodyComposition: const [],
      );
      expect(s.isEmpty, isTrue);
      expect(s.periodStart, isNull);
      expect(s.periodEnd, isNull);
    });

    test('es determinista: misma entrada, misma salida', () {
      ClinicalSummary run() => buildClinicalSummary(
        period: ExportPeriod.oneYear,
        now: now,
        vitals: vitals,
        anthropometry: anthro,
        lipids: lipids,
        bodyComposition: body,
      );
      final a = run();
      final b = run();
      expect(a.weightSeries.stats!.latest, b.weightSeries.stats!.latest);
      expect(a.weightSeries.stats!.average, b.weightSeries.stats!.average);
      expect(a.periodStart, b.periodStart);
      expect(a.periodEnd, b.periodEnd);
    });
  });
}
