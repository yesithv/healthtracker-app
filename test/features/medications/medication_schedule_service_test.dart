import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_dose.dart';
import 'package:myvitals_healthtracker_app/features/medications/domain/medication_schedule_service.dart';

/// Weekday bit helper mirroring the model: Monday = 1 → bit 0 … Sunday = 7 → bit 6.
int _bit(int weekday) => 1 << (weekday - 1);

Medication _med({
  FrequencyType frequency = FrequencyType.daily,
  int? daysOfWeek,
  int? intervalDays,
  DateTime? anchorDate,
  DateTime? startDate,
  DateTime? endDate,
  bool isActive = true,
  double doseQuantity = 1,
}) {
  return Medication(
    name: 'Test',
    doseQuantity: doseQuantity,
    frequencyType: frequency,
    daysOfWeek: daysOfWeek,
    intervalDays: intervalDays,
    anchorDate: anchorDate,
    startDate: startDate,
    endDate: endDate,
    isActive: isActive,
  );
}

MedicationDose _dose(String medId, int hour, int minute, {double? quantity}) {
  return MedicationDose(
    medicationId: medId,
    hour: hour,
    minute: minute,
    quantity: quantity,
  );
}

void main() {
  group('isDueOn - daily', () {
    test('due every day within bounds', () {
      final med = _med(frequency: FrequencyType.daily);
      expect(MedicationScheduleService.isDueOn(med, DateTime(2026, 8, 17)), isTrue);
      expect(MedicationScheduleService.isDueOn(med, DateTime(2026, 8, 18)), isTrue);
    });

    test('not due before startDate or after endDate', () {
      final med = _med(
        frequency: FrequencyType.daily,
        startDate: DateTime(2026, 8, 10),
        endDate: DateTime(2026, 8, 20),
      );
      expect(MedicationScheduleService.isDueOn(med, DateTime(2026, 8, 9)), isFalse);
      expect(MedicationScheduleService.isDueOn(med, DateTime(2026, 8, 10)), isTrue);
      expect(MedicationScheduleService.isDueOn(med, DateTime(2026, 8, 20)), isTrue);
      expect(MedicationScheduleService.isDueOn(med, DateTime(2026, 8, 21)), isFalse);
    });

    test('never due when inactive', () {
      final med = _med(frequency: FrequencyType.daily, isActive: false);
      expect(MedicationScheduleService.isDueOn(med, DateTime(2026, 8, 17)), isFalse);
    });
  });

  group('isDueOn - daysOfWeek', () {
    test('due only on the masked weekdays', () {
      // Monday + Wednesday + Thursday.
      final mask = _bit(DateTime.monday) |
          _bit(DateTime.wednesday) |
          _bit(DateTime.thursday);
      final med = _med(frequency: FrequencyType.daysOfWeek, daysOfWeek: mask);

      // Walk a full week and assert the mask decides membership.
      for (var i = 0; i < 7; i++) {
        final date = DateTime(2026, 8, 17).add(Duration(days: i));
        final expected = {
          DateTime.monday,
          DateTime.wednesday,
          DateTime.thursday,
        }.contains(date.weekday);
        expect(
          MedicationScheduleService.isDueOn(med, date),
          expected,
          reason: 'weekday ${date.weekday}',
        );
      }
    });

    test('empty or null mask is never due', () {
      expect(
        MedicationScheduleService.isDueOn(
          _med(frequency: FrequencyType.daysOfWeek, daysOfWeek: 0),
          DateTime(2026, 8, 17),
        ),
        isFalse,
      );
      expect(
        MedicationScheduleService.isDueOn(
          _med(frequency: FrequencyType.daysOfWeek, daysOfWeek: null),
          DateTime(2026, 8, 17),
        ),
        isFalse,
      );
    });
  });

  group('isDueOn - intervalDays (every N days)', () {
    test('due on anchor and every 8th day, not in between', () {
      final anchor = DateTime(2026, 1, 1);
      final med = _med(
        frequency: FrequencyType.intervalDays,
        intervalDays: 8,
        anchorDate: anchor,
      );
      expect(MedicationScheduleService.isDueOn(med, anchor), isTrue);
      expect(
        MedicationScheduleService.isDueOn(med, anchor.add(const Duration(days: 8))),
        isTrue,
      );
      expect(
        MedicationScheduleService.isDueOn(med, anchor.add(const Duration(days: 16))),
        isTrue,
      );
      for (final offset in [1, 2, 3, 4, 5, 6, 7]) {
        expect(
          MedicationScheduleService.isDueOn(
            med,
            anchor.add(Duration(days: offset)),
          ),
          isFalse,
          reason: 'offset $offset',
        );
      }
    });

    test('not due before the anchor date', () {
      final anchor = DateTime(2026, 1, 10);
      final med = _med(
        frequency: FrequencyType.intervalDays,
        intervalDays: 8,
        anchorDate: anchor,
      );
      expect(
        MedicationScheduleService.isDueOn(med, DateTime(2026, 1, 2)),
        isFalse,
      );
    });

    test('falls back to startDate when anchorDate is null', () {
      final med = _med(
        frequency: FrequencyType.intervalDays,
        intervalDays: 3,
        startDate: DateTime(2026, 5, 1),
      );
      expect(MedicationScheduleService.isDueOn(med, DateTime(2026, 5, 1)), isTrue);
      expect(MedicationScheduleService.isDueOn(med, DateTime(2026, 5, 4)), isTrue);
      expect(MedicationScheduleService.isDueOn(med, DateTime(2026, 5, 2)), isFalse);
    });
  });

  group('expectedDosesForDay', () {
    test('one ExpectedDose per dose, sorted by time, with correct datetime', () {
      final med = _med(frequency: FrequencyType.daily, doseQuantity: 2);
      final doses = [
        _dose(med.id, 20, 30), // later, listed first
        _dose(med.id, 8, 0),
      ];
      final result = MedicationScheduleService.expectedDosesForDay(
        med,
        doses,
        DateTime(2026, 8, 17),
      );
      expect(result.length, 2);
      expect(result.first.scheduledAt, DateTime(2026, 8, 17, 8, 0));
      expect(result.last.scheduledAt, DateTime(2026, 8, 17, 20, 30));
    });

    test('quantity falls back to medication doseQuantity when dose has none', () {
      final med = _med(frequency: FrequencyType.daily, doseQuantity: 2);
      final doses = [
        _dose(med.id, 8, 0), // no quantity → 2
        _dose(med.id, 20, 0, quantity: 1), // explicit → 1
      ];
      final result = MedicationScheduleService.expectedDosesForDay(
        med,
        doses,
        DateTime(2026, 8, 17),
      );
      expect(result[0].quantity, 2);
      expect(result[1].quantity, 1);
    });

    test('empty on a day that is not due, non-empty on a due day', () {
      final med = _med(
        frequency: FrequencyType.daysOfWeek,
        daysOfWeek: _bit(DateTime.sunday),
      );
      // 2026-08-17 es lunes (no toca) y 2026-08-16 es domingo (toca): fechas
      // fijas, sin la guarda condicional anterior que dejaba la aserción muda si
      // el día caía en domingo.
      final monday = DateTime(2026, 8, 17);
      final sunday = DateTime(2026, 8, 16);
      expect(monday.weekday, DateTime.monday);
      expect(sunday.weekday, DateTime.sunday);

      expect(
        MedicationScheduleService.expectedDosesForDay(
            med, [_dose(med.id, 8, 0)], monday),
        isEmpty,
      );
      expect(
        MedicationScheduleService.expectedDosesForDay(
            med, [_dose(med.id, 8, 0)], sunday),
        hasLength(1),
      );
    });
  });

  group('expectedDosesBetween', () {
    test('counts daily doses across an inclusive range', () {
      final med = _med(frequency: FrequencyType.daily);
      final doses = [_dose(med.id, 8, 0), _dose(med.id, 20, 0)];
      // 3 days inclusive × 2 doses = 6.
      final result = MedicationScheduleService.expectedDosesBetween(
        med,
        doses,
        DateTime(2026, 8, 17),
        DateTime(2026, 8, 19),
      );
      expect(result.length, 6);
    });
  });

  group('nextDose', () {
    test('returns the first dose at or after the reference instant', () {
      final med = _med(frequency: FrequencyType.daily);
      final doses = [_dose(med.id, 8, 0), _dose(med.id, 20, 30)];
      final next = MedicationScheduleService.nextDose(
        med,
        doses,
        DateTime(2026, 8, 17, 12, 0), // between the two doses
      );
      expect(next, isNotNull);
      expect(next!.scheduledAt, DateTime(2026, 8, 17, 20, 30));
    });
  });

  group('activeWeekdayCount', () {
    test('counts set bits', () {
      final mask = _bit(DateTime.monday) |
          _bit(DateTime.wednesday) |
          _bit(DateTime.thursday);
      expect(MedicationScheduleService.activeWeekdayCount(mask), 3);
      expect(MedicationScheduleService.activeWeekdayCount(0), 0);
      expect(MedicationScheduleService.activeWeekdayCount(null), 0);
    });
  });
}
