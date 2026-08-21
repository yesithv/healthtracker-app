import 'dart:collection';

import 'package:myvitals_healthtracker_app/core/sync/measurement_read_client.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/anthropometric_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/body_composition_record.dart';

/// Resultado de reconstruir registros locales a partir de la serie del servidor.
class LegacyImport {
  final List<AnthropometricRecord> anthropometric;
  final List<BodyCompositionRecord> bodyComposition;

  const LegacyImport({
    this.anthropometric = const [],
    this.bodyComposition = const [],
  });

  bool get isEmpty => anthropometric.isEmpty && bodyComposition.isEmpty;
}

/// Traducción PURA (sin I/O) de la serie plana del servidor (GET /me/measurements)
/// a los registros tipados de la BD local, para que el historial migrado del legacy
/// se vea en el dashboard/historiales locales de la app (que son local-first).
///
/// Reglas:
///  - Solo puntos `source == 'LEGACY'`: los `APP` nacieron en esta app y ya viven
///    en SQLite (re-importarlos duplicaría).
///  - Un registro por instante (`measuredAt`): la curación asigna el mismo instante
///    a todos los indicadores de una misma atención.
///  - Antropometría: WEIGHT + HEIGHT (+ BMI) y los perímetros (WAIST/HIP/
///    LOWER_ABDOMEN/ARM/LEG/CHEST_BUST → cm). Si una atención no trae talla se
///    arrastra la última conocida (forward-fill); sin talla alguna, se salta. Si no
///    hay BMI se calcula de peso/talla.
///  - Composición corporal: BODY_FAT → % grasa, MUSCLE_PCT → % músculo esquelético,
///    VISCERAL_FAT_LEVEL → nivel OMRON (también acepta el código viejo VISCERAL_FAT:
///    el dump demostró que siempre fue el nivel, mal etiquetado como % — V25 lo
///    unificó en el servidor), KCAL → TMB, BODY_AGE → edad metabólica.
///  - Los registros nacen con `isSynced = true`: vinieron DEL servidor y no deben
///    volver a subirse.
class LegacyImportMapper {
  const LegacyImportMapper._();

  static LegacyImport fromServer(List<ServerMeasurement> points) {
    // Agrupa por instante, ordenado ascendente para el forward-fill de la talla.
    final byInstant = SplayTreeMap<DateTime, Map<String, num>>();
    for (final p in points) {
      if (p.source != 'LEGACY' || p.value == null) continue;
      byInstant.putIfAbsent(p.measuredAt, () => {})[p.indicatorCode] = p.value!;
    }

    final anthropometric = <AnthropometricRecord>[];
    final bodyComposition = <BodyCompositionRecord>[];
    double? lastHeight;

    for (final entry in byInstant.entries) {
      final m = entry.value;

      // ── Antropometría ────────────────────────────────────────────────
      final weight = m['WEIGHT']?.toDouble();
      final heightAtPoint = m['HEIGHT']?.toDouble();
      if (heightAtPoint != null && heightAtPoint > 0)
        lastHeight = heightAtPoint;
      final height = heightAtPoint ?? lastHeight;
      if (weight != null && height != null && height > 0) {
        final bmi =
            m['BMI']?.toDouble() ??
            double.parse((weight / (height * height)).toStringAsFixed(1));
        anthropometric.add(
          AnthropometricRecord(
            date: entry.key,
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
            isSynced: true,
          ),
        );
      }

      // ── Composición corporal ─────────────────────────────────────────
      final bodyFat = m['BODY_FAT']?.toDouble();
      final musclePct = m['MUSCLE_PCT']?.toDouble();
      // Código unificado (V25); el viejo se acepta por si el backend aún no migró.
      final visceral = (m['VISCERAL_FAT_LEVEL'] ?? m['VISCERAL_FAT'])?.round();
      final kcal = m['KCAL']?.round();
      final bodyAge = m['BODY_AGE']?.round();
      if (bodyFat != null ||
          musclePct != null ||
          visceral != null ||
          kcal != null ||
          bodyAge != null) {
        bodyComposition.add(
          BodyCompositionRecord(
            date: entry.key,
            bodyFatPercent: bodyFat,
            musclePct: musclePct,
            visceralFatLevel: visceral,
            bmrKcal: kcal,
            metabolicAge: bodyAge,
            isSynced: true,
          ),
        );
      }
    }

    return LegacyImport(
      anthropometric: anthropometric,
      bodyComposition: bodyComposition,
    );
  }
}
