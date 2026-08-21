import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myvitals_healthtracker_app/core/config/api_config.dart';
import 'package:myvitals_healthtracker_app/core/ranges/reference_ranges_store.dart'
    show ServerBand;

/// Rangos de referencia POR LABORATORIO (GET /api/v1/labs/{code}/ranges): la fuente de
/// verdad para interpretar exámenes de laboratorio (lípidos, glucosa...) según el lab
/// donde el paciente se tomó CADA examen (su `labCode`).
///
/// Local-first como [ReferenceRangesStore]: cachea por laboratorio en SharedPreferences;
/// el fetch se dispara al seleccionar un lab en la captura ([ensureLoaded]) y las demás
/// pantallas clasifican con lo cacheado. Sin datos → el clasificador cae a ATP III.
///
/// Nota Fase 0: se usan las bandas sin distinción de sexo/edad (`sex='ANY'`, como están
/// sembradas); si un lab definiera bandas por sexo/edad, refinar aquí con el perfil.
class LabRangesStore {
  LabRangesStore._();
  static final LabRangesStore instance = LabRangesStore._();

  static const _prefsKey = 'lab_ranges_cache_v1';

  /// labCode → indicatorCode → bandas ordenadas por minValue.
  final Map<String, Map<String, List<ServerBand>>> _byLab = {};
  final Set<String> _fetching = {};
  bool _cacheLoaded = false;

  /// Carga el caché persistido (perezoso, una vez).
  Future<void> _ensureCache() async {
    if (_cacheLoaded) return;
    _cacheLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      (jsonDecode(raw) as Map<String, dynamic>).forEach(
        (lab, bands) => _apply(lab, bands as List<dynamic>),
      );
    } catch (e) {
      debugPrint('LabRanges: caché ilegible, se ignora ($e).');
    }
  }

  /// Trae (una vez) los rangos del laboratorio; best-effort y deduplicado.
  Future<void> ensureLoaded(String labCode) async {
    await _ensureCache();
    if (labCode.isEmpty ||
        _byLab.containsKey(labCode) ||
        _fetching.contains(labCode)) {
      return;
    }
    if (ApiConfig.baseUrl.isEmpty) return;
    _fetching.add(labCode);
    final client = http.Client();
    try {
      final resp = await client
          .get(Uri.parse('${ApiConfig.baseUrl}/api/v1/labs/$labCode/ranges'))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode >= 200 &&
          resp.statusCode < 300 &&
          resp.body.isNotEmpty) {
        final list = jsonDecode(resp.body) as List<dynamic>;
        _apply(labCode, list);
        await _persist();
      }
    } catch (e) {
      debugPrint('LabRanges: rangos de $labCode no disponibles ($e).');
    } finally {
      _fetching.remove(labCode);
      client.close();
    }
  }

  /// Banda del examen para (lab, indicador), o null si no hay datos cacheados
  /// (el llamador cae a su fallback). Fuera de escala → banda extrema.
  ServerBand? classify(String labCode, String indicatorCode, num value) {
    final bands = _byLab[labCode]?[indicatorCode];
    if (bands == null || bands.isEmpty) return null;
    for (final b in bands) {
      if (value >= b.minValue && value <= b.maxValue) return b;
    }
    if (value < bands.first.minValue) return bands.first;
    return bands.last;
  }

  void _apply(String labCode, List<dynamic> rows) {
    final parsed = <String, List<ServerBand>>{};
    for (final r in rows) {
      final map = r as Map<String, dynamic>;
      // Fase 0: solo bandas sin distinción de sexo (así están sembradas los labs).
      if ((map['sex'] as String? ?? 'ANY') != 'ANY') continue;
      final code = map['indicatorCode'] as String?;
      if (code == null) continue;
      (parsed[code] ??= []).add(
        ServerBand(
          bandCode: map['bandCode'] as String,
          bandLabel: map['bandLabel'] as String? ?? '',
          minValue: (map['minValue'] as num).toDouble(),
          maxValue: (map['maxValue'] as num).toDouble(),
          sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
        ),
      );
    }
    for (final bands in parsed.values) {
      bands.sort((a, b) => a.minValue.compareTo(b.minValue));
    }
    if (parsed.isNotEmpty) _byLab[labCode] = parsed;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final out = <String, List<Map<String, Object>>>{};
      _byLab.forEach((lab, byIndicator) {
        final rows = <Map<String, Object>>[];
        byIndicator.forEach((code, bands) {
          for (final b in bands) {
            rows.add({
              'indicatorCode': code,
              'sex': 'ANY',
              'bandCode': b.bandCode,
              'bandLabel': b.bandLabel,
              'sortOrder': b.sortOrder,
              'minValue': b.minValue,
              'maxValue': b.maxValue,
            });
          }
        });
        out[lab] = rows;
      });
      await prefs.setString(_prefsKey, jsonEncode(out));
    } catch (e) {
      debugPrint('LabRanges: no se pudo persistir el caché ($e).');
    }
  }

  /// Siembra el store en pruebas (sin red ni prefs).
  @visibleForTesting
  void setForTesting(Map<String, Map<String, List<ServerBand>>> data) {
    _cacheLoaded = true;
    _byLab
      ..clear()
      ..addAll(data);
  }
}
