import 'package:uuid/uuid.dart';

/// Resultado de una toma programada.
enum MedicationLogStatus { taken, skipped }

MedicationLogStatus _statusFromName(String? name) => MedicationLogStatus.values
    .firstWhere((e) => e.name == name, orElse: () => MedicationLogStatus.taken);

/// Un evento real de toma: el usuario marcó una dosis como tomada u omitida.
///
/// Las tomas *esperadas* de un día no se materializan; se calculan desde la
/// pauta (ver MedicationScheduleService) y se cruzan con estos registros por
/// `(medicationId, scheduledAt)`. Solo las tomas `taken` descuentan inventario.
class MedicationLog {
  final String id;
  final String medicationId;

  /// Qué `MedicationDose` programada corresponde (null si fue un ajuste manual).
  final String? doseId;

  /// Fecha y hora prevista de la toma. Clave para de-duplicar el día y para
  /// pintar los puntos del calendario/adherencia.
  final DateTime scheduledAt;

  final MedicationLogStatus status;

  /// Cuándo se marcó realmente (null para omitidas o registros importados).
  final DateTime? takenAt;

  /// Unidades consumidas; descuenta inventario cuando [status] es `taken`.
  final double? quantity;

  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  MedicationLog({
    String? id,
    required this.medicationId,
    this.doseId,
    required this.scheduledAt,
    required this.status,
    this.takenAt,
    this.quantity,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isTaken => status == MedicationLogStatus.taken;

  MedicationLog copyWith({
    String? medicationId,
    String? doseId,
    DateTime? scheduledAt,
    MedicationLogStatus? status,
    DateTime? takenAt,
    double? quantity,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return MedicationLog(
      id: id,
      medicationId: medicationId ?? this.medicationId,
      doseId: doseId ?? this.doseId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      takenAt: takenAt ?? this.takenAt,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'dose_id': doseId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'status': status.name,
      'taken_at': takenAt?.toIso8601String(),
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory MedicationLog.fromMap(Map<String, dynamic> map) {
    return MedicationLog(
      id: map['id'] as String,
      medicationId: map['medication_id'] as String,
      doseId: map['dose_id'] as String?,
      scheduledAt: DateTime.parse(map['scheduled_at'] as String),
      status: _statusFromName(map['status'] as String?),
      takenAt: map['taken_at'] != null
          ? DateTime.parse(map['taken_at'] as String)
          : null,
      quantity: (map['quantity'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: map['is_synced'] == 1,
    );
  }
}
