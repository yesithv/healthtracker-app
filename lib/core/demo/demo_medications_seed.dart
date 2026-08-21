import 'package:myvitals_healthtracker_app/features/medications/data/models/medication.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_dose.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_log.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/repositories/medication_repositories.dart';
import 'package:myvitals_healthtracker_app/features/medications/domain/medication_schedule_service.dart';

/// Siembra medicamentos de ejemplo para la DEMOSTRACIÓN, para que el módulo se
/// vea poblado (la app normal arranca vacía). Es **idempotente**: si ya hay
/// algún medicamento, no hace nada. Inserta cuatro fichas coherentes con el
/// prototipo, sus horas de toma y un historial de tomas de las dos últimas
/// semanas para que la adherencia y el calendario tengan contenido.
Future<void> seedDemoMedicationsIfEmpty() async {
  final medsRepo = MedicationRepository.instance;
  final dosesRepo = MedicationDoseRepository.instance;
  final logsRepo = MedicationLogRepository.instance;

  // Refresca la caché desde la base ya conmutada a la demo antes de decidir.
  await medsRepo.refresh();
  if (medsRepo.items.isNotEmpty) return;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // (medicamento, horas de toma). Los ids se fijan para enlazar dosis y logs.
  final seeds = <(Medication, List<MedicationDose>)>[];

  Medication med({
    required String id,
    required String name,
    required MedicationForm form,
    double? strengthValue,
    String? strengthUnit,
    required String color,
    required String shape,
    required String notes,
    double doseQuantity = 1,
    FrequencyType frequency = FrequencyType.daily,
    int? daysOfWeek,
    required double stock,
    required double pack,
    required double threshold,
  }) => Medication(
    id: id,
    name: name,
    form: form,
    strengthValue: strengthValue,
    strengthUnit: strengthUnit,
    color: color,
    shape: shape,
    notes: notes,
    doseQuantity: doseQuantity,
    frequencyType: frequency,
    daysOfWeek: daysOfWeek,
    startDate: today.subtract(const Duration(days: 40)),
    stockQuantity: stock,
    stockTrackingEnabled: true,
    refillThreshold: threshold,
    refillLeadDays: 3,
    packSize: pack,
  );

  MedicationDose dose(String medId, int hour, int minute, {double? qty}) =>
      MedicationDose(
        medicationId: medId,
        hour: hour,
        minute: minute,
        quantity: qty,
      );

  seeds.add((
    med(
      id: 'demo-vytorin',
      name: 'Vytorin',
      form: MedicationForm.capsule,
      strengthValue: 10,
      strengthUnit: 'mg',
      color: 'brand',
      shape: 'capsule',
      notes: 'Para el colesterol',
      doseQuantity: 2,
      stock: 3, // dispara el aviso de inventario bajo
      pack: 30,
      threshold: 5,
    ),
    [dose('demo-vytorin', 20, 30, qty: 2)],
  ));
  seeds.add((
    med(
      id: 'demo-eutirox',
      name: 'Eutirox',
      form: MedicationForm.tablet,
      strengthValue: 50,
      strengthUnit: 'mcg',
      color: 'teal',
      shape: 'round',
      notes: 'Para la tiroides',
      stock: 22,
      pack: 28,
      threshold: 5,
    ),
    [dose('demo-eutirox', 8, 0)],
  ));
  seeds.add((
    med(
      id: 'demo-metformina',
      name: 'Metformina',
      form: MedicationForm.tablet,
      strengthValue: 850,
      strengthUnit: 'mg',
      color: 'violet',
      shape: 'round',
      notes: 'Para la glucosa',
      stock: 14,
      pack: 30,
      threshold: 5,
    ),
    [dose('demo-metformina', 20, 30)],
  ));
  seeds.add((
    med(
      id: 'demo-omega3',
      name: 'Omega-3',
      form: MedicationForm.capsule,
      strengthValue: 1000,
      strengthUnit: 'mg',
      color: 'green',
      shape: 'capsule',
      notes: 'Suplemento',
      frequency: FrequencyType.daysOfWeek,
      daysOfWeek: (1 << 0) | (1 << 2) | (1 << 4), // L, X, V
      stock: 40,
      pack: 60,
      threshold: 8,
    ),
    [dose('demo-omega3', 20, 30)],
  ));

  // Inserta medicamentos y sus horas de toma.
  for (final (m, doses) in seeds) {
    await medsRepo.insert(m);
    for (final d in doses) {
      await dosesRepo.insert(d);
    }
  }

  // Historial de las dos últimas semanas (hasta ayer): todas las tomas
  // esperadas marcadas como tomadas, para una adherencia alta y una buena racha.
  final from = today.subtract(const Duration(days: 14));
  final to = today.subtract(const Duration(days: 1));
  for (final (m, doses) in seeds) {
    final expected = MedicationScheduleService.expectedDosesBetween(
      m,
      doses,
      from,
      to,
    );
    for (final e in expected) {
      await logsRepo.insert(
        MedicationLog(
          medicationId: m.id,
          doseId: e.dose?.id,
          scheduledAt: e.scheduledAt,
          status: MedicationLogStatus.taken,
          takenAt: e.scheduledAt,
          quantity: e.quantity,
        ),
      );
    }
  }
}
