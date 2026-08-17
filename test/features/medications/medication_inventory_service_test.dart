import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_dose.dart';
import 'package:myvitals_healthtracker_app/features/medications/domain/medication_inventory_service.dart';

int _bit(int weekday) => 1 << (weekday - 1);

Medication _med({
  FrequencyType frequency = FrequencyType.daily,
  int? daysOfWeek,
  int? intervalDays,
  double doseQuantity = 1,
  double? stockQuantity,
  bool stockTrackingEnabled = true,
  double? refillThreshold,
  int? refillLeadDays,
  double? packSize,
  bool refillAlertEnabled = true,
  DateTime? refillSnoozedUntil,
}) {
  return Medication(
    name: 'Test',
    doseQuantity: doseQuantity,
    frequencyType: frequency,
    daysOfWeek: daysOfWeek,
    intervalDays: intervalDays,
    stockQuantity: stockQuantity,
    stockTrackingEnabled: stockTrackingEnabled,
    refillThreshold: refillThreshold,
    refillLeadDays: refillLeadDays,
    packSize: packSize,
    refillAlertEnabled: refillAlertEnabled,
    refillSnoozedUntil: refillSnoozedUntil,
  );
}

List<MedicationDose> _doses(String medId, List<double> quantities) {
  return [
    for (var i = 0; i < quantities.length; i++)
      MedicationDose(
        medicationId: medId,
        hour: 8 + i,
        minute: 0,
        quantity: quantities[i],
      ),
  ];
}

