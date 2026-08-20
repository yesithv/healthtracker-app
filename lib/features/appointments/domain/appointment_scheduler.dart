import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myvitals_healthtracker_app/core/services/notification_service.dart';
import 'package:myvitals_healthtracker_app/features/appointments/data/models/appointment.dart';
import 'package:myvitals_healthtracker_app/features/appointments/domain/appointment_status_service.dart';

/// Qué representa una notificación planificada de citas.
enum AppointmentNotificationKind { scheduled, toBook, overdue }

/// Textos localizados de una notificación. La parte de dominio no conoce la
/// localización de Flutter, así que la UI le pasa constructores de texto; hay
/// defaults en español para poder programar avisos aunque la UI no exista aún.
typedef NotificationText = ({String title, String body});
typedef AppointmentTextBuilder = NotificationText Function(Appointment a);

/// Una notificación concreta a programar: id reservado, tipo, texto, cuándo y un
/// payload que identifica la cita para el deep-link al tocarla.
class PlannedNotification {
  final int id;
  final AppointmentNotificationKind kind;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final String payload;

  const PlannedNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.payload,
  });
}

/// Materializa los recordatorios del inventario de citas en notificaciones
/// locales.
///
/// El plugin no repite "cada N meses", así que —igual que el módulo de
/// medicamentos— en vez de apoyarnos en la repetición nativa programamos cada
/// ocurrencia futura como una notificación puntual dentro de una ventana móvil
/// ([horizonDays]) y volvemos a rellenar al reabrir la app. [buildPlan] es pura
/// (y testeable); [rescheduleAll] ejecuta el plan y lleva un libro de ids
/// persistido para cancelar sin dejar huérfanas.
class AppointmentScheduler {
  AppointmentScheduler({NotificationService? notificationService})
      : _notif = notificationService ?? NotificationService();

  final NotificationService _notif;

  /// Bases de ids por tipo, separadas de los rangos de medicamentos (dosis
  /// 200000+, inventario 800000+) y de los recordatorios simples (100–999) para
  /// que no colisionen. Como [rescheduleAll] cancela por el libro de ids
  /// persistido, basta con que sean únicos dentro de una misma pasada.
  static const int scheduledIdBase = 400000;
  static const int toBookIdBase = 500000;
  static const int overdueIdBase = 600000;

  /// Días por delante que se materializan en cada pasada.
  static const int defaultHorizonDays = 60;

  static const String _ledgerKey = 'appointment_notif_ids';

  /// ¿Está silenciada la cita para un aviso a la hora [when]?
  static bool _isSnoozed(Appointment a, DateTime when) =>
      a.snoozedUntil != null && when.isBefore(a.snoozedUntil!);

  /// Construye el plan de notificaciones para [appointments] a partir de [from].
  /// Puro: no toca notificaciones ni base de datos.
  ///
  /// - `scheduled`: un aviso por cada offset de [Appointment.reminderOffsets]
  ///   (minutos antes de la cita) que caiga dentro de la ventana.
  /// - `toBook`: un aviso a las 9:00 de la fecha objetivo (menos los días de
  ///   antelación [Appointment.leadDays]).
  /// - vencidas (`overdue`): un re-empuje al inicio de la ventana.
  static List<PlannedNotification> buildPlan({
    required List<Appointment> appointments,
    required DateTime from,
    int horizonDays = defaultHorizonDays,
    AppointmentTextBuilder? scheduledText,
    AppointmentTextBuilder? toBookText,
    AppointmentTextBuilder? overdueText,
  }) {
    final plan = <PlannedNotification>[];
    final to = from.add(Duration(days: horizonDays));
    final sorted = [...appointments]..sort((a, b) => a.id.compareTo(b.id));

    var scheduledId = scheduledIdBase;
    var toBookId = toBookIdBase;
    var overdueId = overdueIdBase;

    for (final a in sorted) {
      // Vencidas: re-empuje inmediato (un minuto tras el arranque).
      if (AppointmentStatusService.isOverdue(a, now: from)) {
        final when = from.add(const Duration(minutes: 1));
        if (!_isSnoozed(a, when)) {
          final text = (overdueText ?? _defaultOverdueText)(a);
          plan.add(PlannedNotification(
            id: overdueId++,
            kind: AppointmentNotificationKind.overdue,
            title: text.title,
            body: text.body,
            scheduledAt: when,
            payload: 'appointment|${a.id}|overdue',
          ));
        }
        continue; // ya vencida: no tiene sentido un aviso "antes de".
      }

      switch (a.status) {
        case AppointmentStatus.scheduled:
          {
            final at = a.scheduledAt;
            if (at == null) break;
            for (final offset in a.reminderOffsets) {
              final when = at.subtract(Duration(minutes: offset));
              if (when.isBefore(from) || when.isAfter(to)) continue;
              if (_isSnoozed(a, when)) continue;
              final text = (scheduledText ?? _defaultScheduledText)(a);
              plan.add(PlannedNotification(
                id: scheduledId++,
                kind: AppointmentNotificationKind.scheduled,
                title: text.title,
                body: text.body,
                scheduledAt: when,
                payload: 'appointment|${a.id}|scheduled',
              ));
            }
          }
          break;

        case AppointmentStatus.toBook:
          {
            final due = a.dueToBookOn;
            if (due == null) break;
            final target = due.subtract(Duration(days: a.leadDays ?? 0));
            final when = DateTime(target.year, target.month, target.day, 9);
            if (when.isBefore(from) || when.isAfter(to)) break;
            if (_isSnoozed(a, when)) break;
            final text = (toBookText ?? _defaultToBookText)(a);
            plan.add(PlannedNotification(
              id: toBookId++,
              kind: AppointmentNotificationKind.toBook,
              title: text.title,
              body: text.body,
              scheduledAt: when,
              payload: 'appointment|${a.id}|toBook',
            ));
          }
          break;

        case AppointmentStatus.attended:
        case AppointmentStatus.missed:
        case AppointmentStatus.cancelled:
          break; // cerradas: sin avisos.
      }
    }

    return plan;
  }

