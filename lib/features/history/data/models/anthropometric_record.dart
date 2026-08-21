import 'package:uuid/uuid.dart';

class AnthropometricRecord {
  final String id;
  final DateTime date;
  final double weight;
  final double height;
  final double bmi;

  // Perímetros corporales en cm (opcionales) — mismos campos que mide la consulta
  // en el legacy (cintura, cadera, abdomen bajo, brazo, pierna, pecho/busto).
  final double? waistCm;
  final double? hipCm;
  final double? lowerAbdomenCm;
  final double? armCm;
  final double? legCm;
  final double? chestBustCm;

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
    this.waistCm,
    this.hipCm,
    this.lowerAbdomenCm,
    this.armCm,
    this.legCm,
    this.chestBustCm,
    this.comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Índice cintura-altura (WHtR): cintura ÷ altura, ambas en cm (adimensional).
  /// Indicador cardiometabólico con umbral universal 0.5 (no depende de sexo/edad).
  /// `null` si falta la cintura o la altura no es válida.
  double? get whtr =>
      (waistCm != null && height > 0) ? waistCm! / height : null;

  /// Índice cintura-cadera (WHR): cintura ÷ cadera (adimensional). Distingue la
  /// distribución de grasa androide/ginoide; los cortes de riesgo dependen del
  /// sexo. `null` si falta cualquiera de los dos perímetros.
  double? get whr => (waistCm != null && hipCm != null && hipCm! > 0)
      ? waistCm! / hipCm!
      : null;

  /// ¿Trae al menos un perímetro? (para mostrar u ocultar la sección en historiales).
  bool get hasCircumferences =>
      waistCm != null ||
      hipCm != null ||
      lowerAbdomenCm != null ||
      armCm != null ||
      legCm != null ||
      chestBustCm != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'measurement_date': date.toIso8601String(),
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'waist_cm': waistCm,
      'hip_cm': hipCm,
      'lower_abdomen_cm': lowerAbdomenCm,
      'arm_cm': armCm,
      'leg_cm': legCm,
      'chest_bust_cm': chestBustCm,
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
      waistCm: map['waist_cm'],
      hipCm: map['hip_cm'],
      lowerAbdomenCm: map['lower_abdomen_cm'],
      armCm: map['arm_cm'],
      legCm: map['leg_cm'],
      chestBustCm: map['chest_bust_cm'],
      comment: map['comment'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isSynced: map['is_synced'] == 1,
    );
  }
}
