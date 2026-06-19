import 'package:uuid/uuid.dart';

class VitalSignRecord {
  final String id;
  final DateTime date;
  final int systolic; // mmHg
  final int diastolic; // mmHg
  final int heartRate; // bpm
  final String? activityState; // reposo, ejercicio, post-op
  final String? symptom; // normal, mareo, dolor, fatiga
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  VitalSignRecord({
    String? id,
    required this.date,
    required this.systolic,
    required this.diastolic,
    required this.heartRate,
    this.activityState,
    this.symptom,
    this.comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'measurement_date': date.toIso8601String(),
      'systolic': systolic,
      'diastolic': diastolic,
      'heart_rate': heartRate,
      'activity_state': activityState,
      'symptom': symptom,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory VitalSignRecord.fromMap(Map<String, dynamic> map) {
    return VitalSignRecord(
      id: map['id'],
      date: DateTime.parse(map['measurement_date']),
      systolic: map['systolic'],
      diastolic: map['diastolic'],
      heartRate: map['heart_rate'],
      activityState: map['activity_state'],
      symptom: map['symptom'],
      comment: map['comment'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isSynced: map['is_synced'] == 1,
    );
  }
}
