import 'package:myvitals_healthtracker_app/features/medications/data/models/medication.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_dose.dart';
import 'package:myvitals_healthtracker_app/features/medications/domain/medication_schedule_service.dart';

/// Lógica pura del inventario: consumo, proyección de agotamiento, evaluación de
/// alertas de recompra, recarga y silenciado. No toca base de datos ni
/// notificaciones; recibe y devuelve [Medication] inmutables para poder probarse
/// sola. Quien la use persiste el [Medication] resultante con su repositorio.
class MedicationInventoryService {
  /// Consumo medio de unidades por día según la pauta y las horas de toma.
  /// - diario: suma de las cantidades de todas sus tomas.
  /// - días de la semana: esa suma × (días activos / 7).
  /// - cada N días: esa suma / N.
  /// 0 si no hay tomas configuradas.
  static double dailyConsumption(Medication med, List<MedicationDose> doses) {
    if (doses.isEmpty) return 0;

    final perIntakeDay = doses.fold<double>(
      0,
      (sum, d) => sum + (d.quantity ?? med.doseQuantity),
    );

    switch (med.frequencyType) {
      case FrequencyType.daily:
        return perIntakeDay;

      case FrequencyType.daysOfWeek:
        final activeDays =
            MedicationScheduleService.activeWeekdayCount(med.daysOfWeek);
        if (activeDays == 0) return 0;
        return perIntakeDay * activeDays / 7.0;

      case FrequencyType.intervalDays:
        final interval = med.intervalDays;
        if (interval == null || interval <= 0) return 0;
        return perIntakeDay / interval;
    }
  }

  /// Días completos que aguanta el stock actual al ritmo de consumo. Null si no
  /// se lleva inventario, no hay stock, o el consumo es 0 (no se puede proyectar).
  static int? daysRemaining(Medication med, List<MedicationDose> doses) {
    if (!med.stockTrackingEnabled) return null;
    final stock = med.stockQuantity;
    if (stock == null) return null;
    final perDay = dailyConsumption(med, doses);
    if (perDay <= 0) return null;
    final days = stock / perDay;
    if (days.isInfinite || days.isNaN) return null;
    return days.floor();
  }

  /// Fecha estimada en la que se agota el stock. Null si no es proyectable.
  static DateTime? runOutDate(
    Medication med,
    List<MedicationDose> doses, {
    DateTime? today,
  }) {
    final days = daysRemaining(med, doses);
    if (days == null) return null;
    final base = today ?? DateTime.now();
    return DateTime(base.year, base.month, base.day).add(Duration(days: days));
  }

  /// Fecha límite recomendada para comprar: el agotamiento menos los días de
  /// antelación configurados. Null si no es proyectable.
  static DateTime? buyByDate(
    Medication med,
    List<MedicationDose> doses, {
    DateTime? today,
  }) {
    final runOut = runOutDate(med, doses, today: today);
    if (runOut == null) return null;
    final lead = med.refillLeadDays ?? 0;
    return runOut.subtract(Duration(days: lead));
  }

  /// ¿Debe avisarse de recompra hoy? True si se lleva inventario, las alertas
  /// están activas, no está silenciado, y o bien el stock cayó al umbral o bien
  /// los días restantes entran dentro de la antelación configurada.
  static bool shouldAlert(
    Medication med,
    List<MedicationDose> doses, {
    DateTime? today,
  }) {
    if (!med.stockTrackingEnabled || !med.refillAlertEnabled) return false;

    final now = today ?? DateTime.now();
    final snooze = med.refillSnoozedUntil;
    if (snooze != null && now.isBefore(snooze)) return false;

    final stock = med.stockQuantity;

    final thresholdHit = med.refillThreshold != null &&
        stock != null &&
        stock <= med.refillThreshold!;

    final remaining = daysRemaining(med, doses);
    final leadHit = med.refillLeadDays != null &&
        remaining != null &&
        remaining <= med.refillLeadDays!;

    return thresholdHit || leadHit;
  }

  /// Aplica una toma: descuenta [quantity] del stock (nunca por debajo de 0).
  /// Devuelve el medicamento sin cambios si no se lleva inventario.
  static Medication applyIntake(Medication med, double quantity) {
    if (!med.stockTrackingEnabled || med.stockQuantity == null) return med;
    final next = med.stockQuantity! - quantity;
    return med.copyWith(stockQuantity: next < 0 ? 0 : next);
  }

  /// Deshace una toma (al desmarcarla o cambiarla a omitida): devuelve
  /// [quantity] al stock. Sin efecto si no se lleva inventario.
  static Medication revertIntake(Medication med, double quantity) {
    if (!med.stockTrackingEnabled || med.stockQuantity == null) return med;
    return med.copyWith(stockQuantity: med.stockQuantity! + quantity);
  }

  /// Recarga el inventario: suma [amount] (o [Medication.packSize] si no se
  /// indica) al stock y limpia el silenciado para que las alertas vuelvan a
  /// evaluarse con el nuevo nivel.
  static Medication refill(Medication med, {double? amount}) {
    final added = amount ?? med.packSize ?? 0;
    final current = med.stockQuantity ?? 0;
    return med.copyWith(
      stockQuantity: current + added,
      clearRefillSnooze: true,
    );
  }

  /// Silencia las alertas de recompra hasta [until] (ej. "ya lo compré" o
  /// "recuérdame mañana").
  static Medication snoozeAlert(Medication med, DateTime until) {
    return med.copyWith(refillSnoozedUntil: until);
  }
}
