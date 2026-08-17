import 'package:uuid/uuid.dart';

import 'package:myvitals_healthtracker_app/features/appointments/data/models/appointment.dart';

/// Lógica pura del ciclo de vida de una cita: cálculo de "vencida" (overdue),
/// transiciones de estado y —para los controles periódicos— la generación de la
/// siguiente ocurrencia "por sacar". No toca base de datos ni notificaciones;
/// recibe y devuelve [Appointment] inmutables para poder probarse sola. Quien la
/// use persiste el resultado con el repositorio.
class AppointmentStatusService {
  /// Suma [months] meses a [date] recortando el día al último válido del mes
  /// destino (ej. 31-ene + 1 mes → 28/29-feb, no un desbordamiento a marzo).
  /// Conserva la hora y los minutos.
  static DateTime addMonths(DateTime date, int months) {
    final totalMonth = date.month - 1 + months;
    final year = date.year + (totalMonth ~/ 12);
    final month = totalMonth % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day; // día 0 del mes siguiente.
    final day = date.day < lastDay ? date.day : lastDay;
    return DateTime(year, month, day, date.hour, date.minute);
  }

  /// Fecha sin componente horario (medianoche local), para comparar por día.
  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// ¿La cita está vencida (necesita acción y se pasó de fecha)?
  /// - `toBook`: su fecha objetivo ([Appointment.dueToBookOn]) ya pasó (por día).
  /// - `scheduled`: su fecha/hora ([Appointment.scheduledAt]) ya pasó sin
  ///   confirmarse asistencia.
  /// - resto de estados: nunca vencen.
  static bool isOverdue(Appointment a, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    switch (a.status) {
      case AppointmentStatus.toBook:
        final due = a.dueToBookOn;
        if (due == null) return false;
        return _dateOnly(due).isBefore(_dateOnly(ref));
      case AppointmentStatus.scheduled:
        final at = a.scheduledAt;
        if (at == null) return false;
        return at.isBefore(ref);
      case AppointmentStatus.attended:
      case AppointmentStatus.missed:
      case AppointmentStatus.cancelled:
        return false;
    }
  }

  /// Agenda una cita "por sacar": fija [scheduledAt], pasa a `scheduled` y limpia
  /// la fecha objetivo. No-op si la cita no estaba en `toBook`.
  static Appointment book(Appointment a, DateTime scheduledAt) {
    if (a.status != AppointmentStatus.toBook) return a;
    return a.copyWith(
      status: AppointmentStatus.scheduled,
      scheduledAt: scheduledAt,
      clearDueToBookOn: true,
      clearSnoozedUntil: true,
    );
  }

  /// Marca la cita como asistida (cierra la ocurrencia).
  static Appointment markAttended(Appointment a) =>
      a.copyWith(status: AppointmentStatus.attended, clearSnoozedUntil: true);

  /// Marca la cita como no asistida.
  static Appointment markMissed(Appointment a) =>
      a.copyWith(status: AppointmentStatus.missed, clearSnoozedUntil: true);

  /// Genera la SIGUIENTE cita "por sacar" de una serie recurrente, a partir de
  /// una ocurrencia recién cerrada ([closed], normalmente `attended` o `missed`).
  /// Devuelve null si la cita no es recurrente o le falta el intervalo.
  ///
  /// La fecha objetivo de la próxima es `[completedOn] + intervalMonths`. La
  /// nueva cita hereda identidad (título, especialidad, médico, notas), la
  /// recurrencia y los avisos, y comparte el `series_id` con las demás
  /// ocurrencias (se crea uno si aún no existía).
  static Appointment? nextRecurringOccurrence(
    Appointment closed, {
    DateTime? completedOn,
  }) {
    if (!closed.isRecurring) return null;
    final interval = closed.intervalMonths;
    if (interval == null || interval <= 0) return null;

    final base = completedOn ?? closed.scheduledAt ?? DateTime.now();
    final nextDue = addMonths(_dateOnly(base), interval);

    return Appointment(
      title: closed.title,
      specialty: closed.specialty,
      provider: closed.provider,
      location: closed.location,
      notes: closed.notes,
      status: AppointmentStatus.toBook,
      dueToBookOn: nextDue,
      isRecurring: true,
      intervalMonths: interval,
      leadDays: closed.leadDays,
      seriesId: closed.seriesId ?? const Uuid().v4(),
      reminderOffsets: closed.reminderOffsets,
    );
  }
}
