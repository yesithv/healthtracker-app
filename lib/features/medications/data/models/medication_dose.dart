import 'package:flutter/material.dart' show TimeOfDay;
import 'package:uuid/uuid.dart';

/// Una hora de toma programada para un [Medication]. Un medicamento puede tener
/// varias (ej. 8:00 y 20:30); cada fila es una hora concreta.
class MedicationDose {
  final String id;
  final String medicationId;
  final int hour; // 0-23
  final int minute; // 0-59

  /// Unidades en esta toma. Null ⇒ usar `Medication.doseQuantity`.
  final double? quantity;

  /// Id reservado para la notificación local de esta toma. Se asigna en el
  /// rango de medicamentos para no chocar con los recordatorios existentes
  /// (ver NotificationService). Null hasta que el planificador la programe.
  final int? notifId;

  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  MedicationDose({
    String? id,
    required this.medicationId,
    required this.hour,
    required this.minute,
    this.quantity,
    this.notifId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  MedicationDose copyWith({
    String? medicationId,
    int? hour,
    int? minute,
    double? quantity,
    int? notifId,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return MedicationDose(
      id: id,
      medicationId: medicationId ?? this.medicationId,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      quantity: quantity ?? this.quantity,
      notifId: notifId ?? this.notifId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'hour': hour,
      'minute': minute,
      'quantity': quantity,
      'notif_id': notifId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory MedicationDose.fromMap(Map<String, dynamic> map) {
    return MedicationDose(
      id: map['id'] as String,
      medicationId: map['medication_id'] as String,
      hour: map['hour'] as int,
      minute: map['minute'] as int,
      quantity: (map['quantity'] as num?)?.toDouble(),
      notifId: map['notif_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: map['is_synced'] == 1,
    );
  }
}
