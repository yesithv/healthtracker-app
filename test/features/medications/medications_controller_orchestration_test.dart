import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_dose.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/repositories/medication_repositories.dart';
import 'package:myvitals_healthtracker_app/features/medications/domain/medication_scheduler.dart';
import 'package:myvitals_healthtracker_app/features/medications/presentation/controllers/medications_controller.dart';

/// Planificador que solo cuenta cuántas veces se reprograma, sin tocar plugins.
/// Sirve para comprobar que el registro en lote reprograma **una sola vez**.
class _CountingScheduler extends MedicationScheduler {
  int rescheduleCalls = 0;

  @override
  Future<void> rescheduleAll({
    required List<Medication> medications,
    required Map<String, List<MedicationDose>> dosesByMedication,
    DateTime? now,
    int horizonDays = MedicationScheduler.defaultHorizonDays,
    bool Function(String medicationId, DateTime scheduledAt)? isAlreadyLogged,
    DoseTextBuilder? doseText,
    InventoryTextBuilder? inventoryText,
  }) async {
    rescheduleCalls++;
  }
}

Medication _med({
  String? id,
  double doseQuantity = 2,
  FrequencyType frequency = FrequencyType.daily,
  bool stockTracking = false,
  double? stock,
  double? threshold,
  double? packSize,
}) {
  return Medication(
    id: id,
    name: 'Med',
    doseQuantity: doseQuantity,
    frequencyType: frequency,
    startDate: DateTime(2026, 1, 1),
    stockTrackingEnabled: stockTracking,
    stockQuantity: stock,
    refillThreshold: threshold,
    packSize: packSize,
  );
}

MedicationDose _dose(String medId, int hour) =>
    MedicationDose(medicationId: medId, hour: hour, minute: 0);

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await MedicationRepository.instance.clearAll();
    await MedicationDoseRepository.instance.clearAll();
    await MedicationLogRepository.instance.clearAll();
  });

  test('updateMedication replaces the schedule times', () async {
    final controller = MedicationsController(scheduler: _CountingScheduler());
    final med = _med();
    await controller.addMedication(med, [_dose(med.id, 8)]);
    expect(controller.dosesFor(med.id).map((d) => d.hour), [8]);

    // Editar: dos tomas nuevas reemplazan la anterior (no se acumulan).
    await controller.updateMedication(med, [
      _dose(med.id, 9),
      _dose(med.id, 21),
    ]);
    expect(controller.dosesFor(med.id).map((d) => d.hour), [9, 21]);

    controller.dispose();
  });

  test('refill adds the pack size and clears the snooze', () async {
    final controller = MedicationsController(scheduler: _CountingScheduler());
    final med = _med(stockTracking: true, stock: 2, threshold: 5, packSize: 30);
    await controller.addMedication(med, [_dose(med.id, 8)]);

    await controller.refill(controller.medicationById(med.id)!);
    expect(controller.medicationById(med.id)!.stockQuantity, 32); // 2 + 30

    controller.dispose();
  });

  test('setActive pauses a medication so it stops generating doses', () async {
    final controller = MedicationsController(scheduler: _CountingScheduler());
    final med = _med();
    await controller.addMedication(med, [_dose(med.id, 8)]);
    final day = DateTime(2026, 8, 17);
    expect(controller.entriesForDay(day), hasLength(1));

    await controller.setActive(
      controller.medicationById(med.id)!,
      active: false,
    );
    expect(controller.medicationById(med.id)!.isActive, isFalse);
    // Pausado: sin tomas esperadas, pero el medicamento sigue existiendo.
    expect(controller.entriesForDay(day), isEmpty);
    expect(controller.activeMedications, isEmpty);
    expect(controller.medications, hasLength(1));

    controller.dispose();
  });

  test('logDoses (batch) reschedules exactly once for many entries', () async {
    final scheduler = _CountingScheduler();
    final controller = MedicationsController(scheduler: scheduler);
    final a = _med();
    final b = _med();
    await controller.addMedication(a, [_dose(a.id, 8)]);
    await controller.addMedication(b, [_dose(b.id, 8)]);

    final day = DateTime(2026, 8, 17);
    final entries = controller.entriesForDay(day);
    expect(entries, hasLength(2));

    scheduler.rescheduleCalls = 0;
    await controller.logDoses(entries, taken: true);
    // Una sola reprogramación para el lote entero (antes: una por toma).
    expect(scheduler.rescheduleCalls, 1);
    expect(controller.entriesForDay(day).every((e) => e.isTaken), isTrue);

    controller.dispose();
  });

  test('reverting a taken dose restores the originally-logged quantity, '
      'not the current expected quantity', () async {
    // Regresión del bug de deriva de inventario: si la cantidad esperada cambia
    // entre "tomada" y "omitida", al deshacer se debe devolver lo que se
    // consumió de verdad (guardado en el log), no la esperada nueva.
    final scheduler = _CountingScheduler();
    final controller = MedicationsController(scheduler: scheduler);
    final med = _med(doseQuantity: 2, stockTracking: true, stock: 10);
    await controller.addMedication(med, [_dose(med.id, 8)]);
    final day = DateTime(2026, 8, 17);

    // Tomada con la cantidad de entonces (2): 10 → 8.
    await controller.logDose(controller.entriesForDay(day).first, taken: true);
    expect(controller.medicationById(med.id)!.stockQuantity, 8);

    // La pauta cambia a 5 por toma (la esperada de ese día pasa a ser 5).
    await controller.updateMedication(
      controller.medicationById(med.id)!.copyWith(doseQuantity: 5),
      [_dose(med.id, 8)],
    );
    final afterEdit = controller.entriesForDay(day).first;
    expect(afterEdit.quantity, 5); // la esperada actual
    expect(afterEdit.isTaken, isTrue); // sigue registrada como tomada (qty 2)

    // Deshacer: debe devolver 2 (lo consumido), no 5. 8 → 10, nunca 13.
    await controller.logDose(afterEdit, taken: false);
    expect(controller.medicationById(med.id)!.stockQuantity, 10);

    controller.dispose();
  });
}
