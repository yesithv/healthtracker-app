import 'package:myvitals_healthtracker_app/features/medications/data/models/medication.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_dose.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_log.dart';
import 'package:myvitals_healthtracker_app/features/medications/domain/medication_schedule_service.dart';

/// Estado de adherencia de un día natural, resumiendo todas las tomas esperadas
/// de todos los medicamentos activos ese día contra lo que realmente se registró.
enum MedDayStatus {
  /// No había ninguna toma esperada ese día (día "sin dato").
  noDoses,

  /// Hay tomas esperadas pero aún no resueltas y el día no ha pasado (hoy o
  /// futuro): todavía se pueden tomar, no cuenta como fallo.
  upcoming,

  /// Todas las tomas esperadas del día se marcaron como tomadas.
  allTaken,

  /// Algunas tomas se tomaron y otras no (omitidas o sin registrar en un día ya
  /// pasado).
  partial,

  /// Ninguna de las tomas esperadas se tomó en un día ya pasado.
  missed,
}

/// Un día de adherencia resuelto: número del día, su estado y banderas de pintado.
class MedAdherenceDay {
  const MedAdherenceDay({
    required this.date,
    required this.status,
    this.isToday = false,
    this.outOfMonth = false,
  });

  final DateTime date;
  final MedDayStatus status;
  final bool isToday;
  final bool outOfMonth;

  int get number => date.day;
}

/// Cálculo de adherencia: qué tan constante ha sido el usuario con su
/// tratamiento. Lógica **pura** y sin estado —no toca base de datos ni
/// notificaciones— sobre los medicamentos, sus horas de toma y los registros
/// reales, para poder probarse sola y alimentar tanto la vista "Adherencia"
/// como la tira semanal y el calendario.
///
/// Definición acordada: adherencia = tomadas ÷ esperadas del mes en curso;
/// racha = días consecutivos hacia atrás en los que se tomaron todas las
/// esperadas (los días sin tomas esperadas no rompen la racha).
class MedicationAdherenceService {
  MedicationAdherenceService({
    required List<Medication> medications,
    required Map<String, List<MedicationDose>> dosesByMedication,
    required List<MedicationLog> logs,
  }) : _meds = medications,
       _doses = dosesByMedication,
       _takenIndex = {
         for (final log in logs)
           if (log.status == MedicationLogStatus.taken)
             '${log.medicationId}|${log.scheduledAt.toIso8601String()}': true,
       };

  final List<Medication> _meds;
  final Map<String, List<MedicationDose>> _doses;

  /// Conjunto de tomas registradas como `taken`, indexado por
  /// `medId|scheduledAtIso` para resolver [_isTaken] en O(1). Antes era un
  /// escaneo lineal sobre todos los registros dentro de bucles anidados
  /// (racha: hasta 366 días × medicamentos × dosis), lo que resultaba cúbico.
  final Map<String, bool> _takenIndex;

  /// Tope de días que se retrocede al calcular la racha, para no iterar sin fin
  /// cuando ningún día tiene tomas esperadas (p. ej. una pauta que aún no empieza).
  static const int _streakLookbackCap = 366;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// ¿Está registrada como tomada la toma esperada [scheduledAt] de [medId]?
  bool _isTaken(String medId, DateTime scheduledAt) =>
      _takenIndex['$medId|${scheduledAt.toIso8601String()}'] ?? false;

  /// (esperadas, tomadas) del día [day] sumando todos los medicamentos activos.
  ({int expected, int taken}) _countsForDay(DateTime day) {
    var expected = 0;
    var taken = 0;
    for (final med in _meds) {
      if (!med.isActive) continue;
      final expectedDoses = MedicationScheduleService.expectedDosesForDay(
        med,
        _doses[med.id] ?? const [],
        day,
      );
      for (final e in expectedDoses) {
        expected++;
        if (_isTaken(med.id, e.scheduledAt)) taken++;
      }
    }
    return (expected: expected, taken: taken);
  }

