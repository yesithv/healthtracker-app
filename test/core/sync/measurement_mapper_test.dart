import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/core/sync/measurement_mapper.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/anthropometric_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/body_composition_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/lipid_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/vital_sign_record.dart';

void main() {
  final when = DateTime.utc(2026, 7, 10, 8, 30);

  group('MeasurementMapper', () {
    test('antropométrico → WEIGHT, HEIGHT, BMI con la nota', () {
      final r = AnthropometricRecord(
        id: 'a1',
        date: when,
        weight: 78.5,
        height: 1.75,
        bmi: 25.6,
        comment: 'en ayunas',
      );

      final items = MeasurementMapper.fromAnthropometric(r);

      expect(items.map((i) => i.indicatorCode), ['WEIGHT', 'HEIGHT', 'BMI']);
      expect(items.every((i) => i.clientId == 'a1'), isTrue);
      expect(items.every((i) => i.note == 'en ayunas'), isTrue);
      expect(items.first.value, 78.5);
    });

    test(
      'antropométrico convierte talla cm→m y emite perímetros presentes',
      () {
        final r = AnthropometricRecord(
          id: 'a2',
          date: when,
          weight: 78.5,
          height: 175, // la captura guarda cm; el catálogo HEIGHT es en metros
          bmi: 25.6,
          waistCm: 92,
          hipCm: 104.5,
          armCm: 31,
        );

        final items = MeasurementMapper.fromAnthropometric(r);

        expect(items.map((i) => i.indicatorCode), [
          'WEIGHT',
          'HEIGHT',
          'BMI',
          'WAIST',
          'HIP',
          'ARM',
        ]);
        final height = items
            .firstWhere((i) => i.indicatorCode == 'HEIGHT')
            .value;
        expect(height, 1.75);
        expect(items.firstWhere((i) => i.indicatorCode == 'WAIST').value, 92);
      },
    );

    test('signos vitales → 3 items con context de estado/síntoma', () {
      final r = VitalSignRecord(
        id: 'v1',
        date: when,
        systolic: 120,
        diastolic: 80,
        heartRate: 72,
        activityState: 'reposo',
        symptom: 'mareo',
      );

      final items = MeasurementMapper.fromVitalSign(r);

      expect(items.map((i) => i.indicatorCode), [
        'BP_SYSTOLIC',
        'BP_DIASTOLIC',
        'HEART_RATE',
      ]);
      expect(items.first.value, 120);
      expect(items.first.context, {
        'activityState': 'reposo',
        'symptom': 'mareo',
      });
    });

    test(
      'lípidos → solo emite los campos con valor, con labName en context',
      () {
        final r = LipidRecord(
          id: 'l1',
          date: when,
          totalCholesterol: 190,
          hdl: 55,
          // ldl, vldl, triglycerides nulos: no deben emitirse
          labName: 'Lab Central',
        );

        final items = MeasurementMapper.fromLipid(r);

        expect(items.map((i) => i.indicatorCode), [
          'CHOLESTEROL_TOTAL',
          'CHOLESTEROL_HDL',
        ]);
        expect(
          items.every((i) => i.context['labName'] == 'Lab Central'),
          isTrue,
        );
      },
    );

    test('composición corporal → grasa visceral usa VISCERAL_FAT_LEVEL y omite nulos', () {
      final r = BodyCompositionRecord(
        id: 'b1',
        date: when,
        bodyFatPercent: 22.4,
        visceralFatLevel: 8,
        deviceName: 'OMRON HBF-514C',
        // resto nulo
      );

      final items = MeasurementMapper.fromBodyComposition(r);

      expect(items.map((i) => i.indicatorCode), [
        'BODY_FAT',
        'VISCERAL_FAT_LEVEL',
      ]);
      expect(
        items.firstWhere((i) => i.indicatorCode == 'VISCERAL_FAT_LEVEL').value,
        8,
      );
      expect(
        items.every((i) => i.context['deviceName'] == 'OMRON HBF-514C'),
        isTrue,
      );
    });

    test(
      'toJson serializa measuredAt en UTC y omite note vacío / context vacío',
      () {
        final item = IngestItem(
          clientId: 'c1',
          indicatorCode: 'WEIGHT',
          measuredAt: DateTime.utc(2026, 7, 10, 8, 30),
          value: 80,
        );

        final json = item.toJson();

        expect(json['measuredAt'], '2026-07-10T08:30:00.000Z');
        expect(json.containsKey('note'), isFalse);
        expect(json.containsKey('context'), isFalse);
        expect(json['value'], 80);
      },
    );
  });
}
