import 'package:flutter/foundation.dart';

import 'package:myvitals_healthtracker_app/features/appointments/data/models/appointment.dart';
import 'package:myvitals_healthtracker_app/features/appointments/data/repositories/appointment_repository.dart';
import 'package:myvitals_healthtracker_app/features/appointments/domain/appointment_compliance_service.dart';
import 'package:myvitals_healthtracker_app/features/appointments/domain/appointment_scheduler.dart';
import 'package:myvitals_healthtracker_app/features/appointments/domain/appointment_status_service.dart';

/// Orquesta el inventario de citas: compone el repositorio y los servicios de
/// dominio para que las pantallas trabajen con operaciones de alto nivel (crear,
/// agendar, confirmar asistencia, posponer…) sin conocer la generación de la
/// siguiente ocurrencia recurrente ni la reprogramación de avisos.
///
/// Es un [ChangeNotifier] pero delega el estado en el repositorio (que ya
/// notifica); reexpone sus listas y las derivadas por comodidad de las pantallas.
class AppointmentsController extends ChangeNotifier {
  AppointmentsController({
    AppointmentRepository? repository,
    AppointmentScheduler? scheduler,
  })  : _repo = repository ?? AppointmentRepository.instance,
        _scheduler = scheduler ?? AppointmentScheduler() {
    _repo.addListener(_onRepoChanged);
  }

  final AppointmentRepository _repo;
  final AppointmentScheduler _scheduler;

  // Constructores de texto localizado de los avisos. La UI (que sí conoce la
  // localización) los inyecta con [setNotificationTextBuilders]; hasta entonces
  // el scheduler usa sus defaults en español.
  AppointmentTextBuilder? _scheduledText;
  AppointmentTextBuilder? _toBookText;
  AppointmentTextBuilder? _overdueText;

  void _onRepoChanged() => notifyListeners();

  /// Fija los textos localizados de las notificaciones (se llama al arrancar y al
  /// cambiar de idioma, antes de reprogramar).
  void setNotificationTextBuilders({
    AppointmentTextBuilder? scheduledText,
    AppointmentTextBuilder? toBookText,
    AppointmentTextBuilder? overdueText,
  }) {
    _scheduledText = scheduledText;
    _toBookText = toBookText;
    _overdueText = overdueText;
  }

  /// Recarga la caché del repositorio y reprograma los avisos. Se llama al
  /// arrancar y al volver de segundo plano: reprogramar con la caché vacía
  /// cancelaría los avisos sin volver a crearlos.
  Future<void> refreshAndReschedule() async {
    await _repo.refresh();
    await _reschedule();
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    super.dispose();
  }

  // --- Lecturas ---------------------------------------------------------------

  List<Appointment> get all => _repo.items;
  List<Appointment> get toBook => _repo.toBook;
  List<Appointment> get scheduled => _repo.scheduled;
  List<Appointment> get history => _repo.history;

  List<Appointment> overdue({DateTime? now}) => _repo.items
      .where((a) => AppointmentStatusService.isOverdue(a, now: now))
      .toList();

  ComplianceLevel semaphore({DateTime? now}) =>
      AppointmentComplianceService.semaphore(_repo.items, now: now);

  Appointment? nextAction({DateTime? now}) =>
      AppointmentComplianceService.nextAction(_repo.items, now: now);

  int overdueCount({DateTime? now}) =>
      AppointmentComplianceService.overdueCount(_repo.items, now: now);

  // --- Escrituras -------------------------------------------------------------

  /// Crea una cita ya agendada (con fecha y hora).
  Future<Appointment> addScheduled({
    required String title,
    required DateTime scheduledAt,
    String? specialty,
    String? provider,
    String? location,
    String? notes,
    bool isRecurring = false,
    int? intervalMonths,
    int? leadDays,
    List<int>? reminderOffsets,
  }) async {
    final appt = Appointment(
      title: title,
      scheduledAt: scheduledAt,
      status: AppointmentStatus.scheduled,
      specialty: specialty,
      provider: provider,
      location: location,
      notes: notes,
      isRecurring: isRecurring,
      intervalMonths: intervalMonths,
      leadDays: leadDays,
      reminderOffsets: reminderOffsets ?? Appointment.defaultReminderOffsets,
    );
    await _repo.insert(appt);
    await _reschedule();
    return appt;
  }

