import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_dose.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/repositories/medication_repositories.dart';
import 'package:myvitals_healthtracker_app/features/medications/domain/medication_scheduler.dart';
import 'package:myvitals_healthtracker_app/features/medications/presentation/controllers/medications_controller.dart';

/// Planificador de notificaciones que no hace nada: evita tocar los plugins de
/// notificaciones y de preferencias en un test de VM, dejando ver el efecto real
/// sobre repositorios e inventario.
class _NoopScheduler extends MedicationScheduler {
  @override
  Future<void> rescheduleAll({
    required List<Medication> medications,
    required Map<String, List<MedicationDose>> dosesByMedication,
    DateTime? now,
    int horizonDays = MedicationScheduler.defaultHorizonDays,
    bool Function(String medicationId, DateTime scheduledAt)? isAlreadyLogged,
    DoseTextBuilder? doseText,
    InventoryTextBuilder? inventoryText,
  }) async {}
}

void main() {
  setUpAll(() {
    // La base real corre sobre sqflite ffi en el test.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Aísla cada prueba: vacía las tres tablas (crea la base si hace falta).
    await MedicationRepository.instance.clearAll();
    await MedicationDoseRepository.instance.clearAll();
    await MedicationLogRepository.instance.clearAll();
  });

  test('add a medication, then logging a dose decrements its stock', () async {
    final controller = MedicationsController(scheduler: _NoopScheduler());
    final day = DateTime(2026, 8, 17); // lunes

    final med = Medication(
      name: 'Vytorin',
      form: MedicationForm.capsule,
      doseQuantity: 2,
      color: 'brand',
      frequencyType: FrequencyType.daily,
      startDate: DateTime(2026, 1, 1),
      stockQuantity: 10,
      stockTrackingEnabled: true,
      refillThreshold: 5,
      packSize: 30,
    );
    final dose = MedicationDose(medicationId: med.id, hour: 8, minute: 0);

    await controller.addMedication(med, [dose]);

    // Aparece entre los activos.
    expect(controller.activeMedications.map((m) => m.name), contains('Vytorin'));

    // Tiene una toma esperada ese día.
    final entries = controller.entriesForDay(day);
    expect(entries.length, 1);
    expect(entries.first.isPending, isTrue);
    expect(entries.first.quantity, 2);

    // Registrarla como tomada descuenta 2 del stock (10 → 8).
    await controller.logDose(entries.first, taken: true);

    final updated = controller.medicationById(med.id)!;
    expect(updated.stockQuantity, 8);

    // La toma ya no está pendiente.
    final after = controller.entriesForDay(day);
    expect(after.first.isTaken, isTrue);

    // Deshacerla (marcar omitida) devuelve el stock (8 → 10).
    await controller.logDose(after.first, taken: false);
    expect(controller.medicationById(med.id)!.stockQuantity, 10);

    controller.dispose();
  });

  test('deleting a medication removes it and its doses', () async {
    final controller = MedicationsController(scheduler: _NoopScheduler());
    final med = Medication(
      name: 'Eutirox',
      doseQuantity: 1,
      startDate: DateTime(2026, 1, 1),
    );
    await controller.addMedication(
      med,
      [MedicationDose(medicationId: med.id, hour: 8, minute: 0)],
    );
    expect(controller.medications, isNotEmpty);

    await controller.deleteMedication(med.id);
    expect(controller.medicationById(med.id), isNull);
    expect(controller.dosesFor(med.id), isEmpty);

    controller.dispose();
  });
}