  /// Estado de adherencia del día [day] respecto a [today] (por defecto, hoy).
  MedDayStatus statusForDay(DateTime day, {DateTime? today}) {
    final now = _dateOnly(today ?? DateTime.now());
    final d = _dateOnly(day);
    final counts = _countsForDay(d);

    if (counts.expected == 0) return MedDayStatus.noDoses;

    final isPast = d.isBefore(now);
    if (counts.taken == counts.expected) return MedDayStatus.allTaken;

    // Día de hoy o futuro con tomas aún por resolver: todavía a tiempo.
    if (!isPast) return MedDayStatus.upcoming;

    // Día ya pasado sin completar.
    return counts.taken == 0 ? MedDayStatus.missed : MedDayStatus.partial;
  }

  /// Adherencia del mes que contiene [month] (0–100), tomadas ÷ esperadas
  /// contando solo hasta [today]. 0 si no hubo ninguna toma esperada.
  int monthlyAdherence(DateTime month, {DateTime? today}) {
    final now = _dateOnly(today ?? DateTime.now());
    final first = DateTime(month.year, month.month, 1);
    final lastOfMonth = DateTime(month.year, month.month + 1, 0);
    // No se cuentan días futuros: aún no se pueden haber tomado.
    final last = lastOfMonth.isAfter(now) ? now : lastOfMonth;

    var expected = 0;
    var taken = 0;
    var day = first;
    while (!day.isAfter(last)) {
      final counts = _countsForDay(day);
      expected += counts.expected;
      taken += counts.taken;
      day = day.add(const Duration(days: 1));
    }

    if (expected == 0) return 0;
    return ((taken / expected) * 100).round();
  }

  /// Días consecutivos hacia atrás desde [today] con todas las tomas esperadas
  /// tomadas. Los días sin tomas esperadas se saltan (no cuentan ni rompen la
  /// racha). El día de hoy solo suma si ya está completo, pero si aún tiene
  /// tomas pendientes no rompe la racha (se sigue contando desde ayer).
  int currentStreak({DateTime? today}) {
    final now = _dateOnly(today ?? DateTime.now());
    var streak = 0;
    for (var i = 0; i < _streakLookbackCap; i++) {
      final day = now.subtract(Duration(days: i));
      final status = statusForDay(day, today: now);
      switch (status) {
        case MedDayStatus.noDoses:
          continue; // no rompe ni suma
        case MedDayStatus.allTaken:
          streak++;
        case MedDayStatus.upcoming:
          // Solo tolerado para hoy (aún a tiempo); en el pasado no ocurre.
          if (_sameDay(day, now)) continue;
          return streak;
        case MedDayStatus.partial:
        case MedDayStatus.missed:
          return streak;
      }
    }
    return streak;
  }

  /// Estados por día para la tira semanal: los [length] días que terminan en
  /// [anchor] (por defecto hoy), del más antiguo al más reciente.
  List<MedAdherenceDay> weekStates({DateTime? anchor, int length = 7}) {
    final now = _dateOnly(anchor ?? DateTime.now());
    final start = now.subtract(Duration(days: length - 1));
    final days = <MedAdherenceDay>[];
    for (var i = 0; i < length; i++) {
      final day = start.add(Duration(days: i));
      days.add(
        MedAdherenceDay(
          date: day,
          status: statusForDay(day, today: now),
          isToday: _sameDay(day, now),
        ),
      );
    }
    return days;
  }

  /// Rejilla del calendario mensual de [month]: semanas completas de lunes a
  /// domingo, con los días de meses vecinos marcados [outOfMonth]. Cada celda
  /// trae su estado de adherencia respecto a [today].
  List<MedAdherenceDay> monthGrid(DateTime month, {DateTime? today}) {
    final now = _dateOnly(today ?? DateTime.now());
    final first = DateTime(month.year, month.month, 1);
    final lastOfMonth = DateTime(month.year, month.month + 1, 0);

    // Retroceder hasta el lunes de la semana del día 1 (weekday: lunes=1).
    final leading = first.weekday - 1;
    final gridStart = first.subtract(Duration(days: leading));
    // Avanzar hasta el domingo de la semana del último día.
    final trailing = 7 - lastOfMonth.weekday;
    final gridEnd = lastOfMonth.add(Duration(days: trailing));

    final cells = <MedAdherenceDay>[];
    var day = gridStart;
    while (!day.isAfter(gridEnd)) {
      cells.add(
        MedAdherenceDay(
          date: day,
          status: statusForDay(day, today: now),
          isToday: _sameDay(day, now),
          outOfMonth: day.month != month.month,
        ),
      );
      day = day.add(const Duration(days: 1));
    }
    return cells;
  }
}
