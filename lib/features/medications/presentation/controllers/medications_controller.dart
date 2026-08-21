import 'package:flutter/foundation.dart';

import 'package:myvitals_healthtracker_app/features/medications/data/models/medication.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_dose.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_log.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/repositories/medication_repositories.dart';
import 'package:myvitals_healthtracker_app/features/medications/domain/medication_schedule_service.dart';
import 'package:myvitals_healthtracker_app/features/medications/domain/medication_inventory_service.dart';
import 'package:myvitals_healthtracker_app/features/medications/domain/medication_adherence_service.dart';
import 'package:myvitals_healthtracker_app/features/medications/domain/medication_scheduler.dart';

/// Efecto de un cambio de estado de una toma sobre el inventario.
enum InventoryEffect { none, consume, restore }

/// Una toma de un día concreto con su estado: lo que la pantalla "Hoy" pinta.
/// Combina la toma esperada (calculada desde la pauta) con su registro real, si
/// existe (`log == null` ⇒ pendiente).
class MedicationDayEntry {
  final Medication medication;
  final MedicationDose dose;
  final DateTime scheduledAt;
  final double quantity;
  final MedicationLog? log;

  const MedicationDayEntry({
    required this.medication,
    required this.dose,
    required this.scheduledAt,
    required this.quantity,
    required this.log,
  });

  bool get isPending => log == null;
  bool get isTaken => log?.status == MedicationLogStatus.taken;
  bool get isSkipped => log?.status == MedicationLogStatus.skipped;
}

/// Orquesta el módulo de medicamentos: compone los repositorios y los servicios
/// de dominio para que las pantallas trabajen con operaciones de alto nivel
/// (añadir, editar, registrar una toma, recargar…) sin conocer el descuento de
/// inventario ni la reprogramación de avisos.
///
/// Es un [ChangeNotifier] pero delega el estado en los repositorios (que ya
/// notifican); reexpone sus listas para comodidad de las pantallas.
class MedicationsController extends ChangeNotifier {
  MedicationsController({
    MedicationRepository? medications,
    MedicationDoseRepository? doses,
    MedicationLogRepository? logs,
    MedicationScheduler? scheduler,
  })  : _meds = medications ?? MedicationRepository.instance,
        _doses = doses ?? MedicationDoseRepository.instance,
        _logs = logs ?? MedicationLogRepository.instance,
        _scheduler = scheduler ?? MedicationScheduler() {
    // Los repositorios ya notifican en cada escritura, pero el controlador no se
    // enteraba: se suscribe a los tres y reemite, para que las pantallas hagan
    // un único `watch<MedicationsController>()` y se reconstruyan tras cualquier
    // alta, registro o recarga.
    _meds.addListener(notifyListeners);
    _doses.addListener(notifyListeners);
    _logs.addListener(notifyListeners);
  }

  final MedicationRepository _meds;
  final MedicationDoseRepository _doses;
  final MedicationLogRepository _logs;
  final MedicationScheduler _scheduler;

  @override
  void dispose() {
    _meds.removeListener(notifyListeners);
    _doses.removeListener(notifyListeners);
    _logs.removeListener(notifyListeners);
    super.dispose();
  }

  /// ¿Terminó la carga inicial de los tres repositorios desde la base?
  bool get isLoaded => _meds.isLoaded && _doses.isLoaded && _logs.isLoaded;

  /// Relee los tres repositorios desde la base. Se usa tras cambiar de base
  /// (entrar/salir de la demostración), donde la caché en memoria queda obsoleta.
  Future<void> reloadRepositories() async {
    await _meds.refresh();
    await _doses.refresh();
    await _logs.refresh();
  }

  /// Asegura que los repositorios están cargados y reprograma los avisos. La
  /// llama la cáscara de la app al arrancar y al volver del segundo plano para
  /// rellenar la ventana móvil de notificaciones aunque el usuario no haya tocado
  /// el módulo. Reprogramar con la caché vacía cancelaría los avisos existentes
  /// sin recrearlos, así que primero se garantiza la carga.
  Future<void> refreshAndReschedule() async {
    if (!isLoaded) await reloadRepositories();
    await reschedule();
  }

  // Constructores de texto localizado para las notificaciones. La UI los fija
  // (con l10n); mientras sean null, el planificador usa sus textos por defecto.
  DoseTextBuilder? _doseText;
  InventoryTextBuilder? _inventoryText;

