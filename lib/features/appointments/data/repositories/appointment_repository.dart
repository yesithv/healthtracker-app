import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/features/appointments/data/models/appointment.dart';

/// Repositorio del inventario de citas. Reutiliza el CRUD, la caché en memoria y
/// el flag `is_synced` de [RecordRepository]; solo declara su tabla, mappers, id
/// y orden (la tabla `appointments` no tiene `measurement_date`).
///
/// Los getters derivados (`toBook`, `scheduled`, `history`, `overdue`, `upcoming`)
/// leen de la caché en memoria, así que las pantallas pueden clasificar las citas
/// por estado sin volver a golpear SQLite.
class AppointmentRepository extends RecordRepository<Appointment> {
  AppointmentRepository._();
  static final AppointmentRepository instance = AppointmentRepository._();

  @override
  String get table => 'appointments';

  /// Orden estable para la lista: primero por fecha relevante (la agendada o la
  /// objetivo), NULLs al final, y desempate por título. Las secciones de la UI
  /// filtran por estado sobre esta base.
  @override
  String get orderBy =>
      'COALESCE(scheduled_at, due_to_book_on) ASC, title COLLATE NOCASE ASC';

  @override
  String get unsyncedOrderBy => 'created_at ASC';

  @override
  Appointment fromMap(Map<String, dynamic> map) => Appointment.fromMap(map);

  @override
  Map<String, dynamic> toMap(Appointment record) => record.toMap();

  @override
  String idOf(Appointment record) => record.id;

  /// Citas por sacar (recall), de la más próxima a agendar a la más lejana.
  List<Appointment> get toBook =>
      items.where((a) => a.status == AppointmentStatus.toBook).toList();

  /// Citas ya agendadas con fecha/hora.
  List<Appointment> get scheduled =>
      items.where((a) => a.status == AppointmentStatus.scheduled).toList();

  /// Citas cerradas (asistí / no asistí / anuladas): el historial.
  List<Appointment> get history => items
      .where(
        (a) =>
            a.status == AppointmentStatus.attended ||
            a.status == AppointmentStatus.missed ||
            a.status == AppointmentStatus.cancelled,
      )
      .toList();
}
