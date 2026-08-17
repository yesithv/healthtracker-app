import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myvitals_healthtracker_app/core/services/notification_service.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_dose.dart';
import 'package:myvitals_healthtracker_app/features/medications/domain/medication_schedule_service.dart';
import 'package:myvitals_healthtracker_app/features/medications/domain/medication_inventory_service.dart';

/// Qué representa una notificación planificada.
enum MedicationNotificationKind { dose, inventory }

/// Textos localizados de una notificación. La parte de dominio no conoce la
/// localización de Flutter, así que la UI le pasa constructores de texto; hay
/// defaults en español para poder programar avisos aunque la UI no exista aún.
typedef NotificationText = ({String title, String body});
typedef DoseTextBuilder = NotificationText Function(
  Medication med,
  ExpectedDose dose,
);
typedef InventoryTextBuilder = NotificationText Function(Medication med);

/// Una notificación concreta a programar: id reservado, cuándo, qué texto y un
/// payload que identifica la toma o la alerta para el deep-link al tocarla.
class PlannedNotification {
  final int id;
  final MedicationNotificationKind kind;
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

/// Materializa las tomas y las alertas de inventario en notificaciones locales.
///
/// El plugin no repite "cada N días", así que en vez de apoyarnos en la
/// repetición nativa programamos cada ocurrencia futura como una notificación
/// puntual dentro de una ventana móvil ([horizonDays]) y volvemos a rellenar al
/// reabrir la app. [buildPlan] es pura (y testeable); [rescheduleAll] ejecuta el
/// plan y lleva un libro de ids persistido para cancelar sin dejar huérfanas.
class MedicationScheduler {
  MedicationScheduler({NotificationService? notificationService})
      : _notif = notificationService ?? NotificationService();

  final NotificationService _notif;

  /// Base de ids para las tomas. Separada de los recordatorios existentes
  /// (`index + 100`, rango 100–999) para que no colisionen.
  static const int doseIdBase = 200000;

  /// Base de ids para las alertas de inventario.
  static const int inventoryIdBase = 800000;

  /// Días por delante que se materializan en cada pasada.
  static const int defaultHorizonDays = 14;

  static const String _ledgerKey = 'medication_notif_ids';

  /// Construye el plan de notificaciones (tomas + inventario) para [medications]
  /// a partir de [from]. Puro: no toca notificaciones ni base de datos.
  ///
  /// - Omite las tomas ya pasadas y las ya registradas ([isAlreadyLogged]).
  /// - Asigna ids secuenciales desde [doseIdBase]/[inventoryIdBase]; como
  ///   [rescheduleAll] cancela por el libro de ids persistido, basta con que
  ///   sean únicos dentro de una misma pasada.
  static List<PlannedNotification> buildPlan({
    required List<Medication> medications,
    required Map<String, List<MedicationDose>> dosesByMedication,
    required DateTime from,
    int horizonDays = defaultHorizonDays,
    bool Function(String medicationId, DateTime scheduledAt)? isAlreadyLogged,
    DoseTextBuilder? doseText,
    InventoryTextBuilder? inventoryText,
  }) {
    final plan = <PlannedNotification>[];
    final active = medications.where((m) => m.isActive).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final to = from.add(Duration(days: horizonDays));

    // Tomas.
    var doseId = doseIdBase;
    for (final med in active) {
      final doses = dosesByMedication[med.id] ?? const [];
      final expected =
          MedicationScheduleService.expectedDosesBetween(med, doses, from, to);
      for (final e in expected) {
        if (e.scheduledAt.isBefore(from)) continue;
        if (isAlreadyLogged?.call(med.id, e.scheduledAt) ?? false) continue;
        final text = (doseText ?? _defaultDoseText)(med, e);
        plan.add(PlannedNotification(
          id: doseId++,
          kind: MedicationNotificationKind.dose,
          title: text.title,
          body: text.body,
          scheduledAt: e.scheduledAt,
          payload: 'dose|${med.id}|${e.scheduledAt.toIso8601String()}',
        ));
      }
    }

    // Alertas de inventario.
    var invId = inventoryIdBase;
    for (final med in active) {
      if (!med.stockTrackingEnabled || !med.refillAlertEnabled) continue;
      final doses = dosesByMedication[med.id] ?? const [];

      final alertNow =
          MedicationInventoryService.shouldAlert(med, doses, today: from);
      final buyBy =
          MedicationInventoryService.buyByDate(med, doses, today: from);

      DateTime? when;
      if (alertNow) {
        // Ya está en zona de recompra: avisar cuanto antes.
        when = from.add(const Duration(minutes: 1));
      } else if (buyBy != null && buyBy.isAfter(from)) {
        // Aún hay margen: avisar la mañana de la fecha límite de compra.
        when = DateTime(buyBy.year, buyBy.month, buyBy.day, 9);
      }
      if (when == null) continue;

      // Respetar un silenciado que aún no ha vencido.
      final snooze = med.refillSnoozedUntil;
      if (snooze != null && when.isBefore(snooze)) {
        when = DateTime(snooze.year, snooze.month, snooze.day, 9);
      }

      final text = (inventoryText ?? _defaultInventoryText)(med);
      plan.add(PlannedNotification(
        id: invId++,
        kind: MedicationNotificationKind.inventory,
        title: text.title,
        body: text.body,
        scheduledAt: when,
        payload: 'inventory|${med.id}',
      ));
    }

    return plan;
  }

