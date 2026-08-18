import 'package:uuid/uuid.dart';

/// Presentación física del medicamento. Se guarda por `name` (string estable),
/// no por índice, para que reordenar el enum no corrompa datos existentes.
enum MedicationForm { capsule, tablet, liquid, injection, drops, other }

/// Cómo se repite la pauta:
/// - [daily]: todos los días.
/// - [daysOfWeek]: días concretos de la semana (ver [Medication.daysOfWeek]).
/// - [intervalDays]: cada N días desde [Medication.anchorDate] (ej. "cada 8 días").
enum FrequencyType { daily, daysOfWeek, intervalDays }

MedicationForm _formFromName(String? name) => MedicationForm.values.firstWhere(
      (e) => e.name == name,
      orElse: () => MedicationForm.other,
    );

FrequencyType _freqFromName(String? name) => FrequencyType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => FrequencyType.daily,
    );

DateTime? _parseDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

/// Un medicamento del usuario: identidad, pauta e inventario. Las horas de toma
/// viven aparte en `medication_doses` (un medicamento puede tener varias al día)
/// y los eventos reales de toma en `medication_logs`.
///
/// Sigue las convenciones de los `*_record.dart`: `id` TEXT con [Uuid], fechas
/// ISO-8601, booleanos como 0/1 y `is_synced` para la sincronización futura.
class Medication {
  final String id;
  final String name;
  final MedicationForm form;

  /// Concentración, ej. 10 (mg). Puramente informativa.
  final double? strengthValue;
  final String? strengthUnit;

  /// Unidades por toma por defecto (ej. 2 cápsulas). Cada `MedicationDose` puede
  /// sobreescribirla con su propia cantidad.
  final double doseQuantity;

  /// Identidad visual del ícono de píldora (decorativa).
  final String? color;
  final String? shape;

  final String? notes;

  final FrequencyType frequencyType;

  /// Bitmask de días de la semana para [FrequencyType.daysOfWeek]. El bit
  /// `weekday - 1` corresponde a `DateTime.weekday` (lunes = 1 → bit 0,
  /// domingo = 7 → bit 6). Null si la frecuencia no es por días de la semana.
  final int? daysOfWeek;

  /// N para [FrequencyType.intervalDays].
  final int? intervalDays;

  /// Fecha base desde la que se cuentan los "cada N días". Si es null se usa
  /// [startDate].
  final DateTime? anchorDate;

  final DateTime? startDate;
  final DateTime? endDate;

  /// Pausar sin borrar. Un medicamento inactivo no genera tomas esperadas.
  final bool isActive;

  // --- Inventario ---
  final double? stockQuantity;
  final bool stockTrackingEnabled;

  /// Avisar cuando el stock quede en o por debajo de este umbral.
  final double? refillThreshold;

  /// Días de antelación para la alerta "se acaba en X días".
  final int? refillLeadDays;

  /// Tamaño de caja por defecto al recargar.
  final double? packSize;

  final bool refillAlertEnabled;

