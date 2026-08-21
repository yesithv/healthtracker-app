import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_dose.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_log.dart';

/// Repositorios del módulo de medicamentos. Reutilizan el CRUD, la caché en
/// memoria y el flag `is_synced` de [RecordRepository]; solo declaran su tabla,
/// mappers, id y orden (estas tablas no tienen `measurement_date`).

class MedicationRepository extends RecordRepository<Medication> {
  MedicationRepository._();
  static final MedicationRepository instance = MedicationRepository._();

  @override
  String get table => 'medications';
  @override
  String get orderBy => 'name COLLATE NOCASE ASC';
  @override
  String get unsyncedOrderBy => 'created_at ASC';
  @override
  Medication fromMap(Map<String, dynamic> map) => Medication.fromMap(map);
  @override
  Map<String, dynamic> toMap(Medication record) => record.toMap();
  @override
  String idOf(Medication record) => record.id;

  /// Solo los medicamentos activos (no pausados), tal como los enseña el hub.
  List<Medication> get active => items.where((m) => m.isActive).toList();
}

class MedicationDoseRepository extends RecordRepository<MedicationDose> {
  MedicationDoseRepository._();
  static final MedicationDoseRepository instance = MedicationDoseRepository._();

  @override
  String get table => 'medication_doses';
  @override
  String get orderBy => 'hour ASC, minute ASC';
  @override
  String get unsyncedOrderBy => 'created_at ASC';
  @override
  MedicationDose fromMap(Map<String, dynamic> map) =>
      MedicationDose.fromMap(map);
  @override
  Map<String, dynamic> toMap(MedicationDose record) => record.toMap();
  @override
  String idOf(MedicationDose record) => record.id;

  /// Horas de toma de un medicamento (desde la caché, ya ordenadas por hora).
  List<MedicationDose> forMedication(String medicationId) =>
      items.where((d) => d.medicationId == medicationId).toList();

  /// Borra todas las horas de un medicamento (al editar o eliminar la pauta).
  Future<void> deleteForMedication(String medicationId) async {
    for (final dose in forMedication(medicationId)) {
      await delete(dose.id);
    }
  }
}

class MedicationLogRepository extends RecordRepository<MedicationLog> {
  MedicationLogRepository._();
  static final MedicationLogRepository instance = MedicationLogRepository._();

  @override
  String get table => 'medication_logs';
  @override
  String get orderBy => 'scheduled_at DESC';
  @override
  String get unsyncedOrderBy => 'scheduled_at ASC';
  @override
  MedicationLog fromMap(Map<String, dynamic> map) => MedicationLog.fromMap(map);
  @override
  Map<String, dynamic> toMap(MedicationLog record) => record.toMap();
  @override
  String idOf(MedicationLog record) => record.id;

  /// Registros de un medicamento (desde la caché, más reciente primero).
  List<MedicationLog> forMedication(String medicationId) =>
      items.where((l) => l.medicationId == medicationId).toList();

  /// Índice `(medicamento, hora prevista) → registro`, para resolver
  /// [findByScheduled] en O(1). Se reconstruye perezosamente tras cada refresco
  /// (ver [refresh]); antes era un escaneo lineal invocado dentro de bucles
  /// (planificador y adherencia), lo que degradaba a cuadrático/cúbico.
  Map<String, MedicationLog>? _byScheduled;

  static String _scheduledKey(String medicationId, DateTime scheduledAt) =>
      '$medicationId|${scheduledAt.toIso8601String()}';

  Map<String, MedicationLog> get _scheduledIndex => _byScheduled ??= {
    for (final log in items)
      _scheduledKey(log.medicationId, log.scheduledAt): log,
  };

  @override
  Future<void> refresh() async {
    await super.refresh();
    _byScheduled = null; // invalidar; se reconstruye al primer uso
  }

  /// El registro de una toma concreta, identificada por medicamento y hora
  /// prevista. Sirve para saber si una dosis esperada ya se marcó (tomada u
  /// omitida) y evitar duplicados al registrar.
  MedicationLog? findByScheduled(String medicationId, DateTime scheduledAt) =>
      _scheduledIndex[_scheduledKey(medicationId, scheduledAt)];

  /// Borra todos los registros de un medicamento (al eliminarlo).
  Future<void> deleteForMedication(String medicationId) async {
    for (final log in forMedication(medicationId)) {
      await delete(log.id);
    }
  }
}
