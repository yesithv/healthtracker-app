import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/core/sync/legacy_import_mapper.dart';
import 'package:myvitals_healthtracker_app/core/sync/measurement_read_client.dart';

ServerMeasurement _p(
  String code,
  DateTime at,
  num value, {
  String source = 'LEGACY',
}) {
  return ServerMeasurement(
    indicatorCode: code,
    indicatorName: code,
    measuredAt: at,
    value: value,
    source: source,
  );
}

void main() {
  final t1 = DateTime(2016, 7, 12, 14, 0);
  final t2 = DateTime(2016, 8, 12, 14, 0);

  group('LegacyImportMapper', () {
    test(
      'agrupa por instante y arma el registro antropométrico con perímetros',
      () {
        final batch = LegacyImportMapper.fromServer([
          _p('WEIGHT', t1, 78.5),
          _p('HEIGHT', t1, 1.62),
          _p('BMI', t1, 29.9),
          _p('WAIST', t1, 92),
          _p('HIP', t1, 104.5),
          _p('LOWER_ABDOMEN', t1, 99),
          _p('ARM', t1, 31),
          _p('LEG', t1, 55.5),
          _p('CHEST_BUST', t1, 98),
        ]);

        expect(batch.anthropometric, hasLength(1));
        final r = batch.anthropometric.first;
        expect(r.weight, 78.5);
        expect(
          r.height,
          162,
          reason: 'el servidor entrega metros; el modelo local es cm',
        );
        expect(r.bmi, 29.9);
        expect(r.waistCm, 92);
        expect(r.hipCm, 104.5);
        expect(r.lowerAbdomenCm, 99);
        expect(r.armCm, 31);
        expect(r.legCm, 55.5);
        expect(r.chestBustCm, 98);
        expect(
          r.isSynced,
          isTrue,
          reason: 'vino del servidor: no debe re-subirse',
        );
      },
    );

    test(
      'sin talla en la atención, arrastra la última conocida y calcula BMI',
      () {
        final batch = LegacyImportMapper.fromServer([
          _p('WEIGHT', t1, 80), _p('HEIGHT', t1, 1.60),
          _p('WEIGHT', t2, 77), // t2 sin HEIGHT ni BMI
        ]);

        expect(batch.anthropometric, hasLength(2));
        final r2 = batch.anthropometric[1];
        expect(
          r2.height,
          160,
          reason: 'forward-fill de talla, convertida a cm',
        );
        expect(r2.bmi, closeTo(30.1, 0.05)); // 77 / 1.60²
      },
    );

    test('composición corporal mapea grasa/músculo%/visceral/kcal/edad', () {
      final batch = LegacyImportMapper.fromServer([
        _p('BODY_FAT', t1, 33.2),
        _p('KCAL', t1, 1450),
        _p('BODY_AGE', t1, 52),
        _p(
          'MUSCLE_PCT',
          t1,
          24.9,
        ), // % músculo esquelético (como lo guarda el legacy)
        _p('VISCERAL_FAT_LEVEL', t1, 9), // nivel OMRON (código unificado V25)
      ]);

      expect(batch.bodyComposition, hasLength(1));
      final r = batch.bodyComposition.first;
      expect(r.bodyFatPercent, 33.2);
      expect(r.bmrKcal, 1450);
      expect(r.metabolicAge, 52);
      expect(r.musclePct, 24.9);
      expect(r.visceralFatLevel, 9);
      expect(
        r.muscleMassKg,
        isNull,
        reason: 'el legacy nunca guardó kg de músculo',
      );
    });

    test(
      'acepta el código viejo VISCERAL_FAT como nivel (backend sin V25)',
      () {
        final batch = LegacyImportMapper.fromServer([
          _p('VISCERAL_FAT', t1, 7),
        ]);

        expect(batch.bodyComposition, hasLength(1));
        expect(batch.bodyComposition.first.visceralFatLevel, 7);
      },
    );

    test('ignora los puntos APP (ya viven en la BD local)', () {
      final batch = LegacyImportMapper.fromServer([
        _p('WEIGHT', t1, 78, source: 'APP'),
        _p('BODY_FAT', t1, 20, source: 'APP'),
      ]);

      expect(batch.isEmpty, isTrue);
    });

    test('peso sin talla alguna se salta (no inventa registros inválidos)', () {
      final batch = LegacyImportMapper.fromServer([_p('WEIGHT', t1, 78)]);

      expect(batch.anthropometric, isEmpty);
    });
  });
}
