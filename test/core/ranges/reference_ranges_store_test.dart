import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/core/ranges/reference_ranges_store.dart';
import 'package:myvitals_healthtracker_app/core/utils/health_classifiers.dart';

ServerBand _b(String code, double min, double max, {int order = 0}) =>
    ServerBand(
      bandCode: code,
      bandLabel: code,
      minValue: min,
      maxValue: max,
      sortOrder: order,
    );

void main() {
  final store = ReferenceRangesStore.instance;

  tearDown(() => store.setForTesting({}));

  group('ReferenceRangesStore.classify', () {
    test('encuentra la banda que contiene el valor', () {
      store.setForTesting({
        'BODY_FAT': [
          _b('LOW', 0, 21.0),
          _b('NORMAL', 21.1, 32.9),
          _b('HIGH', 33.0, 38.9),
          _b('VERY_HIGH', 39.0, 99.0),
        ],
      });

      expect(store.classify('BODY_FAT', 25)!.bandCode, 'NORMAL');
      expect(store.classify('BODY_FAT', 43.0)!.bandCode, 'VERY_HIGH');
    });

    test('valores fuera de la escala se ajustan a la banda extrema', () {
      store.setForTesting({
        'VISCERAL_FAT_LEVEL': [_b('NORMAL', 1, 9), _b('VERY_HIGH', 15, 59)],
      });

      expect(store.classify('VISCERAL_FAT_LEVEL', 0)!.bandCode, 'NORMAL');
      expect(store.classify('VISCERAL_FAT_LEVEL', 200)!.bandCode, 'VERY_HIGH');
    });

    test(
      'sin datos para el indicador devuelve null (fallback del llamador)',
      () {
        expect(store.classify('BMI', 24), isNull);
      },
    );
  });

  group('Clasificadores: servidor primero, fábrica como fallback', () {
    test('BMI usa el corte del SERVIDOR aunque difiera del OMS', () {
      // Servidor (backoffice) define sobrepeso desde 26, no 25.
      store.setForTesting({
        'BMI': [
          _b('UNDERWEIGHT', 0, 18.4),
          _b('NORMAL', 18.5, 25.9),
          _b('OVERWEIGHT', 26.0, 29.9),
          _b('OBESE', 30.0, 90),
        ],
      });

      // 25.5 sería sobrepeso con el fallback OMS; el servidor dice normal.
      expect(BmiCategory.of(25.5), BmiCategory.normal);
      expect(BmiCategory.of(26.5), BmiCategory.overweight);
    });

    test('BMI sin servidor cae al corte OMS de fábrica', () {
      expect(BmiCategory.of(25.5), BmiCategory.overweight);
      expect(BmiCategory.of(17.0), BmiCategory.low);
    });

    test('grasa corporal mapea bandas por sexo/edad del servidor', () {
      // Bandas femeninas 18-39 (tabla OMRON del legacy) ya resueltas por el server.
      store.setForTesting({
        'BODY_FAT': [
          _b('LOW', 0, 21.0),
          _b('NORMAL', 21.1, 32.9),
          _b('HIGH', 33.0, 38.9),
          _b('VERY_HIGH', 39.0, 99.0),
        ],
      });

      // 30% es "elevado" con el fallback genérico; para mujer 18-39 es NORMAL.
      expect(FatCategory.of(30), FatCategory.normal);
      expect(FatCategory.of(34), FatCategory.elevated); // HIGH del server
      expect(FatCategory.of(40), FatCategory.high); // VERY_HIGH del server
    });

    test('grasa visceral con bandas del servidor', () {
      store.setForTesting({
        'VISCERAL_FAT_LEVEL': [
          _b('NORMAL', 0, 9),
          _b('HIGH', 10, 14),
          _b('VERY_HIGH', 15, 60),
        ],
      });

      expect(VisceralCategory.of(7), VisceralCategory.normal);
      expect(VisceralCategory.of(12), VisceralCategory.elevated);
      expect(VisceralCategory.of(16), VisceralCategory.high);
    });

    test('presión arterial toma el componente más severo del servidor', () {
      store.setForTesting({
        'BP_SYSTOLIC': [_b('NORMAL', 90, 120), _b('HIGH', 140, 300)],
        'BP_DIASTOLIC': [_b('NORMAL', 60, 80), _b('HIGH', 90, 200)],
      });

      expect(BpCategory.of(110, 95), BpCategory.high); // diastólica manda
      expect(BpCategory.of(110, 75), BpCategory.normal);
    });
  });
}
