import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/core/sync/server_import_mapper.dart';
import 'package:myvitals_healthtracker_app/core/sync/measurement_read_client.dart';

ServerMeasurement _p(
  String code,
  DateTime at,
  num value, {
  String source = 'LEGACY',
  String? note,
  Map<String, dynamic> context = const {},
}) {
  return ServerMeasurement(
    indicatorCode: code,
    indicatorName: code,
    measuredAt: at,
    value: value,
    source: source,
    note: note,
    context: context,
  );
}

void main() {
  final t1 = DateTime(2016, 7, 12, 14, 0);
  final t2 = DateTime(2016, 8, 12, 14, 0);

  group('ServerImportMapper', () {
    test(
      'agrupa por instante y arma el registro antropométrico con perímetros',
      () {
        final batch = ServerImportMapper.fromServer([
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
        final batch = ServerImportMapper.fromServer([
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
      final batch = ServerImportMapper.fromServer([
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
        final batch = ServerImportMapper.fromServer([
          _p('VISCERAL_FAT', t1, 7),
        ]);

        expect(batch.bodyComposition, hasLength(1));
        expect(batch.bodyComposition.first.visceralFatLevel, 7);
      },
    );

    test('los puntos APP también vuelven: en un móvil nuevo son lo único que hay', () {
      // Antes se descartaban con el argumento de que «ya viven en la BD local». Eso
      // vale mientras el teléfono conserve su SQLite; tras reinstalar, está vacío y
      // esta era la línea que tiraba justo lo que la persona había escrito a mano.
      final batch = ServerImportMapper.fromServer([
        _p('WEIGHT', t1, 78, source: 'APP', context: {'clientId': 'abc'}),
        _p('HEIGHT', t1, 1.7, source: 'APP', context: {'clientId': 'abc'}),
      ]);

      expect(batch.anthropometric, hasLength(1));
      // Y vuelve con su identidad, no como una copia parecida: el registro que se
      // reinstala es el mismo, con el id que tuvo aquí.
      expect(batch.anthropometric.first.id, 'abc');
    });

    test('signos vitales vuelven con su estado y su síntoma', () {
      // La app los sube desde siempre (MeasurementMapper.fromVitalSign) y el mapa de
      // vuelta no los reconstruía: no volvían nunca.
      final batch = ServerImportMapper.fromServer([
        _p(
          'BP_SYSTOLIC',
          t1,
          128,
          source: 'APP',
          context: {'clientId': 'v1', 'activityState': 'reposo'},
        ),
        _p('BP_DIASTOLIC', t1, 82, source: 'APP', context: {'clientId': 'v1'}),
        _p(
          'HEART_RATE',
          t1,
          71,
          source: 'APP',
          context: {'clientId': 'v1', 'symptom': 'normal'},
          note: 'tras caminar',
        ),
      ]);

      expect(batch.vitalSigns, hasLength(1));
      final r = batch.vitalSigns.first;
      expect(r.systolic, 128);
      expect(r.diastolic, 82);
      expect(r.heartRate, 71);
      expect(r.activityState, 'reposo');
      expect(r.symptom, 'normal');
      expect(r.comment, 'tras caminar');
      expect(
        r.isSynced,
        isTrue,
        reason: 'vino del servidor: no se vuelve a subir',
      );
    });

    test('media tensión no es un registro', () {
      // Sin las tres cifras no hay toma que reconstruir; inventar la que falta sería
      // fabricar un dato clínico.
      final batch = ServerImportMapper.fromServer([
        _p('BP_SYSTOLIC', t1, 128, source: 'APP'),
        _p('HEART_RATE', t1, 71, source: 'APP'),
      ]);

      expect(batch.vitalSigns, isEmpty);
    });

    test(
      'lípidos vuelven con su laboratorio, aunque el perfil esté incompleto',
      () {
        // Un perfil con solo dos valores sigue siendo un resultado de laboratorio.
        final batch = ServerImportMapper.fromServer([
          _p(
            'CHOLESTEROL_TOTAL',
            t1,
            195,
            source: 'APP',
            context: {'clientId': 'l1', 'labName': 'Laboratorio Central'},
          ),
          _p(
            'TRIGLYCERIDES',
            t1,
            130,
            source: 'APP',
            context: {'clientId': 'l1'},
          ),
        ]);

        expect(batch.lipids, hasLength(1));
        final r = batch.lipids.first;
        expect(r.totalCholesterol, 195);
        expect(r.triglycerides, 130);
        expect(r.ldl, isNull);
        expect(r.labName, 'Laboratorio Central');
      },
    );

    test('la composición corporal vuelve entera, no a medias', () {
      // La subida emite ocho indicadores y la vuelta reconstruía cinco: los kg de
      // músculo, el agua y la masa ósea se perdían en el camino de ida y vuelta.
      final batch = ServerImportMapper.fromServer([
        _p('MUSCLE_MASS', t1, 41.2, source: 'APP', context: {'clientId': 'b1'}),
        _p('BODY_WATER', t1, 52.3, source: 'APP', context: {'clientId': 'b1'}),
        _p(
          'BONE_MASS',
          t1,
          2.4,
          source: 'APP',
          context: {'clientId': 'b1', 'deviceName': 'Omron HBF-516'},
        ),
      ]);

      expect(batch.bodyComposition, hasLength(1));
      final r = batch.bodyComposition.first;
      expect(r.muscleMassKg, 41.2);
      expect(r.bodyWaterPercent, 52.3);
      expect(r.boneMassKg, 2.4);
      expect(r.deviceName, 'Omron HBF-516');
    });

    test('dos registros en el mismo instante no se funden en uno', () {
      // Tomarse la tensión y anotar el peso en el mismo segundo es perfectamente
      // posible. Agrupar solo por instante los habría mezclado.
      final batch = ServerImportMapper.fromServer([
        _p('WEIGHT', t1, 78, source: 'APP', context: {'clientId': 'a'}),
        _p('HEIGHT', t1, 1.7, source: 'APP', context: {'clientId': 'a'}),
        _p('BP_SYSTOLIC', t1, 120, source: 'APP', context: {'clientId': 'b'}),
        _p('BP_DIASTOLIC', t1, 80, source: 'APP', context: {'clientId': 'b'}),
        _p('HEART_RATE', t1, 65, source: 'APP', context: {'clientId': 'b'}),
      ]);

      expect(batch.anthropometric, hasLength(1));
      expect(batch.vitalSigns, hasLength(1));
    });

    test('peso sin talla alguna se salta (no inventa registros inválidos)', () {
      final batch = ServerImportMapper.fromServer([_p('WEIGHT', t1, 78)]);

      expect(batch.anthropometric, isEmpty);
    });
  });
}
