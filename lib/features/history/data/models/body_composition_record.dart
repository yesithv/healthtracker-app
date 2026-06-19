import 'package:uuid/uuid.dart';

class BodyCompositionRecord {
  final String id;
  final DateTime date;
  final double? bodyFatPercent;
  final double? muscleMassKg;
  final int? visceralFatLevel;
  final int? metabolicAge;
  final int? bmrKcal;
  final double? bodyWaterPercent;
  final double? boneMassKg;
  final String? deviceName;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  BodyCompositionRecord({
    String? id,
    required this.date,
    this.bodyFatPercent,
    this.muscleMassKg,
    this.visceralFatLevel,
    this.metabolicAge,
    this.bmrKcal,
    this.bodyWaterPercent,
    this.boneMassKg,
    this.deviceName,
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
      'body_fat_percent': bodyFatPercent,
      'muscle_mass_kg': muscleMassKg,
      'visceral_fat_level': visceralFatLevel,
      'metabolic_age': metabolicAge,
      'bmr_kcal': bmrKcal,
      'body_water_percent': bodyWaterPercent,
      'bone_mass_kg': boneMassKg,
      'device_name': deviceName,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory BodyCompositionRecord.fromMap(Map<String, dynamic> map) {
    return BodyCompositionRecord(
      id: map['id'],
      date: DateTime.parse(map['measurement_date']),
      bodyFatPercent: map['body_fat_percent'],
      muscleMassKg: map['muscle_mass_kg'],
      visceralFatLevel: map['visceral_fat_level'],
      metabolicAge: map['metabolic_age'],
      bmrKcal: map['bmr_kcal'],
      bodyWaterPercent: map['body_water_percent'],
      boneMassKg: map['bone_mass_kg'],
      deviceName: map['device_name'],
      comment: map['comment'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isSynced: map['is_synced'] == 1,
    );
  }
}
