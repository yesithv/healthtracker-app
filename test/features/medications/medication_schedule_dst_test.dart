import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_dose.dart';
import 'package:myvitals_healthtracker_app/features/medications/domain/medication_schedule_service.dart';

/// El servicio cuenta días con aritmética en UTC (`_dateOnly`/`_daysBetween`)
/// justamente para que los días de 23/25 h del cambio de horario no desvíen la
/// cuenta. Estas pruebas cruzan una ventana que en muchas zonas contiene una
/// transición de horario de verano y verifican que no se pierde ni se duplica
/// ningún día. Son deterministas: no dependen de la zona horaria de la máquina,
/// porque el conteo de días naturales es independiente de ella.
Medication _med({
  FrequencyType frequency = FrequencyType.daily,
  int? intervalDays,
  DateTime? anchorDate,
}) {
  return Medication(
    id: 'a',
    name: 'Med',
    doseQuantity: 1,
    frequencyType: frequency,
    intervalDays: intervalDays,
    anchorDate: anchorDate,
    startDate: DateTime(2026, 1, 1),
  );
}

MedicationDose _dose(int hour) =>
    MedicationDose(medicationId: 'a', hour: hour, minute: 0);

void main() {
  group('conteo de días estable a través del cambio de horario', () {
    test('pauta diaria: una toma por cada día natural del tramo de marzo', () {
      // 2026-03-08 es el cambio de horario de primavera en varias zonas.
      final med = _med();
      final doses = [_dose(8)];
      final from = DateTime(2026, 3, 1);
      final to = DateTime(2026, 3, 31);

      final expected =
          MedicationScheduleService.expectedDosesBetween(med, doses, from, to);

      // 31 días × 1 toma, sin faltar ni sobrar por el día de 23 h.
      expect(expected.length, 31);
      // Cada toma cae en su día, en orden, sin huecos.
      for (var i = 0; i < 31; i++) {
        expect(expected[i].scheduledAt, DateTime(2026, 3, 1 + i, 8, 0));
      }
    });

    test('pauta "cada 2 días": el paso no deriva al cruzar el cambio', () {
      final anchor = DateTime(2026, 3, 1);
      final med = _med(
        frequency: FrequencyType.intervalDays,
        intervalDays: 2,
        anchorDate: anchor,
      );

      // Días pares desde el ancla (1, 3, 5, …) tocan; los impares no, incluido
      // el mismísimo día del cambio de horario si cae en uno impar.
      for (var day = 1; day <= 15; day++) {
        final date = DateTime(2026, 3, day, 12, 0);
        final isDue = MedicationScheduleService.isDueOn(med, date);
        expect(isDue, (day - 1) % 2 == 0,
            reason: 'día 2026-03-$day debería ${(day - 1) % 2 == 0 ? '' : 'NO '}tocar');
      }
    });

    test('pauta diaria a través del cambio de otoño (día de 25 h)', () {
      // 2026-11-01 es el retorno del horario de verano en varias zonas.
      final med = _med();
      final doses = [_dose(9)];
      final expected = MedicationScheduleService.expectedDosesBetween(
        med,
        doses,
        DateTime(2026, 10, 25),
        DateTime(2026, 11, 5),
      );
      // 12 días naturales inclusive, uno por día.
      expect(expected.length, 12);
      expect(expected.first.scheduledAt, DateTime(2026, 10, 25, 9, 0));
      expect(expected.last.scheduledAt, DateTime(2026, 11, 5, 9, 0));
    });
  });
}
