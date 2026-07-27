import 'package:myvitals_healthtracker_app/features/history/data/models/anthropometric_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/body_composition_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/lipid_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/vital_sign_record.dart';

/// Un punto de medición en el contrato de ingest de la HealthTracker-Api
/// (`POST /api/v1/me/measurements`). Es el formato PLANO dirigido por catálogo:
/// cada campo medido de un registro local se convierte en un item que referencia
/// el `code` del indicador en el servidor.
class IngestItem {
  /// Id del registro local en la app (varios items comparten el de su registro).
  final String clientId;

  /// Código del catálogo del servidor (`app.indicator_type.code`), p. ej. 'WEIGHT'.
  final String indicatorCode;

  /// Instante de la medición.
  final DateTime measuredAt;

  /// Valor numérico (los indicadores INTEGER viajan como entero).
  final num value;

  /// Comentario libre del usuario (opcional).
  final String? note;

  /// Metadatos que no son serie (estado de actividad, síntoma, laboratorio,
  /// dispositivo…). Solo se incluyen las claves con valor.
  final Map<String, Object?> context;

  const IngestItem({
    required this.clientId,
    required this.indicatorCode,
    required this.measuredAt,
    required this.value,
    this.note,
    this.context = const {},
  });

  Map<String, dynamic> toJson() => {
    'clientId': clientId,
    'indicatorCode': indicatorCode,
    // El servidor espera un instante UTC (Instant ISO-8601).
    'measuredAt': measuredAt.toUtc().toIso8601String(),
    'value': value,
    if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
    if (context.isNotEmpty) 'context': context,
  };
}

/// Aplana los registros locales (SQLite) en items de ingest. Es una traducción
/// PURA (sin I/O): el conjunto de `indicatorCode` debe coincidir con el catálogo
/// del servidor sembrado en Flyway (V7/V10/V15/V18). Fuente única de ese contrato.
///
/// Reglas: se emite un item por cada campo con valor (los campos opcionales nulos
/// se omiten); el `comment` viaja como `note`; los metadatos por familia van en
/// `context` (solo las claves presentes).
class MeasurementMapper {
  const MeasurementMapper._();

  static List<IngestItem> fromAnthropometric(AnthropometricRecord r) => [
    IngestItem(
      clientId: r.id,
      indicatorCode: 'WEIGHT',
      measuredAt: r.date,
      value: r.weight,
      note: r.comment,
    ),
    IngestItem(
      clientId: r.id,
      indicatorCode: 'HEIGHT',
      measuredAt: r.date,
      // El modelo local guarda cm; el indicador HEIGHT del catálogo es en
      // METROS (0.3–2.6): sin esta conversión el servidor rechaza la talla.
      value: r.height > 3
          ? double.parse((r.height / 100).toStringAsFixed(2))
          : r.height,
      note: r.comment,
    ),
    IngestItem(
      clientId: r.id,
      indicatorCode: 'BMI',
      measuredAt: r.date,
      value: r.bmi,
      note: r.comment,
    ),
    // Perímetros corporales (cm), mismos códigos que cura el legacy.
    if (r.waistCm != null)
      _item(r.id, 'WAIST', r.date, r.waistCm!, r.comment, const {}),
    if (r.hipCm != null)
      _item(r.id, 'HIP', r.date, r.hipCm!, r.comment, const {}),
    if (r.lowerAbdomenCm != null)
      _item(
        r.id,
        'LOWER_ABDOMEN',
        r.date,
        r.lowerAbdomenCm!,
        r.comment,
        const {},
      ),
    if (r.armCm != null)
      _item(r.id, 'ARM', r.date, r.armCm!, r.comment, const {}),
    if (r.legCm != null)
      _item(r.id, 'LEG', r.date, r.legCm!, r.comment, const {}),
    if (r.chestBustCm != null)
      _item(r.id, 'CHEST_BUST', r.date, r.chestBustCm!, r.comment, const {}),
  ];

  static List<IngestItem> fromVitalSign(VitalSignRecord r) {
    final context = <String, Object?>{
      if (r.activityState != null) 'activityState': r.activityState,
      if (r.symptom != null) 'symptom': r.symptom,
    };
    return [
      _item(r.id, 'BP_SYSTOLIC', r.date, r.systolic, r.comment, context),
      _item(r.id, 'BP_DIASTOLIC', r.date, r.diastolic, r.comment, context),
      _item(r.id, 'HEART_RATE', r.date, r.heartRate, r.comment, context),
    ];
  }

  static List<IngestItem> fromLipid(LipidRecord r) {
    final context = <String, Object?>{
      if (r.labCode != null) 'labCode': r.labCode,
      if (r.labName != null) 'labName': r.labName,
    };
    return [
      if (r.totalCholesterol != null)
        _item(
          r.id,
          'CHOLESTEROL_TOTAL',
          r.date,
          r.totalCholesterol!,
          r.comment,
          context,
        ),
      if (r.ldl != null)
        _item(r.id, 'CHOLESTEROL_LDL', r.date, r.ldl!, r.comment, context),
      if (r.hdl != null)
        _item(r.id, 'CHOLESTEROL_HDL', r.date, r.hdl!, r.comment, context),
      if (r.vldl != null)
        _item(r.id, 'CHOLESTEROL_VLDL', r.date, r.vldl!, r.comment, context),
      if (r.triglycerides != null)
        _item(
          r.id,
          'TRIGLYCERIDES',
          r.date,
          r.triglycerides!,
          r.comment,
          context,
        ),
    ];
  }

  static List<IngestItem> fromBodyComposition(BodyCompositionRecord r) {
    final context = <String, Object?>{
      if (r.deviceName != null) 'deviceName': r.deviceName,
    };
    return [
      if (r.bodyFatPercent != null)
        _item(r.id, 'BODY_FAT', r.date, r.bodyFatPercent!, r.comment, context),
      if (r.muscleMassKg != null)
        _item(r.id, 'MUSCLE_MASS', r.date, r.muscleMassKg!, r.comment, context),
      // % de músculo esquelético: lo que reporta OMRON y guarda el legacy.
      if (r.musclePct != null)
        _item(r.id, 'MUSCLE_PCT', r.date, r.musclePct!, r.comment, context),
      if (r.visceralFatLevel != null)
        _item(
          r.id,
          'VISCERAL_FAT_LEVEL',
          r.date,
          r.visceralFatLevel!,
          r.comment,
          context,
        ),
      if (r.metabolicAge != null)
        _item(r.id, 'BODY_AGE', r.date, r.metabolicAge!, r.comment, context),
      if (r.bmrKcal != null)
        _item(r.id, 'KCAL', r.date, r.bmrKcal!, r.comment, context),
      if (r.bodyWaterPercent != null)
        _item(
          r.id,
          'BODY_WATER',
          r.date,
          r.bodyWaterPercent!,
          r.comment,
          context,
        ),
      if (r.boneMassKg != null)
        _item(r.id, 'BONE_MASS', r.date, r.boneMassKg!, r.comment, context),
    ];
  }

  static IngestItem _item(
    String id,
    String code,
    DateTime date,
    num value,
    String? note,
    Map<String, Object?> context,
  ) => IngestItem(
    clientId: id,
    indicatorCode: code,
    measuredAt: date,
    value: value,
    note: note,
    context: context,
  );
}