  /// Fija los textos localizados de las notificaciones (llamar desde la UI con
  /// las cadenas de `AppLocalizations`).
  void setNotificationTextBuilders({
    DoseTextBuilder? doseText,
    InventoryTextBuilder? inventoryText,
  }) {
    _doseText = doseText;
    _inventoryText = inventoryText;
  }

  // --- Lecturas ---

  List<Medication> get medications => _meds.items;
  List<Medication> get activeMedications => _meds.active;

  /// Todos los registros de toma (para adherencia/calendario).
  List<MedicationLog> get logs => _logs.items;

  List<MedicationDose> dosesFor(String medicationId) =>
      _doses.forMedication(medicationId);

  /// El medicamento con [id], o null si no existe.
  Medication? medicationById(String id) {
    for (final m in _meds.items) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Mapa medicamento→horas de toma, para los servicios de dominio.
  Map<String, List<MedicationDose>> dosesByMedication() => {
        for (final m in _meds.items) m.id: _doses.forMedication(m.id),
      };

  /// Servicio de adherencia sobre el estado actual. Por defecto abarca los
  /// medicamentos activos; pasa [only] para restringirlo a uno (vista detalle).
  MedicationAdherenceService adherence({Medication? only}) {
    final meds = only != null ? [only] : _meds.active;
    return MedicationAdherenceService(
      medications: meds,
      dosesByMedication: dosesByMedication(),
      logs: _logs.items,
    );
  }

  /// Las tomas de [day] (por defecto hoy) con su estado, ordenadas por hora.
  List<MedicationDayEntry> entriesForDay([DateTime? day]) {
    final target = day ?? DateTime.now();
    final entries = <MedicationDayEntry>[];
    for (final med in _meds.active) {
      final expected = MedicationScheduleService.expectedDosesForDay(
        med,
        _doses.forMedication(med.id),
        target,
      );
      for (final e in expected) {
        entries.add(MedicationDayEntry(
          medication: med,
          dose: e.dose!,
          scheduledAt: e.scheduledAt,
          quantity: e.quantity,
          log: _logs.findByScheduled(med.id, e.scheduledAt),
        ));
      }
    }
    entries.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return entries;
  }

  // --- Comandos ---

  /// Alta de un medicamento con sus horas de toma. Reprograma los avisos.
  Future<void> addMedication(
    Medication medication,
    List<MedicationDose> doses,
  ) async {
    await _meds.insert(medication);
    for (final dose in doses) {
      await _doses.insert(dose.copyWith(medicationId: medication.id));
    }
    await reschedule();
  }

  /// Edición: reemplaza el medicamento y sus horas (borra las previas y crea las
  /// nuevas). Reprograma los avisos.
  Future<void> updateMedication(
    Medication medication,
    List<MedicationDose> doses,
  ) async {
    await _meds.update(medication);
    await _doses.deleteForMedication(medication.id);
    for (final dose in doses) {
      await _doses.insert(dose.copyWith(medicationId: medication.id));
    }
    await reschedule();
  }

  /// Pausa o reanuda un medicamento sin tocar su pauta ni sus horas. Un
  /// medicamento pausado (`isActive == false`) no genera tomas esperadas ni
  /// avisos —lo respeta el dominio—, pero conserva su historial. Reprograma.
  Future<void> setActive(Medication medication, {required bool active}) async {
    if (medication.isActive == active) return;
    await _meds.update(medication.copyWith(isActive: active));
    await reschedule();
  }

  /// Elimina un medicamento y todo lo suyo (horas, registros). Reprograma.
  Future<void> deleteMedication(String medicationId) async {
    await _doses.deleteForMedication(medicationId);
    await _logs.deleteForMedication(medicationId);
    await _meds.delete(medicationId);
    await reschedule();
  }

  /// Registra una toma como tomada u omitida, ajustando el inventario según la
  /// transición (ver [inventoryEffectOf]) y reprogramando los avisos.
  Future<void> logDose(
    MedicationDayEntry entry, {
    required bool taken,
  }) async {
    await _applyDoseLog(entry, taken: taken);
    await reschedule();
  }

  /// Registra VARIAS tomas de una vez y reprograma **una sola vez** al final, en
  /// lugar de por cada toma. Lo usa la hoja de «varias tomas» (misma hora, varios
  /// medicamentos): antes cada toma disparaba una reprogramación completa
  /// (cancelar N + reconstruir el plan de 14 días + programar N), lo que hacía
  /// ese registro cuadrático.
  Future<void> logDoses(
    Iterable<MedicationDayEntry> entries, {
    required bool taken,
  }) async {
    var any = false;
    for (final entry in entries) {
      await _applyDoseLog(entry, taken: taken);
      any = true;
    }
    if (any) await reschedule();
  }

  /// Escribe el registro de una toma y ajusta el inventario, SIN reprogramar (de
  /// eso se encargan [logDose]/[logDoses]). Aislado para poder registrar en lote.
  Future<void> _applyDoseLog(
    MedicationDayEntry entry, {
    required bool taken,
  }) async {
    final newStatus =
        taken ? MedicationLogStatus.taken : MedicationLogStatus.skipped;
    final effect = inventoryEffectOf(
      previous: entry.log?.status,
      next: newStatus,
    );

    // Cantidad que se devolvería al deshacer una toma: la que se consumió de
    // verdad (guardada en el log), no la esperada actual —que puede haber
    // cambiado tras editar la pauta—, para que el stock no derive. `entry.log`
    // sigue teniendo la cantidad antigua en memoria aunque abajo se sobrescriba
    // el registro. Restaurar solo ocurre cuando había una toma previa (log ≠ null).
    final restoreQuantity = entry.log?.quantity ?? entry.quantity;

    // Registro (nuevo o actualizado).
    if (entry.log != null) {
      await _logs.update(entry.log!.copyWith(
        status: newStatus,
        takenAt: taken ? DateTime.now() : null,
        quantity: entry.quantity,
      ));
    } else {
      await _logs.insert(MedicationLog(
        medicationId: entry.medication.id,
        doseId: entry.dose.id,
        scheduledAt: entry.scheduledAt,
        status: newStatus,
        takenAt: taken ? DateTime.now() : null,
        quantity: entry.quantity,
      ));
    }

    // Inventario. Se lee el medicamento ACTUAL del repositorio (no la copia
    // capturada en `entry`, que puede estar obsoleta tras registrar otra toma
    // del mismo medicamento en el mismo lote) para no perder descuentos.
    if (effect != InventoryEffect.none) {
      final med = medicationById(entry.medication.id) ?? entry.medication;
      final updated = effect == InventoryEffect.consume
          ? MedicationInventoryService.applyIntake(med, entry.quantity)
          : MedicationInventoryService.revertIntake(med, restoreQuantity);
      if (!identical(updated, med)) {
        await _meds.update(updated);
      }
    }
  }

  /// Recarga el inventario (suma [amount] o el tamaño de caja) y reprograma.
  Future<void> refill(Medication medication, {double? amount}) async {
    await _meds.update(
      MedicationInventoryService.refill(medication, amount: amount),
    );
    await reschedule();
  }

  /// Silencia las alertas de recompra hasta [until] y reprograma.
  Future<void> snoozeRefill(Medication medication, DateTime until) async {
    await _meds.update(
      MedicationInventoryService.snoozeAlert(medication, until),
    );
    await reschedule();
  }

  /// Reprograma todas las notificaciones a partir del estado actual. No-op en
  /// web (el planificador se protege solo).
  Future<void> reschedule() async {
    await _scheduler.rescheduleAll(
      medications: _meds.items,
      dosesByMedication: {
        for (final m in _meds.items) m.id: _doses.forMedication(m.id),
      },
      isAlreadyLogged: (medId, at) => _logs.findByScheduled(medId, at) != null,
      doseText: _doseText,
      inventoryText: _inventoryText,
    );
  }

  /// Decide el efecto sobre el inventario de pasar de [previous] a [next]:
  /// solo se descuenta al entrar en "tomada" y solo se devuelve al salir de
  /// "tomada". Puro y testeable.
  static InventoryEffect inventoryEffectOf({
    required MedicationLogStatus? previous,
    required MedicationLogStatus next,
  }) {
    final wasTaken = previous == MedicationLogStatus.taken;
    final willTake = next == MedicationLogStatus.taken;
    if (willTake && !wasTaken) return InventoryEffect.consume;
    if (!willTake && wasTaken) return InventoryEffect.restore;
    return InventoryEffect.none;
  }
}
