import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/core/demo/demo_dataset.dart';
import 'package:myvitals_healthtracker_app/core/export/clinical_summary.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/vital_sign_record.dart';

/// El PDF consolidado resume el historial con mínimos, máximos y promedios. Es
/// justo donde un valor extremo tiene que APARECER —un máximo de tensión que se
/// pierde es un informe que miente al médico— y donde un caso degenerado (una
/// serie de un solo punto, dos mediciones en el mismo instante) no puede tumbar
/// la aritmética. Estas pruebas empujan los extremos de la demo por la
/// agregación pura y fijan ambas cosas.
void main() {
  // Mismo «hoy» que la demo, para que el recorte por periodo sea determinista.
  final today = DateTime(2026, 7, 29, 8);
  // Opt-in: los edge cases están apagados por defecto (aplastan las gráficas del
  // home), así que esta prueba de blindaje enciende la bandera a mano.
  final data = buildDemoDataset(today: today, includeEdgeCases: true);

  final summary = buildClinicalSummary(
    period: ExportPeriod.all,
    now: today,
    vitals: data.vitalSigns,
    anthropometry: data.anthropometric,
    lipids: data.lipids,
    bodyComposition: data.bodyComposition,
  );

  group('los extremos afloran en las estadísticas del periodo ·', () {
    test('la tensión recoge la crisis al tope del clamp', () {
      final s = summary.systolicSeries.stats!;
      expect(
        s.max,
        172,
        reason: 'la crisis hipertensiva es el máximo de la serie',
      );
      expect(s.min, lessThanOrEqualTo(100));
    });

    test('el peso abarca del bajo peso a la obesidad extrema', () {
      final s = summary.weightSeries.stats!;
      expect(s.min, lessThanOrEqualTo(44.0));
      expect(s.max, greaterThanOrEqualTo(118.0));
      // El promedio queda entre medias: los dos extremos no lo sacan de rango.
      expect(s.average, inInclusiveRange(s.min, s.max));
    });

    test('el colesterol y el HDL recogen los paneles extremos', () {
      expect(summary.ldlSeries.stats!.max, greaterThanOrEqualTo(300));
      expect(summary.hdlSeries.stats!.max, greaterThanOrEqualTo(100));
    });

    test('la grasa corporal y la visceral llegan a sus topes', () {
      expect(summary.bodyFatSeries.stats!.max, greaterThanOrEqualTo(55.0));
      expect(summary.visceralFatSeries.stats!.max, greaterThanOrEqualTo(30.0));
    });

    test('el muestreo de cada serie conserva primer y último punto', () {
      // La capa de PDF dibuja con `sampled`; da igual cuántos extremos haya en
      // medio, los bordes del periodo tienen que sobrevivir.
      final full = summary.systolicSeries.points;
      final sampled = summary.systolicSeries.sampled(maxPoints: 12);
      expect(sampled.first.value, full.first.value);
      expect(sampled.last.value, full.last.value);
    });
  });

  group('Stats.fromSeries con entradas degeneradas ·', () {
    test('un solo punto: mínimo = máximo = promedio = último', () {
      final s = Stats.fromSeries([SeriesPoint(today, 130)])!;
      expect(s.count, 1);
      expect(s.min, 130);
      expect(s.max, 130);
      expect(s.average, closeTo(130, 1e-9));
      expect(s.latest, 130);
      expect(s.latestDate, today);
    });

    test('dos puntos en el mismo instante no rompen la aritmética', () {
      // La colisión de fecha del generador: min/max/promedio siguen siendo
      // correctos aunque las dos mediciones compartan marca de tiempo.
      final s = Stats.fromSeries([
        SeriesPoint(today, 168),
        SeriesPoint(today, 110),
      ])!;
      expect(s.count, 2);
      expect(s.min, 110);
      expect(s.max, 168);
      expect(s.average, closeTo(139, 1e-9));
    });
  });

  group('withinPeriod con fechas colisionadas ·', () {
    test('conserva las dos tomas del mismo instante y las ordena', () {
      final collision = DateTime(2026, 5, 1, 9, 30);
      VitalSignRecord v(int s) => VitalSignRecord(
        date: collision,
        systolic: s,
        diastolic: 80,
        heartRate: 70,
      );

      final out = withinPeriod(
        [v(168), v(110)],
        (r) => r.date,
        ExportPeriod.all,
        today,
      );
      expect(out, hasLength(2));
      expect(out.every((r) => r.date == collision), isTrue);
    });
  });
}
