import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_dose.dart';
import 'package:myvitals_healthtracker_app/features/medications/domain/medication_scheduler.dart';

Medication _med({
  String? id,
  FrequencyType frequency = FrequencyType.daily,
  bool isActive = true,
  double doseQuantity = 1,
  double? stockQuantity,
  bool stockTrackingEnabled = false,
  double? refillThreshold,
  int? refillLeadDays,
  bool refillAlertEnabled = true,
}) {
  return Medication(
    id: id,
    name: 'Med-${id ?? 'x'}',
    doseQuantity: doseQuantity,
    frequencyType: frequency,
    isActive: isActive,
    stockQuantity: stockQuantity,
    stockTrackingEnabled: stockTrackingEnabled,
    refillThreshold: refillThreshold,
    refillLeadDays: refillLeadDays,
    refillAlertEnabled: refillAlertEnabled,
  );
}

MedicationDose _dose(String medId, int hour) =>
    MedicationDose(medicationId: medId, hour: hour, minute: 0);

List<PlannedNotification> _doseNotifs(List<PlannedNotification> plan) =>
    plan.where((p) => p.kind == MedicationNotificationKind.dose).toList();

List<PlannedNotification> _inventoryNotifs(List<PlannedNotification> plan) =>
    plan.where((p) => p.kind == MedicationNotificationKind.inventory).toList();

void main() {
  group('buildPlan - doses', () {
    test('materializes each future dose in the window with sequential ids', () {
      final med = _med(id: 'a');
      final plan = MedicationScheduler.buildPlan(
        medications: [med],
        dosesByMedication: {
          'a': [_dose('a', 8), _dose('a', 20)],
        },
        from: DateTime(2026, 8, 17, 0, 0),
        horizonDays: 1, // days 17 and 18 inclusive → 2 days × 2 doses
      );
      final doses = _doseNotifs(plan);
      expect(doses.length, 4);
      expect(doses.map((p) => p.id).toList(), [200000, 200001, 200002, 200003]);
      expect(doses.first.payload, startsWith('dose|a|'));
    });

    test('skips doses earlier than the reference instant', () {
      final med = _med(id: 'a');
      final plan = MedicationScheduler.buildPlan(
        medications: [med],
        dosesByMedication: {
          'a': [_dose('a', 8), _dose('a', 20)],
        },
        from: DateTime(2026, 8, 17, 12, 0), // noon
        horizonDays: 0, // only day 17
      );
      final doses = _doseNotifs(plan);
      expect(doses.length, 1);
      expect(doses.single.scheduledAt, DateTime(2026, 8, 17, 20, 0));
    });

    test('skips doses already logged', () {
      final med = _med(id: 'a');
      final plan = MedicationScheduler.buildPlan(
        medications: [med],
        dosesByMedication: {
          'a': [_dose('a', 20)],
        },
        from: DateTime(2026, 8, 17, 0, 0),
        horizonDays: 0,
        isAlreadyLogged: (medId, at) =>
            medId == 'a' && at == DateTime(2026, 8, 17, 20, 0),
      );
      expect(_doseNotifs(plan), isEmpty);
    });

    test('excludes inactive medications', () {
      final med = _med(id: 'a', isActive: false);
      final plan = MedicationScheduler.buildPlan(
        medications: [med],
        dosesByMedication: {
          'a': [_dose('a', 8)],
        },
        from: DateTime(2026, 8, 17, 0, 0),
        horizonDays: 3,
      );
      expect(_doseNotifs(plan), isEmpty);
    });

    test('uses provided localized text builder', () {
      final med = _med(id: 'a');
      final plan = MedicationScheduler.buildPlan(
        medications: [med],
        dosesByMedication: {
          'a': [_dose('a', 8)],
        },
        from: DateTime(2026, 8, 17, 0, 0),
        horizonDays: 0,
        doseText: (m, d) => (title: 'Take ${m.name}', body: 'Now'),
      );
      expect(_doseNotifs(plan).single.title, 'Take Med-a');
      expect(_doseNotifs(plan).single.body, 'Now');
    });
  });

  group('buildPlan - inventory', () {
    test('adds an alert when stock is at the threshold', () {
      final med = _med(
        id: 'a',
        stockQuantity: 3,
        stockTrackingEnabled: true,
        refillThreshold: 3,
      );
      final plan = MedicationScheduler.buildPlan(
        medications: [med],
        dosesByMedication: {
          'a': [_dose('a', 8)],
        },
        from: DateTime(2026, 8, 17, 8, 0),
        horizonDays: 0,
      );
      final inv = _inventoryNotifs(plan);
      expect(inv.length, 1);
      expect(inv.single.id, 800000);
      expect(inv.single.payload, 'inventory|a');
    });

    test('no inventory alert when tracking is off', () {
      final med = _med(
        id: 'a',
        stockQuantity: 1,
        stockTrackingEnabled: false,
        refillThreshold: 3,
      );
      final plan = MedicationScheduler.buildPlan(
        medications: [med],
        dosesByMedication: {
          'a': [_dose('a', 8)],
        },
        from: DateTime(2026, 8, 17, 0, 0),
        horizonDays: 0,
      );
      expect(_inventoryNotifs(plan), isEmpty);
    });

    test('healthy stock produces no immediate alert', () {
      final med = _med(
        id: 'a',
        stockQuantity: 100,
        stockTrackingEnabled: true,
        refillThreshold: 3,
        refillLeadDays: 3,
      );
      final plan = MedicationScheduler.buildPlan(
        medications: [med],
        dosesByMedication: {
          'a': [_dose('a', 8)],
        },
        from: DateTime(2026, 8, 17, 0, 0),
        horizonDays: 0,
      );
      // Far from the threshold: any scheduled alert must be in the future
      // (buy-by morning), never the "alert now" +1 minute case.
      for (final n in _inventoryNotifs(plan)) {
        expect(n.scheduledAt.isAfter(DateTime(2026, 8, 18)), isTrue);
      }
    });
  });
}
