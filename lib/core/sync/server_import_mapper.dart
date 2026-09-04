import 'dart:collection';

import 'package:myvitals_healthtracker_app/core/sync/measurement_read_client.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/anthropometric_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/body_composition_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/lipid_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/vital_sign_record.dart';

/// Resultado de reconstruir registros locales a partir de la serie del servidor.
class ServerImport {
  final List<AnthropometricRecord> anthropometric;
  final List<VitalSignRecord> vitalSigns;
  final List<LipidRecord> lipids;
  final List<BodyCompositionRecord> bodyComposition;

  const ServerImport({
    this.anthropometric = const [],
    this.vitalSigns = const [],
    this.lipids = const [],
    this.bodyComposition = const [],
  });

  bool get isEmpty =>
      anthropometric.isEmpty &&
      vitalSigns.isEmpty &&
      lipids.isEmpty &&
      bodyComposition.isEmpty;
}

/// Traducción PURA (sin I/O) de la serie plana del servidor (`GET /me/measurements`)
/// a los registros tipados de la BD local.
///
/// <h3>Por qué ya no se llama «legacy»</h3>
///
/// Antes solo dejaba pasar los puntos `source == 'LEGACY'`, con este argumento: los
/// `APP` «ya viven en SQLite, re-importarlos duplicaría». Eso vale **mientras el
/// teléfono conserve su SQLite**. En uno recién instalado —o en un móvil nuevo— SQLite
/// está vacío, y esa regla tiraba justo lo que la persona había escrito a mano. El
/// servidor lo tenía y lo devolvía; era este mapa el que lo desechaba. La duplicación
/// se evita donde toca: deduplicando contra lo que hay en local
/// ([MeasurementDownloadService]), no negándose a mirar.
///
/// <h3>Las cuatro familias, no dos</h3>
///
/// Subir emite las cuatro ([MeasurementMapper]); bajar reconstruía antropometría y
/// composición corporal. Los signos vitales y los lípidos no volvían nunca. La ida y la
/// vuelta tienen que hablar el mismo vocabulario o la pérdida se repite: los códigos de
/// aquí son los mismos que emite `MeasurementMapper`.
///
/// <h3>Reglas</h3>
///
///  - **Un registro por grupo.** El grupo es el `clientId` cuando el punto lo trae —así
///    un registro reinstalado vuelve con su identidad, no como una copia parecida— y el
///    instante cuando no, que es el caso del legacy: la curación asigna el mismo
///    instante a todos los indicadores de una atención.
///  - Antropometría: WEIGHT + HEIGHT (+ BMI) y los perímetros. Si una atención no trae
///    talla se arrastra la última conocida (forward-fill); sin talla alguna, se salta.
///    Si no hay BMI se calcula de peso y talla.
///  - Composición corporal: BODY_FAT, MUSCLE_MASS, MUSCLE_PCT, VISCERAL_FAT_LEVEL
///    (también el código viejo VISCERAL_FAT: el dump demostró que siempre fue el nivel,
///    mal etiquetado como % — V25 lo unificó en el servidor), KCAL, BODY_AGE,
///    BODY_WATER y BONE_MASS.
///  - Signos vitales: BP_SYSTOLIC, BP_DIASTOLIC y HEART_RATE. Hacen falta los tres:
///    media tensión no es un registro.
///  - Lípidos: cualquiera de los cinco valores basta, porque un perfil incompleto sigue
///    siendo un resultado de laboratorio.
///  - Los registros nacen con `isSynced = true`: vinieron DEL servidor y volver a
///    subirlos sería un bucle.
class ServerImportMapper {
  const ServerImportMapper._();

