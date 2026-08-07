import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/core/demo/demo_dataset.dart';

/// Lo que se fotografía es lo que se enseña, y una captura vive después en una
/// web durante meses: si la demo publicara una analítica que no cuadra o un
/// pulso imposible, el error queda ahí, ampliado. Estas pruebas vigilan las tres
/// cosas que un generador de datos falsos rompe con facilidad:
///
/// 1. que los valores sean fisiológicamente posibles,
/// 2. que las familias no se contradigan entre sí (el IMC sale del peso y la
///    talla, el VLDL de los triglicéridos, los kg de músculo del peso del día),
/// 3. que dos generaciones seguidas den lo mismo — que es lo que permite
///    repetir una captura semanas después y que salga idéntica.
void main() {
  // Fecha fija: así la prueba no cambia de resultado según el día en que corra.
  final today = DateTime(2026, 7, 29, 8);
  final data = buildDemoDataset(today: today);

  group('el conjunto de la demo ·', () {
    test('cubre dos años en las cuatro familias', () {
      expect(data.anthropometric, hasLength(105)); // semanal
      expect(data.bodyComposition, hasLength(105)); // una por pesaje
      expect(data.lipids, hasLength(9)); // trimestral
      // La tensión se mide en casa: es la serie densa, y la que llena las
      // gráficas de los filtros de 7 y 30 días.
      expect(data.vitalSigns.length, greaterThan(380));

      final families = {
        'antropometría': data.anthropometric.map((r) => r.date).toList(),
        'signos vitales': data.vitalSigns.map((r) => r.date).toList(),
        'lípidos': data.lipids.map((r) => r.date).toList(),
        'composición': data.bodyComposition.map((r) => r.date).toList(),
      };

      families.forEach((family, dates) {
        expect(dates.first.isBefore(dates.last), isTrue, reason: family);
        // Cada familia tiene su cadencia (semanal, cada dos días, trimestral),
        // así que su primer registro cae dentro de un ciclo del arranque de la
        // ventana; ninguna empieza a mitad de camino.
        expect(
          today.difference(dates.first).inDays,
          inInclusiveRange(640, 731),
          reason: '$family: la historia debe abarcar los dos años anunciados',
        );
        // Y todas llegan hasta hoy: una tarjeta del panel que abriera con un
        // dato de hace meses es exactamente lo que no se quiere fotografiar.
        expect(
          today.difference(dates.last).inDays,
          lessThanOrEqualTo(7),
          reason: '$family: la demo no puede morir en el pasado',
        );
      });
    });

    test('es determinista: la misma fecha da exactamente los mismos datos', () {
      final again = buildDemoDataset(today: today);
      expect(
        again.anthropometric.map((r) => r.weight),
        data.anthropometric.map((r) => r.weight),
      );
      expect(
        again.vitalSigns.map((r) => '${r.systolic}/${r.diastolic}·${r.heartRate}'),
        data.vitalSigns.map((r) => '${r.systolic}/${r.diastolic}·${r.heartRate}'),
      );
      expect(again.lipids.map((r) => r.ldl), data.lipids.map((r) => r.ldl));
    });

    test('los identificadores son únicos', () {
      final ids = [
        ...data.anthropometric.map((r) => r.id),
        ...data.vitalSigns.map((r) => r.id),
        ...data.lipids.map((r) => r.id),
        ...data.bodyComposition.map((r) => r.id),
      ];
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('todo queda marcado como sincronizado', () {
      // Si no, el panel de cuenta enseñaría 600 registros pendientes de subir
      // justo en la captura que quiere enseñar una app al día.
      expect(data.anthropometric.every((r) => r.isSynced), isTrue);
      expect(data.vitalSigns.every((r) => r.isSynced), isTrue);
      expect(data.lipids.every((r) => r.isSynced), isTrue);
      expect(data.bodyComposition.every((r) => r.isSynced), isTrue);
    });
  });

  group('los valores son posibles ·', () {
    test('peso, talla e IMC', () {
      for (final r in data.anthropometric) {
        expect(r.weight, inInclusiveRange(61.0, 83.0));
        expect(r.height, 165.0);
        // El IMC no se inventa: se deriva del peso y la talla del registro.
        final expected = r.weight / ((r.height / 100) * (r.height / 100));
        expect(r.bmi, closeTo(expected, 0.05));
      }
    });

    test('tensión y pulso', () {
      for (final r in data.vitalSigns) {
        expect(r.systolic, inInclusiveRange(95, 172));
        expect(r.diastolic, inInclusiveRange(58, 108));
        expect(r.heartRate, inInclusiveRange(48, 168));
        expect(
          r.systolic,
          greaterThan(r.diastolic),
          reason: 'La sistólica siempre va por encima de la diastólica',
        );
        expect(['reposo', 'ejercicio', 'post-op'], contains(r.activityState));
        expect(
          ['normal', 'mareo', 'dolor', 'fatiga'],
          contains(r.symptom),
          reason: 'Vocabulario de la pantalla de registro',
        );
      }
    });

    test('el panel lipídico cuadra por dentro', () {
      for (final r in data.lipids) {
        expect(r.ldl, inInclusiveRange(90.0, 160.0));
        expect(r.hdl, inInclusiveRange(37.0, 66.0));
        expect(r.triglycerides, inInclusiveRange(95.0, 220.0));
        // Friedewald: VLDL ≈ triglicéridos / 5.
        expect(r.vldl, closeTo(r.triglycerides! / 5, 1));
        // Y el total es la suma de las tres fracciones.
        expect(r.totalCholesterol, closeTo(r.ldl! + r.hdl! + r.vldl!, 1));
      }
    });

    test('la composición corporal concuerda con el peso del mismo día', () {
      final weightByDate = {
        for (final r in data.anthropometric) r.date: r.weight,
      };

      for (final r in data.bodyComposition) {
        expect(r.bodyFatPercent, inInclusiveRange(23.0, 38.0));
        expect(r.musclePct, inInclusiveRange(21.0, 33.0));
        expect(r.visceralFatLevel, inInclusiveRange(1, 30));
        expect(r.metabolicAge, inInclusiveRange(18, 80));
        expect(r.bodyWaterPercent, inInclusiveRange(42.0, 55.0));

        final weight = weightByDate[r.date];
        expect(
          weight,
          isNotNull,
          reason: 'Cada bioimpedancia sale del pesaje de ese día',
        );
        expect(r.muscleMassKg, closeTo(weight! * r.musclePct! / 100, 0.1));
      }
    });
  });

  group('la historia mejora ·', () {
    // El sentido de la demo: que las gráficas se lean de un vistazo. Si el
    // generador dejara de contar una mejora, las capturas perderían el hilo.
    test('el peso y el IMC bajan de sobrepeso a normalidad', () {
      expect(data.anthropometric.first.bmi, greaterThan(29));
      expect(data.anthropometric.last.bmi, lessThan(25));
    });

    test('la tensión pasa de elevada a normal', () {
      // Se promedian las tomas en reposo del primer y del último mes: una
      // lectura suelta no dice nada, y las de después de entrenar sesgarían.
      double restingMean(Iterable<int> values) =>
          values.reduce((a, b) => a + b) / values.length;

      final resting = data.vitalSigns
          .where((r) => r.activityState == 'reposo')
          .toList();
      final firstMonth = resting.take(15).map((r) => r.systolic);
      final lastMonth = resting.reversed.take(15).map((r) => r.systolic);

      expect(restingMean(firstMonth), greaterThan(130));
      expect(restingMean(lastMonth), lessThan(125));
    });

    test('el perfil lipídico mejora en las cuatro fracciones', () {
      final first = data.lipids.first;
      final last = data.lipids.last;
      expect(last.ldl, lessThan(first.ldl!));
      expect(last.triglycerides, lessThan(first.triglycerides!));
      expect(last.totalCholesterol, lessThan(first.totalCholesterol!));
      // El HDL es el bueno: éste tiene que SUBIR.
      expect(last.hdl, greaterThan(first.hdl!));
    });

    test('se pierde grasa y se gana músculo', () {
      expect(
        data.bodyComposition.last.bodyFatPercent,
        lessThan(data.bodyComposition.first.bodyFatPercent!),
      );
      expect(
        data.bodyComposition.last.musclePct,
        greaterThan(data.bodyComposition.first.musclePct!),
      );
      expect(
        data.bodyComposition.last.visceralFatLevel,
        lessThan(data.bodyComposition.first.visceralFatLevel!),
      );
    });
  });

  group('los comentarios siguen el idioma de la demo ·', () {
    test('en español y en inglés', () {
      String firstComment(DemoDataset d) =>
          d.anthropometric.firstWhere((r) => r.comment != null).comment!;

      expect(firstComment(buildDemoDataset(today: today)), contains('gimnasio'));
      expect(
        firstComment(buildDemoDataset(today: today, language: 'en')),
        contains('gym'),
      );
      // Los idiomas sin juego propio caen al inglés, no al español.
      expect(
        firstComment(buildDemoDataset(today: today, language: 'de')),
        contains('gym'),
      );
    });
  });
}
