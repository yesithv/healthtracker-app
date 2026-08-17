import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/core/demo/demo_dataset.dart';

/// La serie curada de la demo cuenta una mejora bonita y suave, y por eso NUNCA
/// toca los topes clínicos ni las rarezas de tiempo que un usuario real sí
/// produce: dos tomas en el mismo instante, la tensión al borde del clamp, una
/// presión de pulso de 1 mmHg. `buildDemoDataset` los añade a propósito
/// (`includeEdgeCases`, encendido por defecto) para ver cómo se comporta la app
/// con datos extremos ANTES de que lleguen en producción.
///
/// Estas pruebas blindan ese contrato: que los extremos existan, que sigan
/// siendo válidos y coherentes (no basta con que sean feos, tienen que poder
/// darse), que no desplacen el dato más reciente que abre el panel, y que —como
/// todo lo de la demo— salgan idénticos en cada generación.
void main() {
  // Fecha fija: la demo es determinista, así que la prueba no depende del reloj.
  final today = DateTime(2026, 7, 29, 8);
  final withEdges = buildDemoDataset(today: today);
  final clean = buildDemoDataset(today: today, includeEdgeCases: false);

  bool isEdge(String id) => id.startsWith('demo-edge-');

  group('los casos extremos se añaden a las cuatro familias ·', () {
    test('sin la bandera no aparece ningún registro extremo', () {
      final ids = [
        ...clean.anthropometric.map((r) => r.id),
        ...clean.vitalSigns.map((r) => r.id),
        ...clean.lipids.map((r) => r.id),
        ...clean.bodyComposition.map((r) => r.id),
      ];
      expect(ids.any(isEdge), isFalse);
    });

    test('con la bandera (por defecto) cada familia gana sus extremos', () {
      // Se cuentan por diferencia con la serie limpia: así la cuenta no se
      // desactualiza si mañana cambia la cadencia de la serie curada.
      expect(
        withEdges.anthropometric.where((r) => isEdge(r.id)),
        hasLength(withEdges.anthropometric.length - clean.anthropometric.length),
      );
      expect(withEdges.anthropometric.where((r) => isEdge(r.id)), hasLength(3));
      expect(withEdges.vitalSigns.where((r) => isEdge(r.id)), hasLength(5));
      expect(withEdges.lipids.where((r) => isEdge(r.id)), hasLength(2));
      expect(withEdges.bodyComposition.where((r) => isEdge(r.id)), hasLength(2));
    });

    test('los identificadores siguen siendo únicos', () {
      final ids = [
        ...withEdges.anthropometric.map((r) => r.id),
        ...withEdges.vitalSigns.map((r) => r.id),
        ...withEdges.lipids.map((r) => r.id),
        ...withEdges.bodyComposition.map((r) => r.id),
      ];
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('todo queda marcado como sincronizado, también los extremos', () {
      expect(withEdges.anthropometric.every((r) => r.isSynced), isTrue);
      expect(withEdges.vitalSigns.every((r) => r.isSynced), isTrue);
      expect(withEdges.lipids.every((r) => r.isSynced), isTrue);
      expect(withEdges.bodyComposition.every((r) => r.isSynced), isTrue);
    });
  });

  group('cada familia sigue ordenada ascendentemente por fecha ·', () {
    void ascending(List<DateTime> dates, String family) {
      for (var i = 1; i < dates.length; i++) {
        expect(
          dates[i].isBefore(dates[i - 1]),
          isFalse,
          reason: '$family: los extremos no pueden desordenar la serie',
        );
      }
    }

    test('antropometría, vitales, lípidos y composición', () {
      ascending(withEdges.anthropometric.map((r) => r.date).toList(), 'antropometría');
      ascending(withEdges.vitalSigns.map((r) => r.date).toList(), 'vitales');
      ascending(withEdges.lipids.map((r) => r.date).toList(), 'lípidos');
      ascending(withEdges.bodyComposition.map((r) => r.date).toList(), 'composición');
    });
  });

  group('los extremos NO desplazan el dato más reciente ·', () {
    // El panel abre con la última medición de cada familia; si un extremo se
    // colara como la más reciente, la tarjeta «actual» enseñaría una crisis en
    // vez de los valores de hoy de Camila. Por diseño van en medio de la serie.
    test('el último registro de cada familia es de la serie curada', () {
      expect(isEdge(withEdges.anthropometric.last.id), isFalse);
      expect(isEdge(withEdges.vitalSigns.last.id), isFalse);
      expect(isEdge(withEdges.lipids.last.id), isFalse);
      expect(isEdge(withEdges.bodyComposition.last.id), isFalse);
    });
  });

  group('los extremos son válidos y coherentes ·', () {
    test('tensión y pulso: dentro del clamp y sistólica > diastólica', () {
      final edges = withEdges.vitalSigns.where((r) => isEdge(r.id));
      expect(edges, isNotEmpty);
      for (final r in edges) {
        expect(r.systolic, inInclusiveRange(95, 172));
        expect(r.diastolic, inInclusiveRange(58, 108));
        expect(r.heartRate, inInclusiveRange(48, 168));
        expect(
          r.systolic,
          greaterThan(r.diastolic),
          reason: 'la sistólica siempre va por encima de la diastólica',
        );
        expect(['reposo', 'ejercicio', 'post-op'], contains(r.activityState));
        expect(
          ['normal', 'mareo', 'dolor', 'fatiga'],
          contains(r.symptom),
        );
      }
    });

    test('antropometría: el IMC se deriva del peso y la talla', () {
      final edges = withEdges.anthropometric.where((r) => isEdge(r.id));
      expect(edges, isNotEmpty);
      for (final r in edges) {
        expect(r.height, 165.0);
        final expected = r.weight / ((r.height / 100) * (r.height / 100));
        expect(r.bmi, closeTo(expected, 0.05));
      }
    });

    test('lípidos: cuadran por Friedewald (VLDL≈TG/5, total=suma)', () {
      final edges = withEdges.lipids.where((r) => isEdge(r.id));
      expect(edges, isNotEmpty);
      for (final r in edges) {
        expect(r.vldl, closeTo(r.triglycerides! / 5, 1));
        expect(r.totalCholesterol, closeTo(r.ldl! + r.hdl! + r.vldl!, 1));
      }
    });

    test('composición: los niveles enteros caen en su escala', () {
      final edges = withEdges.bodyComposition.where((r) => isEdge(r.id));
      expect(edges, isNotEmpty);
      for (final r in edges) {
        expect(r.visceralFatLevel, inInclusiveRange(1, 30));
        expect(r.metabolicAge, inInclusiveRange(18, 80));
        expect(r.bodyFatPercent, inInclusiveRange(0.0, 100.0));
      }
    });
  });

  group('el extremo de TIEMPO: dos tomas en el mismo instante ·', () {
    test('las tomas «gemelas» comparten fecha exacta y valores distintos', () {
      final a = withEdges.vitalSigns
          .firstWhere((r) => r.id == 'demo-edge-vitals-collision-a');
      final b = withEdges.vitalSigns
          .firstWhere((r) => r.id == 'demo-edge-vitals-collision-b');
      expect(
        a.date,
        b.date,
        reason: 'la colisión de fecha es el caso que estresa las gráficas',
      );
      expect(a.systolic == b.systolic && a.diastolic == b.diastolic, isFalse);
    });
  });

  group('los extremos también son deterministas ·', () {
    test('dos generaciones dan exactamente los mismos extremos', () {
      final again = buildDemoDataset(today: today);
      String sig(Iterable<dynamic> rs) => rs
          .where((r) => isEdge(r.id as String))
          .map((r) => '${r.id}@${r.date.toIso8601String()}')
          .join('|');

      expect(sig(again.anthropometric), sig(withEdges.anthropometric));
      expect(sig(again.vitalSigns), sig(withEdges.vitalSigns));
      expect(sig(again.lipids), sig(withEdges.lipids));
      expect(sig(again.bodyComposition), sig(withEdges.bodyComposition));

      // Y los valores, no solo las fechas.
      final vitalsA = again.vitalSigns.where((r) => isEdge(r.id));
      final vitalsB = withEdges.vitalSigns.where((r) => isEdge(r.id));
      expect(
        vitalsA.map((r) => '${r.systolic}/${r.diastolic}·${r.heartRate}'),
        vitalsB.map((r) => '${r.systolic}/${r.diastolic}·${r.heartRate}'),
      );
    });
  });
}
