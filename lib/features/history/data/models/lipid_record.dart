import 'package:uuid/uuid.dart';

class LipidRecord {
  final String id;
  final DateTime date;
  final double? totalCholesterol;
  final double? ldl;
  final double? hdl;
  final double? vldl;
  final double? triglycerides;
  final String? labName;

  /// Código del laboratorio elegido del catálogo (vocabulario controlado,
  /// `laboratory.code`). null = "Otro" (ver [labName]) o "No sé/Ninguno".
  final String? labCode;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  LipidRecord({
    String? id,
    required this.date,
    this.totalCholesterol,
    this.ldl,
    this.hdl,
    this.vldl,
    this.triglycerides,
    this.labName,
    this.labCode,
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
      'total_cholesterol': totalCholesterol,
      'ldl': ldl,
      'hdl': hdl,
      'vldl': vldl,
      'triglycerides': triglycerides,
      'lab_name': labName,
      'lab_code': labCode,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory LipidRecord.fromMap(Map<String, dynamic> map) {
    return LipidRecord(
      id: map['id'],
      date: DateTime.parse(map['measurement_date']),
      totalCholesterol: map['total_cholesterol'],
      ldl: map['ldl'],
      hdl: map['hdl'],
      vldl: map['vldl'],
      triglycerides: map['triglycerides'],
      labName: map['lab_name'],
      labCode: map['lab_code'],
      comment: map['comment'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isSynced: map['is_synced'] == 1,
    );
  }
}