  /// Reprograma TODAS las notificaciones de medicamentos: cancela las de la
  /// pasada anterior (por el libro de ids), programa el plan nuevo y persiste
  /// los ids programados. No-op en web (sin notificaciones). Llamar al arrancar
  /// la app, al volver del segundo plano y tras editar/registrar.
  Future<void> rescheduleAll({
    required List<Medication> medications,
    required Map<String, List<MedicationDose>> dosesByMedication,
    DateTime? now,
    int horizonDays = defaultHorizonDays,
    bool Function(String medicationId, DateTime scheduledAt)? isAlreadyLogged,
    DoseTextBuilder? doseText,
    InventoryTextBuilder? inventoryText,
  }) async {
    if (kIsWeb) return;

    final prefs = await SharedPreferences.getInstance();
    final previous = prefs
            .getStringList(_ledgerKey)
            ?.map((s) => int.tryParse(s))
            .whereType<int>()
            .toList() ??
        const <int>[];
    for (final id in previous) {
      await _notif.cancel(id);
    }

    final plan = buildPlan(
      medications: medications,
      dosesByMedication: dosesByMedication,
      from: now ?? DateTime.now(),
      horizonDays: horizonDays,
      isAlreadyLogged: isAlreadyLogged,
      doseText: doseText,
      inventoryText: inventoryText,
    );

    final scheduled = <int>[];
    for (final p in plan) {
      await _notif.scheduleOneTimeNotification(
        id: p.id,
        title: p.title,
        body: p.body,
        dateTime: p.scheduledAt,
        payload: p.payload,
      );
      scheduled.add(p.id);
    }

    await prefs.setStringList(
      _ledgerKey,
      scheduled.map((e) => e.toString()).toList(),
    );
  }

  /// Cancela todas las notificaciones de medicamentos y vacía el libro de ids
  /// (al desactivar el módulo o cambiar de paciente).
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final previous = prefs
            .getStringList(_ledgerKey)
            ?.map((s) => int.tryParse(s))
            .whereType<int>()
            .toList() ??
        const <int>[];
    for (final id in previous) {
      await _notif.cancel(id);
    }
    await prefs.remove(_ledgerKey);
  }

  static NotificationText _defaultDoseText(Medication med, ExpectedDose dose) {
    return (title: med.name, body: 'Es hora de tu toma.');
  }

  static NotificationText _defaultInventoryText(Medication med) {
    return (
      title: 'Reabastecer ${med.name}',
      body: 'Tu inventario está por agotarse.',
    );
  }
}
