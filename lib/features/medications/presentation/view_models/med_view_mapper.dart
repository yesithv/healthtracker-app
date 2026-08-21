import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/medication.dart';
import '../../data/models/medication_dose.dart';
import '../../domain/medication_adherence_service.dart';
import '../../domain/medication_inventory_service.dart';
import '../../domain/medication_schedule_service.dart';
import '../controllers/medications_controller.dart';
import 'med_view_models.dart';

/// MAPEO DOMINIO → VIEW-MODELS del módulo de Medicamentos.
///
/// Funciones **puras**: reciben el dominio ([Medication], [MedicationDayEntry],
/// estados de adherencia) más una [AppLocalizations] y devuelven los VM con las
/// cadenas ya formateadas y traducidas. No dependen de `BuildContext`, así que
/// se prueban solas cargando `AppLocalizations.delegate` en el test. Las fechas
/// y los nombres de día se localizan con `intl` según `l10n.localeName`.

/// Formatea un número quitando el ".0" de los enteros (2.0 → "2", 2.5 → "2,5").
String _numStr(num v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

/// Hora "HH:mm" a 24 h (neutro respecto al idioma).
String timeLabelHM(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

String _timeOf(DateTime dt) => timeLabelHM(dt.hour, dt.minute);

/// Rol de color decorativo a partir del valor guardado (`Medication.color`). Si
/// no se reconoce, se elige uno estable a partir de la semilla (el nombre) para
/// que el mismo medicamento conserve siempre su color.
MedColor medColorFromKey(String? key, {String? seed}) {
  switch (key) {
    case 'brand':
      return MedColor.brand;
    case 'teal':
      return MedColor.teal;
    case 'violet':
      return MedColor.violet;
    case 'green':
      return MedColor.green;
    case 'amber':
      return MedColor.amber;
  }
  const values = MedColor.values;
  final s = seed ?? key ?? '';
  if (s.isEmpty) return MedColor.brand;
  final hash = s.codeUnits.fold<int>(0, (a, b) => a + b);
  return values[hash % values.length];
}

/// Nombre localizado de la forma farmacéutica.
String formName(MedicationForm form, AppLocalizations l) => switch (form) {
      MedicationForm.capsule => l.medFormNameCapsule,
      MedicationForm.tablet => l.medFormNameTablet,
      MedicationForm.liquid => l.medFormNameLiquid,
      MedicationForm.injection => l.medFormNameInjection,
      MedicationForm.drops => l.medFormNameDrops,
      MedicationForm.other => l.medFormNameOther,
    };

/// Palabra de unidad (pluralizada) para la forma: "cápsula"/"cápsulas".
String unitWord(MedicationForm form, int count, AppLocalizations l) =>
    switch (form) {
      MedicationForm.capsule => l.medUnitCapsule(count),
      MedicationForm.tablet => l.medUnitTablet(count),
      MedicationForm.liquid => l.medUnitLiquid(count),
      MedicationForm.injection => l.medUnitInjection(count),
      MedicationForm.drops => l.medUnitDrops(count),
      MedicationForm.other => l.medUnitOther(count),
    };

/// Cantidad por toma: "2 cápsulas", "1 tableta".
String doseAmountLabel(num quantity, MedicationForm form, AppLocalizations l) =>
    '${_numStr(quantity)} ${unitWord(form, quantity.round(), l)}';

/// Concentración: "10 mg" (vacío si no hay valor).
String strengthLabel(Medication m) {
  if (m.strengthValue == null) return '';
  final unit = m.strengthUnit ?? '';
  return '${_numStr(m.strengthValue!)} $unit'.trim();
}

/// Nombre corto del día de la semana [weekday] (1=lunes … 7=domingo) localizado.
String weekdayShort(int weekday, String locale) {
  // 2024-01-01 fue lunes; +weekday-1 recorre lunes..domingo.
  final date = DateTime(2024, 1, weekday);
  return DateFormat.E(locale).format(date);
}

/// Texto de la pauta: "Todos los días" / "Lun · Mié · Vie" / "Cada 8 días".
String scheduleLabel(Medication m, AppLocalizations l, String locale) {
  switch (m.frequencyType) {
    case FrequencyType.daily:
      return l.medScheduleDaily;
    case FrequencyType.intervalDays:
      return l.medScheduleEveryNDays(m.intervalDays ?? 1);
    case FrequencyType.daysOfWeek:
      final mask = m.daysOfWeek ?? 0;
      final count = MedicationScheduleService.activeWeekdayCount(mask);
      if (count == 0 || count == 7) return l.medScheduleDaily;
      final names = <String>[];
      for (var wd = 1; wd <= 7; wd++) {
        if ((mask & (1 << (wd - 1))) != 0) names.add(weekdayShort(wd, locale));
      }
      return names.join(' · ');
  }
}

/// Resumen de la pauta con horas: "2 cápsulas · 08:00, 20:30".
String doseSummaryLabel(
  Medication m,
  List<MedicationDose> doses,
  AppLocalizations l,
) {
  if (doses.isEmpty) return '';
  final qty = doses.first.quantity ?? m.doseQuantity;
  final amount = doseAmountLabel(qty, m.form, l);
  final times = (doses.map((d) => timeLabelHM(d.hour, d.minute)).toList()
        ..sort())
      .join(', ');
  return '$amount · $times';
}

/// Fecha corta con "~": "~13 ago". Vacío si es null.
String runOutLabel(DateTime? runOut, String locale) =>
    runOut == null ? '' : '~${DateFormat.MMMd(locale).format(runOut)}';

/// Fecha corta localizada: "13 ago".
String shortDateLabel(DateTime date, String locale) =>
    DateFormat.MMMd(locale).format(date);

/// Etiqueta del mes: "Agosto 2026" (con inicial mayúscula).
String monthLabel(DateTime month, String locale) {
  final raw = DateFormat.yMMMM(locale).format(month);
  return raw.isEmpty ? raw : raw[0].toUpperCase() + raw.substring(1);
}

/// Estado de pintado (verde/ámbar/pendiente/sin dato) desde el estado de un día.
DoseState? doseStateFromDayStatus(MedDayStatus s) => switch (s) {
      MedDayStatus.allTaken => DoseState.taken,
      MedDayStatus.partial => DoseState.skipped,
      MedDayStatus.missed => DoseState.skipped,
      MedDayStatus.upcoming => DoseState.pending,
      MedDayStatus.noDoses => null,
    };

/// VM de una toma del día a partir de la entrada del controlador.
DoseVm doseVm(MedicationDayEntry e, AppLocalizations l) {
  final med = e.medication;
  final state = e.isTaken
      ? DoseState.taken
      : e.isSkipped
          ? DoseState.skipped
          : DoseState.pending;
  return DoseVm(
    medId: med.id,
    doseId: e.dose.id,
    scheduledAt: e.scheduledAt,
    medName: med.name,
    amount: doseAmountLabel(e.quantity, med.form, l),
    time: _timeOf(e.scheduledAt),
    color: medColorFromKey(med.color, seed: med.name),
    icon: medIconFor(med.shape),
    state: state,
  );
}

/// VM de la ficha de un medicamento. La adherencia y el inventario proyectado se
/// pasan ya calculados (los computa la pantalla con los servicios de dominio).
MedVm medVm(
  Medication m,
  List<MedicationDose> doses, {
  required int adherencePct,
  required int streak,
  int? daysLeft,
  DateTime? runOut,
  required AppLocalizations l,
  required String locale,
}) {
  final stockValue = m.stockQuantity ?? 0;
  final low = m.stockTrackingEnabled &&
      m.refillThreshold != null &&
      stockValue <= m.refillThreshold!;
  return MedVm(
    id: m.id,
    name: m.name,
    form: formName(m.form, l),
    strength: strengthLabel(m),
    reason: m.notes ?? '',
    color: medColorFromKey(m.color, seed: m.name),
    icon: medIconFor(m.shape),
    schedule: scheduleLabel(m, l, locale),
    doseSummary: doseSummaryLabel(m, doses, l),
    trackInventory: m.stockTrackingEnabled,
    stock: stockValue.round(),
    packSize: (m.packSize ?? 0).round(),
    refillThreshold: (m.refillThreshold ?? 0).round(),
    daysLeft: daysLeft,
    runOut: runOut != null ? runOutLabel(runOut, locale) : '',
    adherencePct: adherencePct,
    streak: streak,
    lowStock: low,
  );
}

/// Compone el VM completo de un medicamento a partir del controlador: adherencia
/// (mes + racha) e inventario proyectado (días restantes y fecha de agotamiento).
/// Es el atajo que usan las pantallas para no repetir el cálculo.
MedVm medVmForMedication(
  MedicationsController controller,
  Medication m,
  AppLocalizations l,
  String locale, {
  DateTime? today,
}) {
  final now = today ?? DateTime.now();
  final doses = controller.dosesFor(m.id);
  final adh = controller.adherence(only: m);
  return medVm(
    m,
    doses,
    adherencePct: adh.monthlyAdherence(now, today: now),
    streak: adh.currentStreak(today: now),
    daysLeft: MedicationInventoryService.daysRemaining(m, doses),
    runOut: MedicationInventoryService.runOutDate(m, doses, today: now),
    l: l,
    locale: locale,
  );
}

/// VM de un día de la tira semanal.
WeekDayVm weekDayVm(MedAdherenceDay d, String locale) => WeekDayVm(
      weekday: DateFormat.E(locale).format(d.date).toUpperCase(),
      number: d.number,
      state: doseStateFromDayStatus(d.status) ?? DoseState.pending,
      isToday: d.isToday,
    );

/// VM de un día del calendario de adherencia.
AdherenceDayVm adherenceDayVm(MedAdherenceDay d) => AdherenceDayVm(
      number: d.number,
      state: doseStateFromDayStatus(d.status),
      isToday: d.isToday,
      outOfMonth: d.outOfMonth,
    );
