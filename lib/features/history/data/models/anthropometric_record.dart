import 'package:uuid/uuid.dart';

class AnthropometricRecord {
  final String id;
  final DateTime date;
  final double weight;
  final double height;
  final double bmi;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  AnthropometricRecord({
    String? id,
    required this.date,
    required this.weight,
    required this.height,
    required this.bmi,
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
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory AnthropometricRecord.fromMap(Map<String, dynamic> map) {
    return AnthropometricRecord(
      id: map['id'],
      date: DateTime.parse(map['measurement_date']),
      weight: map['weight'],
      height: map['height'],
      bmi: map['bmi'],
      comment: map['comment'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isSynced: map['is_synced'] == 1,
    );
  }
}
