import 'package:myvitals_healthtracker_app/features/appointments/data/models/appointment.dart';
import 'package:myvitals_healthtracker_app/features/appointments/domain/appointment_status_service.dart';

/// Nivel del semáforo de cumplimiento que ve el usuario.
/// - [green]: nada vencido ni inminente.
/// - [amber]: hay algo que atender pronto (dentro de la ventana).
/// - [red]: hay al menos una cita vencida (por sacar pasada de fecha o agendada
///   pasada sin confirmar).
enum ComplianceLevel { green, amber, red }

/// Lógica pura del índice de cumplimiento del inventario de citas. Para el MVP
/// alimenta un semáforo simple (guiado por el nº de vencidas) y la "próxima
/// acción"; las métricas numéricas más finas (tasa de asistencia) quedan
/// disponibles aquí para la Fase 2. No toca UI ni base de datos.
class AppointmentComplianceService {
  /// Citas abiertas (requieren acción): por sacar o agendadas.
  static bool _isOpen(Appointment a) =>
      a.status == AppointmentStatus.toBook ||
      a.status == AppointmentStatus.scheduled;

  /// Fecha relevante de una cita abierta: la objetivo (por sacar) o la agendada.
  static DateTime? _relevantDate(Appointment a) =>
      a.status == AppointmentStatus.toBook ? a.dueToBookOn : a.scheduledAt;

  /// Número de citas vencidas ahora mismo.
  static int overdueCount(List<Appointment> appointments, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    return appointments
        .where((a) => AppointmentStatusService.isOverdue(a, now: ref))
        .length;
  }

  /// Citas abiertas cuya fecha relevante cae dentro de los próximos [withinDays]
  /// días (sin contar las ya vencidas).
  static int dueSoonCount(
    List<Appointment> appointments, {
    DateTime? now,
    int withinDays = 7,
  }) {
    final ref = now ?? DateTime.now();
    final limit = ref.add(Duration(days: withinDays));
    return appointments.where((a) {
      if (!_isOpen(a)) return false;
      if (AppointmentStatusService.isOverdue(a, now: ref)) return false;
      final date = _relevantDate(a);
      return date != null && !date.isBefore(ref) && !date.isAfter(limit);
    }).length;
  }

  /// Semáforo de cumplimiento: rojo si hay algo vencido, ámbar si hay algo
  /// inminente (dentro de [soonWithinDays]), verde en caso contrario.
  static ComplianceLevel semaphore(
    List<Appointment> appointments, {
    DateTime? now,
    int soonWithinDays = 7,
  }) {
    final ref = now ?? DateTime.now();
    if (overdueCount(appointments, now: ref) > 0) return ComplianceLevel.red;
    if (dueSoonCount(appointments, now: ref, withinDays: soonWithinDays) > 0) {
      return ComplianceLevel.amber;
    }
    return ComplianceLevel.green;
  }

  /// La "próxima acción": la cita abierta más urgente. Prioriza las vencidas y,
  /// entre iguales, la de fecha relevante más temprana. Null si no hay nada
  /// pendiente.
  static Appointment? nextAction(List<Appointment> appointments, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final open = appointments.where(_isOpen).toList();
    if (open.isEmpty) return null;

    open.sort((a, b) {
      final aOver = AppointmentStatusService.isOverdue(a, now: ref);
      final bOver = AppointmentStatusService.isOverdue(b, now: ref);
      if (aOver != bOver) return aOver ? -1 : 1; // vencidas primero.
      final da = _relevantDate(a);
      final db = _relevantDate(b);
      if (da == null && db == null) return 0;
      if (da == null) return 1; // sin fecha, al final.
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return open.first;
  }

  /// Tasa de asistencia = asistidas / (asistidas + no asistidas), opcionalmente
  /// acotada a las cerradas desde [since]. Null si no hay citas cerradas
  /// evaluables (no se puede calcular una tasa sobre cero). Preparada para el
  /// detalle numérico de la Fase 2.
  static double? attendanceRate(
    List<Appointment> appointments, {
    DateTime? since,
  }) {
    var attended = 0;
    var missed = 0;
    for (final a in appointments) {
      if (since != null) {
        final when = a.scheduledAt ?? a.updatedAt;
        if (when.isBefore(since)) continue;
      }
      if (a.status == AppointmentStatus.attended) attended++;
      if (a.status == AppointmentStatus.missed) missed++;
    }
    final total = attended + missed;
    if (total == 0) return null;
    return attended / total;
  }
}
