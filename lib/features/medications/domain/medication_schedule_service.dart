import 'package:myvitals_healthtracker_app/features/medications/data/models/medication.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_dose.dart';

/// Una toma esperada concreta: qué medicamento, a qué hora programada y cuántas
/// unidades. Se calcula desde la pauta (no se guarda en base de datos).
class ExpectedDose {
  final Medication medication;

  /// La hora de toma de la que sale. Null solo si el medicamento no tiene horas
  /// configuradas (no debería ocurrir en la práctica).
  final MedicationDose? dose;

  /// Fecha + hora previstas de la toma.
  final DateTime scheduledAt;

  /// Unidades a tomar (la de la dosis, o la del medicamento por defecto).
  final double quantity;

  const ExpectedDose({
    required this.medication,
    required this.dose,
    required this.scheduledAt,
    required this.quantity,
  });
}

/// Resuelve la pauta de un medicamento a tomas concretas. Es lógica pura y sin
/// estado: no toca base de datos ni notificaciones, para poder probarla sola y
/// reutilizarla tanto en la pantalla "Hoy" como en el planificador de avisos.
class MedicationScheduleService {
  /// Fecha sin hora, en UTC, para contar días de forma exacta sin que el horario
  /// de verano (días de 23/25 h) desvíe la diferencia.
  static DateTime _dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  /// Días enteros entre dos fechas (b - a), ignorando la hora.
  static int _daysBetween(DateTime a, DateTime b) =>
      _dateOnly(b).difference(_dateOnly(a)).inDays;

  /// ¿El medicamento [med] tiene toma en el día natural [date]? Respeta que esté
  /// activo y dentro de [Medication.startDate]–[Medication.endDate]. Ignora la
  /// hora: decide únicamente el día.
  static bool isDueOn(Medication med, DateTime date) {
    if (!med.isActive) return false;

    final day = _dateOnly(date);

    if (med.startDate != null && day.isBefore(_dateOnly(med.startDate!))) {
      return false;
    }
    if (med.endDate != null && day.isAfter(_dateOnly(med.endDate!))) {
      return false;
    }

    switch (med.frequencyType) {
      case FrequencyType.daily:
        return true;

      case FrequencyType.daysOfWeek:
        final mask = med.daysOfWeek;
        if (mask == null || mask == 0) return false;
        // DateTime.weekday: lunes = 1 … domingo = 7 → bit weekday - 1.
        final bit = 1 << (date.weekday - 1);
        return (mask & bit) != 0;

      case FrequencyType.intervalDays:
        final interval = med.intervalDays;
        if (interval == null || interval <= 0) return false;
        final anchor = med.anchorDate ?? med.startDate;
        if (anchor == null) return false;
        final delta = _daysBetween(anchor, date);
        if (delta < 0) return false; // antes de la fecha base
        return delta % interval == 0;
    }
  }

  /// Las tomas esperadas de [med] en el día [date], una por cada hora de
  /// [doses], ordenadas por hora. Vacío si el día no toca.
  static List<ExpectedDose> expectedDosesForDay(
    Medication med,
    List<MedicationDose> doses,
    DateTime date,
  ) {
    if (!isDueOn(med, date)) return const [];

    final sorted = [...doses]
      ..sort((a, b) {
        final byHour = a.hour.compareTo(b.hour);
        return byHour != 0 ? byHour : a.minute.compareTo(b.minute);
      });

    return sorted
        .map(
          (dose) => ExpectedDose(
            medication: med,
            dose: dose,
            scheduledAt: DateTime(
              date.year,
              date.month,
              date.day,
              dose.hour,
              dose.minute,
            ),
            quantity: dose.quantity ?? med.doseQuantity,
          ),
        )
        .toList();
  }

  /// Todas las tomas esperadas de [med] entre [from] y [to], ambos inclusive por
  /// día natural. Útil para materializar las próximas ocurrencias de cara a las
  /// notificaciones (sobre todo para las pautas "cada N días", que el plugin no
  /// repite de forma nativa) y para pintar el calendario de adherencia.
  static List<ExpectedDose> expectedDosesBetween(
    Medication med,
    List<MedicationDose> doses,
    DateTime from,
    DateTime to,
  ) {
    final result = <ExpectedDose>[];
    var day = _dateOnly(from);
    final last = _dateOnly(to);
    // Iterar en UTC-midnight evita el desfase por horario de verano; se
    // reconstruye la fecha local al calcular cada `scheduledAt`.
    while (!day.isAfter(last)) {
      final localDay = DateTime(day.year, day.month, day.day);
      result.addAll(expectedDosesForDay(med, doses, localDay));
      day = day.add(const Duration(days: 1));
    }
    return result;
  }

  /// La siguiente toma esperada de [med] a partir de [from] (inclusive), o null
  /// si no hay ninguna dentro de [lookaheadDays]. Sirve para la tarjeta
  /// "próxima toma" del Dashboard.
  static ExpectedDose? nextDose(
    Medication med,
    List<MedicationDose> doses,
    DateTime from, {
    int lookaheadDays = 60,
  }) {
    final horizon = from.add(Duration(days: lookaheadDays));
    final candidates =
        expectedDosesBetween(
            med,
            doses,
            from,
            horizon,
          ).where((e) => !e.scheduledAt.isBefore(from)).toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return candidates.isEmpty ? null : candidates.first;
  }

  /// Nº de días activos por semana de una pauta [FrequencyType.daysOfWeek]
  /// (popcount de la máscara sobre 7 bits). 0 si no aplica.
  static int activeWeekdayCount(int? mask) {
    if (mask == null) return 0;
    var count = 0;
    for (var i = 0; i < 7; i++) {
      if ((mask & (1 << i)) != 0) count++;
    }
    return count;
  }
}