void main() {
  group('dailyConsumption', () {
    test('daily sums the dose quantities', () {
      final med = _med(frequency: FrequencyType.daily);
      final doses = _doses(med.id, [1, 1]);
      expect(MedicationInventoryService.dailyConsumption(med, doses), 2);
    });

    test('daysOfWeek scales by active days / 7', () {
      final mask = _bit(DateTime.monday) |
          _bit(DateTime.wednesday) |
          _bit(DateTime.thursday);
      final med = _med(frequency: FrequencyType.daysOfWeek, daysOfWeek: mask);
      final doses = _doses(med.id, [1, 1]); // 2 per intake day, 3 days/week
      expect(
        MedicationInventoryService.dailyConsumption(med, doses),
        closeTo(2 * 3 / 7, 1e-9),
      );
    });

    test('intervalDays divides by N', () {
      final med = _med(frequency: FrequencyType.intervalDays, intervalDays: 8);
      final doses = _doses(med.id, [1, 1]); // 2 every 8 days
      expect(
        MedicationInventoryService.dailyConsumption(med, doses),
        closeTo(2 / 8, 1e-9),
      );
    });

    test('zero when there are no doses', () {
      final med = _med(frequency: FrequencyType.daily);
      expect(MedicationInventoryService.dailyConsumption(med, const []), 0);
    });
  });

  group('daysRemaining', () {
    test('floors stock / daily consumption', () {
      final med = _med(frequency: FrequencyType.daily, stockQuantity: 30);
      final doses = _doses(med.id, [1, 1]); // 2/day → 15 days
      expect(MedicationInventoryService.daysRemaining(med, doses), 15);
    });

    test('null when tracking is off', () {
      final med = _med(
        frequency: FrequencyType.daily,
        stockQuantity: 30,
        stockTrackingEnabled: false,
      );
      expect(
        MedicationInventoryService.daysRemaining(med, _doses(med.id, [1])),
        isNull,
      );
    });

    test('null when consumption is zero', () {
      final med = _med(frequency: FrequencyType.daily, stockQuantity: 30);
      expect(MedicationInventoryService.daysRemaining(med, const []), isNull);
    });
  });

  group('runOutDate / buyByDate', () {
    test('run-out is today + days remaining; buy-by subtracts the lead', () {
      final today = DateTime(2026, 8, 17);
      final med = _med(
        frequency: FrequencyType.daily,
        stockQuantity: 30,
        refillLeadDays: 3,
      );
      final doses = _doses(med.id, [1, 1]); // 2/day → 15 days
      expect(
        MedicationInventoryService.runOutDate(med, doses, today: today),
        DateTime(2026, 9, 1), // 17 Aug + 15 days
      );
      expect(
        MedicationInventoryService.buyByDate(med, doses, today: today),
        DateTime(2026, 8, 29), // run-out - 3
      );
    });
  });

  group('shouldAlert', () {
    test('fires when stock is at or below the threshold', () {
      final med = _med(
        frequency: FrequencyType.daily,
        stockQuantity: 3,
        refillThreshold: 3,
      );
      expect(
        MedicationInventoryService.shouldAlert(med, _doses(med.id, [1])),
        isTrue,
      );
    });

    test('fires when days remaining fall within the lead window', () {
      final med = _med(
        frequency: FrequencyType.daily,
        stockQuantity: 5, // 5/day-ish
        refillLeadDays: 3,
      );
      // 1 unit/day → 5 days remaining; lead 3 → not yet... make it 2/day.
      final twoPerDay = _doses(med.id, [2]); // 2/day → 2 days remaining ≤ 3
      expect(
        MedicationInventoryService.shouldAlert(med, twoPerDay),
        isTrue,
      );
    });

    test('suppressed while snoozed', () {
      final today = DateTime(2026, 8, 17);
      final med = _med(
        frequency: FrequencyType.daily,
        stockQuantity: 1,
        refillThreshold: 3,
        refillSnoozedUntil: DateTime(2026, 8, 20),
      );
      expect(
        MedicationInventoryService.shouldAlert(
          med,
          _doses(med.id, [1]),
          today: today,
        ),
        isFalse,
      );
    });

    test('suppressed when alerts are disabled or tracking is off', () {
      expect(
        MedicationInventoryService.shouldAlert(
          _med(stockQuantity: 1, refillThreshold: 3, refillAlertEnabled: false),
          _doses('x', [1]),
        ),
        isFalse,
      );
      expect(
        MedicationInventoryService.shouldAlert(
          _med(
            stockQuantity: 1,
            refillThreshold: 3,
            stockTrackingEnabled: false,
          ),
          _doses('x', [1]),
        ),
        isFalse,
      );
    });

    test('does not fire with healthy stock and no lead breach', () {
      final med = _med(
        frequency: FrequencyType.daily,
        stockQuantity: 30,
        refillThreshold: 3,
        refillLeadDays: 3,
      );
      expect(MedicationInventoryService.shouldAlert(med, _doses(med.id, [1])), isFalse);
    });
  });

  group('applyIntake / revertIntake', () {
    test('applyIntake decrements and never goes below zero', () {
      final med = _med(stockQuantity: 2);
      expect(MedicationInventoryService.applyIntake(med, 2).stockQuantity, 0);
      expect(MedicationInventoryService.applyIntake(med, 5).stockQuantity, 0);
    });

    test('applyIntake is a no-op without tracking', () {
      final med = _med(stockQuantity: 10, stockTrackingEnabled: false);
      expect(MedicationInventoryService.applyIntake(med, 2).stockQuantity, 10);
    });

    test('revertIntake adds the quantity back', () {
      final med = _med(stockQuantity: 5);
      expect(MedicationInventoryService.revertIntake(med, 2).stockQuantity, 7);
    });
  });

  group('refill / snooze', () {
    test('refill adds pack_size by default and clears the snooze', () {
      final med = _med(
        stockQuantity: 2,
        packSize: 30,
        refillSnoozedUntil: DateTime(2026, 8, 20),
      );
      final refilled = MedicationInventoryService.refill(med);
      expect(refilled.stockQuantity, 32);
      expect(refilled.refillSnoozedUntil, isNull);
    });

    test('refill accepts an explicit amount', () {
      final med = _med(stockQuantity: 2, packSize: 30);
      expect(MedicationInventoryService.refill(med, amount: 20).stockQuantity, 22);
    });

    test('snoozeAlert sets the snooze date', () {
      final med = _med(stockQuantity: 1);
      final until = DateTime(2026, 8, 25);
      expect(
        MedicationInventoryService.snoozeAlert(med, until).refillSnoozedUntil,
        until,
      );
    });
  });
}