  /// Crea una cita "por sacar" (recall), con su fecha objetivo para agendarla.
  Future<Appointment> addToBook({
    required String title,
    required DateTime dueToBookOn,
    String? specialty,
    String? provider,
    String? location,
    String? notes,
    bool isRecurring = false,
    int? intervalMonths,
    int? leadDays,
    List<int>? reminderOffsets,
  }) async {
    final appt = Appointment(
      title: title,
      dueToBookOn: dueToBookOn,
      status: AppointmentStatus.toBook,
      specialty: specialty,
      provider: provider,
      location: location,
      notes: notes,
      isRecurring: isRecurring,
      intervalMonths: intervalMonths,
      leadDays: leadDays,
      reminderOffsets: reminderOffsets ?? Appointment.defaultReminderOffsets,
    );
    await _repo.insert(appt);
    await _reschedule();
    return appt;
  }

  /// Agenda una cita "por sacar": pasa a agendada con [scheduledAt].
  Future<void> book(Appointment appt, DateTime scheduledAt) async {
    await _repo.update(AppointmentStatusService.book(appt, scheduledAt));
    await _reschedule();
  }

  /// Marca la cita como asistida. Si es un control periódico, genera y guarda la
  /// siguiente cita "por sacar" de la serie.
  Future<void> markAttended(Appointment appt, {DateTime? completedOn}) async {
    await _repo.update(AppointmentStatusService.markAttended(appt));
    await _spawnNextIfRecurring(appt, completedOn: completedOn);
    await _reschedule();
  }

  /// Marca la cita como no asistida. Si es recurrente, igualmente genera la
  /// siguiente ocurrencia (el control sigue tocando aunque se perdiera una).
  Future<void> markMissed(Appointment appt, {DateTime? completedOn}) async {
    await _repo.update(AppointmentStatusService.markMissed(appt));
    await _spawnNextIfRecurring(appt, completedOn: completedOn);
    await _reschedule();
  }

  /// Silencia los avisos de una cita hasta [until] ("ya la saqué" / "recuérdame
  /// más adelante").
  Future<void> snooze(Appointment appt, DateTime until) async {
    await _repo.update(appt.copyWith(snoozedUntil: until));
    await _reschedule();
  }

  /// Reprograma una cita a una nueva fecha (mueve `scheduledAt` si está agendada,
  /// o la fecha objetivo si está por sacar).
  Future<void> postpone(Appointment appt, DateTime newDate) async {
    final updated = appt.status == AppointmentStatus.scheduled
        ? appt.copyWith(scheduledAt: newDate)
        : appt.copyWith(dueToBookOn: newDate);
    await _repo.update(updated);
    await _reschedule();
  }

  /// Guarda una edición arbitraria de la cita.
  Future<void> save(Appointment appt) async {
    await _repo.update(appt);
    await _reschedule();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await _reschedule();
  }

  /// Reprograma todos los avisos según el estado actual del inventario. Se llama
  /// al arrancar la app y al volver de segundo plano, además de tras cada cambio.
  Future<void> reschedule() => _reschedule();

  Future<void> _spawnNextIfRecurring(
    Appointment closed, {
    DateTime? completedOn,
  }) async {
    final next = AppointmentStatusService.nextRecurringOccurrence(
      closed,
      completedOn: completedOn,
    );
    if (next != null) await _repo.insert(next);
  }

  Future<void> _reschedule() => _scheduler.rescheduleAll(
        appointments: _repo.items,
        scheduledText: _scheduledText,
        toBookText: _toBookText,
        overdueText: _overdueText,
      );
}