  /// Silenciar las alertas de recompra hasta esta fecha (tras comprar/aplazar).
  final DateTime? refillSnoozedUntil;

  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  Medication({
    String? id,
    required this.name,
    this.form = MedicationForm.other,
    this.strengthValue,
    this.strengthUnit,
    required this.doseQuantity,
    this.color,
    this.shape,
    this.notes,
    this.frequencyType = FrequencyType.daily,
    this.daysOfWeek,
    this.intervalDays,
    this.anchorDate,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.stockQuantity,
    this.stockTrackingEnabled = false,
    this.refillThreshold,
    this.refillLeadDays,
    this.packSize,
    this.refillAlertEnabled = true,
    this.refillSnoozedUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Medication copyWith({
    String? name,
    MedicationForm? form,
    double? strengthValue,
    String? strengthUnit,
    double? doseQuantity,
    String? color,
    String? shape,
    String? notes,
    FrequencyType? frequencyType,
    int? daysOfWeek,
    int? intervalDays,
    DateTime? anchorDate,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    double? stockQuantity,
    bool? stockTrackingEnabled,
    double? refillThreshold,
    int? refillLeadDays,
    double? packSize,
    bool? refillAlertEnabled,
    DateTime? refillSnoozedUntil,
    DateTime? updatedAt,
    bool? isSynced,
    // Los null no se distinguen de "no provisto" en copyWith; estos flags
    // permiten limpiar explícitamente los campos opcionales que el dominio
    // necesita borrar (ej. quitar el silenciado al recargar).
    bool clearRefillSnooze = false,
    bool clearEndDate = false,
  }) {
    return Medication(
      id: id,
      name: name ?? this.name,
      form: form ?? this.form,
      strengthValue: strengthValue ?? this.strengthValue,
      strengthUnit: strengthUnit ?? this.strengthUnit,
      doseQuantity: doseQuantity ?? this.doseQuantity,
      color: color ?? this.color,
      shape: shape ?? this.shape,
      notes: notes ?? this.notes,
      frequencyType: frequencyType ?? this.frequencyType,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      intervalDays: intervalDays ?? this.intervalDays,
      anchorDate: anchorDate ?? this.anchorDate,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      isActive: isActive ?? this.isActive,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      stockTrackingEnabled: stockTrackingEnabled ?? this.stockTrackingEnabled,
      refillThreshold: refillThreshold ?? this.refillThreshold,
      refillLeadDays: refillLeadDays ?? this.refillLeadDays,
      packSize: packSize ?? this.packSize,
      refillAlertEnabled: refillAlertEnabled ?? this.refillAlertEnabled,
      refillSnoozedUntil:
          clearRefillSnooze ? null : (refillSnoozedUntil ?? this.refillSnoozedUntil),
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'form': form.name,
      'strength_value': strengthValue,
      'strength_unit': strengthUnit,
      'dose_quantity': doseQuantity,
      'color': color,
      'shape': shape,
      'notes': notes,
      'frequency_type': frequencyType.name,
      'days_of_week': daysOfWeek,
      'interval_days': intervalDays,
      'anchor_date': anchorDate?.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'stock_quantity': stockQuantity,
      'stock_tracking_enabled': stockTrackingEnabled ? 1 : 0,
      'refill_threshold': refillThreshold,
      'refill_lead_days': refillLeadDays,
      'pack_size': packSize,
      'refill_alert_enabled': refillAlertEnabled ? 1 : 0,
      'refill_snoozed_until': refillSnoozedUntil?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as String,
      name: map['name'] as String,
      form: _formFromName(map['form'] as String?),
      strengthValue: (map['strength_value'] as num?)?.toDouble(),
      strengthUnit: map['strength_unit'] as String?,
      doseQuantity: (map['dose_quantity'] as num).toDouble(),
      color: map['color'] as String?,
      shape: map['shape'] as String?,
      notes: map['notes'] as String?,
      frequencyType: _freqFromName(map['frequency_type'] as String?),
      daysOfWeek: map['days_of_week'] as int?,
      intervalDays: map['interval_days'] as int?,
      anchorDate: _parseDate(map['anchor_date']),
      startDate: _parseDate(map['start_date']),
      endDate: _parseDate(map['end_date']),
      isActive: map['is_active'] == 1,
      stockQuantity: (map['stock_quantity'] as num?)?.toDouble(),
      stockTrackingEnabled: map['stock_tracking_enabled'] == 1,
      refillThreshold: (map['refill_threshold'] as num?)?.toDouble(),
      refillLeadDays: map['refill_lead_days'] as int?,
      packSize: (map['pack_size'] as num?)?.toDouble(),
      refillAlertEnabled: map['refill_alert_enabled'] == 1,
      refillSnoozedUntil: _parseDate(map['refill_snoozed_until']),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: map['is_synced'] == 1,
    );
  }
}