  static ServerImport fromServer(List<ServerMeasurement> points) {
    final groups = SplayTreeMap<_GroupKey, _Group>();
    for (final p in points) {
      if (p.value == null) continue;
      final key = _GroupKey(p.measuredAt, p.clientId ?? '');
      groups.putIfAbsent(key, () => _Group(p.measuredAt, p.clientId))
        ..values[p.indicatorCode] = p.value!
        ..absorb(p);
    }

    final anthropometric = <AnthropometricRecord>[];
    final vitalSigns = <VitalSignRecord>[];
    final lipids = <LipidRecord>[];
    final bodyComposition = <BodyCompositionRecord>[];
    double? lastHeight;

    for (final group in groups.values) {
      final m = group.values;

      // ── Antropometría ────────────────────────────────────────────────
      final weight = m['WEIGHT']?.toDouble();
      final heightAtPoint = m['HEIGHT']?.toDouble();
      if (heightAtPoint != null && heightAtPoint > 0) {
        lastHeight = heightAtPoint;
      }
      final height = heightAtPoint ?? lastHeight;
      if (weight != null && height != null && height > 0) {
        final bmi =
            m['BMI']?.toDouble() ??
            double.parse((weight / (height * height)).toStringAsFixed(1));
        anthropometric.add(
          AnthropometricRecord(
            id: group.clientId,
            date: group.measuredAt,
            weight: weight,
            // El servidor entrega la talla en METROS; el modelo local es en cm
            // (así la maneja la pantalla de captura).
            height: double.parse((height * 100).toStringAsFixed(1)),
            bmi: bmi,
            waistCm: m['WAIST']?.toDouble(),
            hipCm: m['HIP']?.toDouble(),
            lowerAbdomenCm: m['LOWER_ABDOMEN']?.toDouble(),
            armCm: m['ARM']?.toDouble(),
            legCm: m['LEG']?.toDouble(),
            chestBustCm: m['CHEST_BUST']?.toDouble(),
            comment: group.note,
            isSynced: true,
          ),
        );
      }

      // ── Signos vitales ───────────────────────────────────────────────
      final systolic = m['BP_SYSTOLIC']?.round();
      final diastolic = m['BP_DIASTOLIC']?.round();
      final heartRate = m['HEART_RATE']?.round();
      if (systolic != null && diastolic != null && heartRate != null) {
        vitalSigns.add(
          VitalSignRecord(
            id: group.clientId,
            date: group.measuredAt,
            systolic: systolic,
            diastolic: diastolic,
            heartRate: heartRate,
            activityState: group.text('activityState'),
            symptom: group.text('symptom'),
            comment: group.note,
            isSynced: true,
          ),
        );
      }

      // ── Lípidos ──────────────────────────────────────────────────────
      final total = m['CHOLESTEROL_TOTAL']?.toDouble();
      final ldl = m['CHOLESTEROL_LDL']?.toDouble();
      final hdl = m['CHOLESTEROL_HDL']?.toDouble();
      final vldl = m['CHOLESTEROL_VLDL']?.toDouble();
      final triglycerides = m['TRIGLYCERIDES']?.toDouble();
      if (total != null ||
          ldl != null ||
          hdl != null ||
          vldl != null ||
          triglycerides != null) {
        lipids.add(
          LipidRecord(
            id: group.clientId,
            date: group.measuredAt,
            totalCholesterol: total,
            ldl: ldl,
            hdl: hdl,
            vldl: vldl,
            triglycerides: triglycerides,
            labCode: group.text('labCode'),
            labName: group.text('labName'),
            comment: group.note,
            isSynced: true,
          ),
        );
      }

      // ── Composición corporal ─────────────────────────────────────────
      final bodyFat = m['BODY_FAT']?.toDouble();
      final muscleMass = m['MUSCLE_MASS']?.toDouble();
      final musclePct = m['MUSCLE_PCT']?.toDouble();
      // Código unificado (V25); el viejo se acepta por si el backend aún no migró.
      final visceral = (m['VISCERAL_FAT_LEVEL'] ?? m['VISCERAL_FAT'])?.round();
      final kcal = m['KCAL']?.round();
      final bodyAge = m['BODY_AGE']?.round();
      final water = m['BODY_WATER']?.toDouble();
      final bone = m['BONE_MASS']?.toDouble();
      if (bodyFat != null ||
          muscleMass != null ||
          musclePct != null ||
          visceral != null ||
          kcal != null ||
          bodyAge != null ||
          water != null ||
          bone != null) {
        bodyComposition.add(
          BodyCompositionRecord(
            id: group.clientId,
            date: group.measuredAt,
            bodyFatPercent: bodyFat,
            muscleMassKg: muscleMass,
            musclePct: musclePct,
            visceralFatLevel: visceral,
            metabolicAge: bodyAge,
            bmrKcal: kcal,
            bodyWaterPercent: water,
            boneMassKg: bone,
            deviceName: group.text('deviceName'),
            comment: group.note,
            isSynced: true,
          ),
        );
      }
    }

    return ServerImport(
      anthropometric: anthropometric,
      vitalSigns: vitalSigns,
      lipids: lipids,
      bodyComposition: bodyComposition,
    );
  }
}

/// Ordena por instante y, dentro del mismo instante, separa registros distintos.
///
/// El orden por instante no es decorativo: el forward-fill de la talla lo necesita
/// cronológico. El `id` desempata para que dos registros hechos en el mismo segundo no
/// se fundan en uno.
class _GroupKey implements Comparable<_GroupKey> {
  final DateTime measuredAt;
  final String id;

  const _GroupKey(this.measuredAt, this.id);

  @override
  int compareTo(_GroupKey other) {
    final byTime = measuredAt.compareTo(other.measuredAt);
    return byTime != 0 ? byTime : id.compareTo(other.id);
  }
}

/// Los puntos que formaban un registro, otra vez juntos.
class _Group {
  final DateTime measuredAt;
  final String? clientId;
  final Map<String, num> values = {};
  final Map<String, dynamic> context = {};
  String? note;

  _Group(this.measuredAt, this.clientId);

  /// Nota y contexto son del registro, no del punto: el aplanado los repitió en cada
  /// uno. Se queda el primero que venga con algo.
  void absorb(ServerMeasurement point) {
    note ??= (point.note?.trim().isNotEmpty ?? false) ? point.note : null;
    for (final entry in point.context.entries) {
      context.putIfAbsent(entry.key, () => entry.value);
    }
  }

  String? text(String key) {
    final value = context[key];
    return value is String && value.trim().isNotEmpty ? value : null;
  }
}
