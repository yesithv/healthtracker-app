import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_dose.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_log.dart';

/// Round-trip de serialización y semántica de `copyWith` de los tres modelos.
/// Son datos que viajan a SQLite (0/1 para booleanos, ISO-8601 para fechas,
/// enums por nombre estable) y de vuelta; que un `toMap`→`fromMap` preserve todo
/// es la base de que la persistencia y la futura sincronización no corrompan nada.
void main() {
  group('Medication toMap/fromMap', () {
    test(
      'round-trips every field, including inventory and daysOfWeek bitmask',
      () {
        final original = Medication(
          id: 'm1',
          name: 'Vytorin',
          form: MedicationForm.tablet,
          strengthValue: 10,
          strengthUnit: 'mg',
          doseQuantity: 2,
          color: 'brand',
          shape: 'round',
          notes: 'con la cena',
          frequencyType: FrequencyType.daysOfWeek,
          daysOfWeek: 0x15, // lunes, miércoles, viernes (bits 0,2,4)
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 31),
          isActive: false,
          stockQuantity: 42,
          stockTrackingEnabled: true,
          refillThreshold: 5,
          refillLeadDays: 3,
          packSize: 30,
          refillAlertEnabled: false,
          refillSnoozedUntil: DateTime(2026, 2, 1),
        );

        final restored = Medication.fromMap(original.toMap());

        expect(restored.id, 'm1');
        expect(restored.name, 'Vytorin');
        expect(restored.form, MedicationForm.tablet);
        expect(restored.strengthValue, 10);
        expect(restored.strengthUnit, 'mg');
        expect(restored.doseQuantity, 2);
        expect(restored.color, 'brand');
        expect(restored.shape, 'round');
        expect(restored.notes, 'con la cena');
        expect(restored.frequencyType, FrequencyType.daysOfWeek);
        expect(restored.daysOfWeek, 0x15);
        expect(restored.startDate, DateTime(2026, 1, 1));
        expect(restored.endDate, DateTime(2026, 12, 31));
        expect(restored.isActive, false);
        expect(restored.stockQuantity, 42);
        expect(restored.stockTrackingEnabled, true);
        expect(restored.refillThreshold, 5);
        expect(restored.refillLeadDays, 3);
        expect(restored.packSize, 30);
        expect(restored.refillAlertEnabled, false);
        expect(restored.refillSnoozedUntil, DateTime(2026, 2, 1));
      },
    );

    test('MedicationForm.other survives the round-trip (regression)', () {
      // `other` es el sexto valor del enum; antes el asistente lo degradaba a
      // `drops` en la UI. En datos, guardarse por nombre debe preservarlo.
      final med = Medication(
        name: 'X',
        doseQuantity: 1,
        form: MedicationForm.other,
      );
      expect(Medication.fromMap(med.toMap()).form, MedicationForm.other);
    });

    test('unknown persisted enum names fall back to safe defaults', () {
      final map = Medication(name: 'X', doseQuantity: 1).toMap()
        ..['form'] = 'no-existe'
        ..['frequency_type'] = 'no-existe';
      final restored = Medication.fromMap(map);
      expect(restored.form, MedicationForm.other);
      expect(restored.frequencyType, FrequencyType.daily);
    });
  });

  group('Medication copyWith clear flags', () {
    test('clearRefillSnooze and clearEndDate null out their fields', () {
      final med = Medication(
        name: 'X',
        doseQuantity: 1,
        endDate: DateTime(2026, 12, 31),
        refillSnoozedUntil: DateTime(2026, 2, 1),
      );
      final cleared = med.copyWith(clearEndDate: true, clearRefillSnooze: true);
      expect(cleared.endDate, isNull);
      expect(cleared.refillSnoozedUntil, isNull);
    });

    test('clearing the frequency fields prevents stale schedule data', () {
      // daysOfWeek → daily: sin limpiar, `daysOfWeek` quedaría obsoleto.
      final weekly = Medication(
        name: 'X',
        doseQuantity: 1,
        frequencyType: FrequencyType.daysOfWeek,
        daysOfWeek: 0x2A,
      );
      final daily = weekly.copyWith(
        frequencyType: FrequencyType.daily,
        clearDaysOfWeek: true,
        clearIntervalDays: true,
        clearAnchorDate: true,
      );
      expect(daily.daysOfWeek, isNull);
      expect(daily.intervalDays, isNull);
      expect(daily.anchorDate, isNull);
    });

    test('without a clear flag, an unspecified field is preserved', () {
      final med = Medication(name: 'X', doseQuantity: 1, daysOfWeek: 0x2A);
      expect(med.copyWith(name: 'Y').daysOfWeek, 0x2A);
    });
  });

  group('MedicationDose toMap/fromMap', () {
    test('round-trips including optional quantity and notifId', () {
      final dose = MedicationDose(
        id: 'd1',
        medicationId: 'm1',
        hour: 20,
        minute: 30,
        quantity: 1.5,
        notifId: 200001,
      );
      final restored = MedicationDose.fromMap(dose.toMap());
      expect(restored.id, 'd1');
      expect(restored.medicationId, 'm1');
      expect(restored.hour, 20);
      expect(restored.minute, 30);
      expect(restored.quantity, 1.5);
      expect(restored.notifId, 200001);
    });

    test('null quantity round-trips as null', () {
      final dose = MedicationDose(medicationId: 'm1', hour: 8, minute: 0);
      expect(MedicationDose.fromMap(dose.toMap()).quantity, isNull);
    });
  });

  group('MedicationLog toMap/fromMap', () {
    test('round-trips a taken log with quantity and takenAt', () {
      final log = MedicationLog(
        id: 'l1',
        medicationId: 'm1',
        doseId: 'd1',
        scheduledAt: DateTime(2026, 8, 17, 8, 0),
        status: MedicationLogStatus.taken,
        takenAt: DateTime(2026, 8, 17, 8, 5),
        quantity: 2,
      );
      final restored = MedicationLog.fromMap(log.toMap());
      expect(restored.id, 'l1');
      expect(restored.medicationId, 'm1');
      expect(restored.doseId, 'd1');
      expect(restored.scheduledAt, DateTime(2026, 8, 17, 8, 0));
      expect(restored.status, MedicationLogStatus.taken);
      expect(restored.takenAt, DateTime(2026, 8, 17, 8, 5));
      expect(restored.quantity, 2);
      expect(restored.isTaken, isTrue);
    });

    test('a skipped log has no takenAt', () {
      final log = MedicationLog(
        medicationId: 'm1',
        scheduledAt: DateTime(2026, 8, 17, 8, 0),
        status: MedicationLogStatus.skipped,
      );
      final restored = MedicationLog.fromMap(log.toMap());
      expect(restored.status, MedicationLogStatus.skipped);
      expect(restored.takenAt, isNull);
      expect(restored.isTaken, isFalse);
    });
  });
}
