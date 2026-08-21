import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_dose.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_log.dart';
import 'package:myvitals_healthtracker_app/features/medications/domain/medication_adherence_service.dart';

Medication _med({
  String? id,
  FrequencyType frequency = FrequencyType.daily,
  int? daysOfWeek,
  DateTime? startDate,
  bool isActive = true,
}) {
  return Medication(
    id: id,
    name: 'Test',
    doseQuantity: 1,
    frequencyType: frequency,
    daysOfWeek: daysOfWeek,
    startDate: startDate,
    isActive: isActive,
  );
}

MedicationDose _dose(String medId, int hour) =>
    MedicationDose(medicationId: medId, hour: hour, minute: 0);

MedicationLog _log(
  String medId,
  DateTime scheduledAt,
  MedicationLogStatus status,
) => MedicationLog(
  medicationId: medId,
  scheduledAt: scheduledAt,
  status: status,
);

MedicationAdherenceService _service({
  required List<Medication> meds,
  required Map<String, List<MedicationDose>> doses,
  required List<MedicationLog> logs,
}) => MedicationAdherenceService(
  medications: meds,
  dosesByMedication: doses,
  logs: logs,
);

void main() {
  // Un medicamento diario con una toma a las 08:00.
  Medication med(String id) => _med(id: id, startDate: DateTime(2026, 1, 1));

  group('statusForDay', () {
    test('noDoses when nothing is expected', () {
      final m = med('a');
      final svc = _service(meds: [m], doses: {'a': []}, logs: []);
      expect(
        svc.statusForDay(DateTime(2026, 8, 10), today: DateTime(2026, 8, 15)),
        MedDayStatus.noDoses,
      );
    });

    test('allTaken when the expected dose was taken', () {
      final m = med('a');
      final sched = DateTime(2026, 8, 10, 8, 0);
      final svc = _service(
        meds: [m],
        doses: {
          'a': [_dose('a', 8)],
        },
        logs: [_log('a', sched, MedicationLogStatus.taken)],
      );
      expect(
        svc.statusForDay(DateTime(2026, 8, 10), today: DateTime(2026, 8, 15)),
        MedDayStatus.allTaken,
      );
    });

    test('missed on a past day with nothing taken', () {
      final m = med('a');
      final svc = _service(
        meds: [m],
        doses: {
          'a': [_dose('a', 8)],
        },
        logs: [],
      );
      expect(
        svc.statusForDay(DateTime(2026, 8, 10), today: DateTime(2026, 8, 15)),
        MedDayStatus.missed,
      );
    });

    test('partial on a past day with some taken', () {
      final m = med('a');
      final s8 = DateTime(2026, 8, 10, 8, 0);
      final svc = _service(
        meds: [m],
        doses: {
          'a': [_dose('a', 8), _dose('a', 20)],
        },
        logs: [_log('a', s8, MedicationLogStatus.taken)],
      );
      expect(
        svc.statusForDay(DateTime(2026, 8, 10), today: DateTime(2026, 8, 15)),
        MedDayStatus.partial,
      );
    });

    test('upcoming for today when not yet fully taken', () {
      final m = med('a');
      final svc = _service(
        meds: [m],
        doses: {
          'a': [_dose('a', 8)],
        },
        logs: [],
      );
      expect(
        svc.statusForDay(DateTime(2026, 8, 15), today: DateTime(2026, 8, 15)),
        MedDayStatus.upcoming,
      );
    });
  });

  group('monthlyAdherence', () {
    test('taken / expected up to today, rounded', () {
      final m = med('a');
      // Del 1 al 4 de agosto (today = 4): 4 esperadas, 3 tomadas → 75%.
      final logs = [
        _log('a', DateTime(2026, 8, 1, 8), MedicationLogStatus.taken),
        _log('a', DateTime(2026, 8, 2, 8), MedicationLogStatus.taken),
        _log('a', DateTime(2026, 8, 3, 8), MedicationLogStatus.skipped),
        _log('a', DateTime(2026, 8, 4, 8), MedicationLogStatus.taken),
      ];
      final svc = _service(
        meds: [m],
        doses: {
          'a': [_dose('a', 8)],
        },
        logs: logs,
      );
      expect(
        svc.monthlyAdherence(DateTime(2026, 8, 1), today: DateTime(2026, 8, 4)),
        75,
      );
    });

    test('0 when nothing is expected', () {
      final m = med('a');
      final svc = _service(meds: [m], doses: {'a': []}, logs: []);
      expect(
        svc.monthlyAdherence(DateTime(2026, 8, 1), today: DateTime(2026, 8, 4)),
        0,
      );
    });

    test('future days in the month are not counted', () {
      final m = med('a');
      // today = 2 ago: solo cuentan días 1 y 2. Ambos tomados → 100%.
      final logs = [
        _log('a', DateTime(2026, 8, 1, 8), MedicationLogStatus.taken),
        _log('a', DateTime(2026, 8, 2, 8), MedicationLogStatus.taken),
      ];
      final svc = _service(
        meds: [m],
        doses: {
          'a': [_dose('a', 8)],
        },
        logs: logs,
      );
      expect(
        svc.monthlyAdherence(DateTime(2026, 8, 1), today: DateTime(2026, 8, 2)),
        100,
      );
    });
  });

  group('currentStreak', () {
    test('counts consecutive fully-taken days back from today', () {
      final m = med('a');
      final logs = [
        for (final day in [13, 14, 15])
          _log('a', DateTime(2026, 8, day, 8), MedicationLogStatus.taken),
      ];
      final svc = _service(
        meds: [m],
        doses: {
          'a': [_dose('a', 8)],
        },
        logs: logs,
      );
      expect(svc.currentStreak(today: DateTime(2026, 8, 15)), 3);
    });

    test('a missed past day breaks the streak', () {
      final m = med('a');
      final logs = [
        _log('a', DateTime(2026, 8, 15, 8), MedicationLogStatus.taken),
        // 14 ago: no tomado → rompe.
        _log('a', DateTime(2026, 8, 13, 8), MedicationLogStatus.taken),
      ];
      final svc = _service(
        meds: [m],
        doses: {
          'a': [_dose('a', 8)],
        },
        logs: logs,
      );
      expect(svc.currentStreak(today: DateTime(2026, 8, 15)), 1);
    });

    test('today not yet taken does not break the streak', () {
      final m = med('a');
      // Hoy (15) sin tomar aún; 14 y 13 tomados → racha 2.
      final logs = [
        _log('a', DateTime(2026, 8, 14, 8), MedicationLogStatus.taken),
        _log('a', DateTime(2026, 8, 13, 8), MedicationLogStatus.taken),
      ];
      final svc = _service(
        meds: [m],
        doses: {
          'a': [_dose('a', 8)],
        },
        logs: logs,
      );
      expect(svc.currentStreak(today: DateTime(2026, 8, 15)), 2);
    });

    test('days with no expected doses do not break the streak', () {
      // Pauta lunes y miércoles (bits 0 y 2). Los martes no cuentan.
      final m = _med(
        id: 'a',
        frequency: FrequencyType.daysOfWeek,
        daysOfWeek: (1 << 0) | (1 << 2),
        startDate: DateTime(2026, 1, 1),
      );
      // 2026-08-17 es lunes; 08-19 miércoles; 08-24 lunes.
      final logs = [
        _log('a', DateTime(2026, 8, 17, 8), MedicationLogStatus.taken),
        _log('a', DateTime(2026, 8, 19, 8), MedicationLogStatus.taken),
        _log('a', DateTime(2026, 8, 24, 8), MedicationLogStatus.taken),
      ];
      final svc = _service(
        meds: [m],
        doses: {
          'a': [_dose('a', 8)],
        },
        logs: logs,
      );
      // Desde el 24 (lunes) hacia atrás: 24, 19, 17 → 3.
      expect(svc.currentStreak(today: DateTime(2026, 8, 24)), 3);
    });

    test('no meds gives zero without looping forever', () {
      final svc = _service(meds: [], doses: {}, logs: []);
      expect(svc.currentStreak(today: DateTime(2026, 8, 15)), 0);
    });
  });

  group('monthGrid / weekStates', () {
    test('monthGrid covers whole weeks Mon..Sun and flags out-of-month', () {
      final m = med('a');
      final svc = _service(
        meds: [m],
        doses: {
          'a': [_dose('a', 8)],
        },
        logs: [],
      );
      final grid = svc.monthGrid(
        DateTime(2026, 8, 1),
        today: DateTime(2026, 8, 15),
      );
      // Agosto 2026: día 1 = sábado; la rejilla empieza el lunes previo (27 jul).
      expect(grid.length % 7, 0);
      expect(grid.first.outOfMonth, isTrue);
      expect(grid.first.date, DateTime(2026, 7, 27));
      expect(grid.any((c) => c.isToday && c.number == 15), isTrue);
    });

    test('weekStates returns the last N days ending today', () {
      final m = med('a');
      final svc = _service(
        meds: [m],
        doses: {
          'a': [_dose('a', 8)],
        },
        logs: [],
      );
      final week = svc.weekStates(anchor: DateTime(2026, 8, 15), length: 7);
      expect(week.length, 7);
      expect(week.first.date, DateTime(2026, 8, 9));
      expect(week.last.isToday, isTrue);
    });
  });
}