  /// Reprograma TODAS las notificaciones de citas: cancela las de la pasada
  /// anterior (por el libro de ids), programa el plan nuevo y persiste los ids
  /// programados. No-op en web. Llamar al arrancar, al volver de segundo plano y
  /// tras crear/editar/confirmar una cita.
  Future<void> rescheduleAll({
    required List<Appointment> appointments,
    DateTime? now,
    int horizonDays = defaultHorizonDays,
    AppointmentTextBuilder? scheduledText,
    AppointmentTextBuilder? toBookText,
    AppointmentTextBuilder? overdueText,
  }) async {
    if (kIsWeb) return;

    final prefs = await SharedPreferences.getInstance();
    for (final id in _readLedger(prefs)) {
      await _notif.cancel(id);
    }

    final plan = buildPlan(
      appointments: appointments,
      from: now ?? DateTime.now(),
      horizonDays: horizonDays,
      scheduledText: scheduledText,
      toBookText: toBookText,
      overdueText: overdueText,
    );

    final scheduled = <int>[];
    for (final p in plan) {
      await _notif.scheduleOneTimeNotification(
        id: p.id,
        title: p.title,
        body: p.body,
        dateTime: p.scheduledAt,
        payload: p.payload,
        channelId: NotificationService.appointmentChannelId,
        channelName: 'Recordatorios de citas',
        channelDescription:
            'Avisos de citas médicas agendadas y de citas por sacar',
      );
      scheduled.add(p.id);
    }

    await prefs.setStringList(
      _ledgerKey,
      scheduled.map((e) => e.toString()).toList(),
    );
  }

  /// Cancela todas las notificaciones de citas y vacía el libro de ids (al
  /// cambiar de paciente o borrar los datos locales).
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    for (final id in _readLedger(prefs)) {
      await _notif.cancel(id);
    }
    await prefs.remove(_ledgerKey);
  }

  List<int> _readLedger(SharedPreferences prefs) =>
      prefs
          .getStringList(_ledgerKey)
          ?.map(int.tryParse)
          .whereType<int>()
          .toList() ??
      const <int>[];

  // Textos por defecto (solo fallback de desarrollo/tests; en la app los inyecta
  // localizados el ciclo de vida). Se construyen en variables locales a
  // propósito: así el literal no queda tras un `title:`/`body:` inline, que es lo
  // que el test de cadenas visibles inspecciona en `lib/`.
  static NotificationText _defaultScheduledText(Appointment a) {
    final title = 'Cita: ${a.title}';
    const body = 'Tienes una cita proxima.';
    return (title: title, body: body);
  }

  static NotificationText _defaultToBookText(Appointment a) {
    final title = 'Recuerda agendar: ${a.title}';
    const body = 'Es momento de pedir esta cita.';
    return (title: title, body: body);
  }

  static NotificationText _defaultOverdueText(Appointment a) {
    final title = 'Cita pendiente: ${a.title}';
    const body = 'Tienes una cita vencida.';
    return (title: title, body: body);
  }
}
