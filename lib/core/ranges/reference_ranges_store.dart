import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/config/api_config.dart';
import 'package:myvitals_healthtracker_app/core/demo/demo_session.dart';

/// Una banda de referencia resuelta para ESTE paciente (GET /me/reference-ranges):
/// el servidor ya eligió dispositivo-vs-baseline y filtró por sexo/edad.
class ServerBand {
  final String bandCode;
  final String bandLabel;
  final double minValue;
  final double maxValue;
  final int sortOrder;

  const ServerBand({
    required this.bandCode,
    required this.bandLabel,
    required this.minValue,
    required this.maxValue,
    required this.sortOrder,
  });

  factory ServerBand.fromJson(Map<String, dynamic> json) => ServerBand(
    bandCode: json['bandCode'] as String,
    bandLabel: json['bandLabel'] as String? ?? '',
    minValue: (json['minValue'] as num).toDouble(),
    maxValue: (json['maxValue'] as num).toDouble(),
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  );
}

/// Fuente ÚNICA de umbrales clínicos en la app: los rangos administrados en el
/// backoffice (por dispositivo/sexo/edad), servidos ya resueltos para el paciente
/// por `GET /api/v1/me/reference-ranges`.
///
/// Local-first: cachea la última respuesta buena en SharedPreferences (sirve
/// offline) y se refresca al iniciar sesión / arrancar con sesión. Los
/// clasificadores de `health_classifiers.dart` consultan [classify] primero y
/// solo caen a sus cortes de fábrica cuando aquí no hay banda aplicable
/// (invitado sin sesión, primer arranque offline o indicador sin rangos).
class ReferenceRangesStore {
  ReferenceRangesStore._();
  static final ReferenceRangesStore instance = ReferenceRangesStore._();

  static const _prefsKey = 'reference_ranges_cache_v1';

  /// Bandas por código de indicador, ordenadas por minValue ascendente.
  Map<String, List<ServerBand>> _byIndicator = {};

  bool get hasData => _byIndicator.isNotEmpty;

  /// Carga el caché y engancha el refresco a la sesión. Llamar una vez en main().
  Future<void> init() async {
    await _loadCache();
    PatientSession.instance.addListener(_onSessionChanged);
    if (PatientSession.instance.isAuthenticated) {
      unawaited(refresh());
    }
  }

  void _onSessionChanged() {
    if (PatientSession.instance.isAuthenticated) {
      unawaited(refresh());
    }
  }

  /// Baja los rangos del servidor (best-effort: sin red se queda el caché).
  Future<void> refresh({http.Client? httpClient}) async {
    // La demo corre sin servidor: los clasificadores usan sus cortes de fábrica
    // y no se emite ni una petición. Evita además llenar la consola de errores
    // de conexión mientras se graba la pantalla.
    if (DemoSession.instance.isActive) return;
    if (!ApiConfig.isConfigured) return;
    // Sin sesión no hay a quién pedirle rangos: la API respondería 401.
    final auth = PatientSession.instance.authHeaders;
    if (auth.isEmpty) return;

    final client = httpClient ?? http.Client();
    try {
      final resp = await client
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/me/reference-ranges'),
            headers: auth,
          )
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode >= 200 &&
          resp.statusCode < 300 &&
          resp.body.isNotEmpty) {
        _apply(jsonDecode(resp.body) as Map<String, dynamic>);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsKey, resp.body);
      }
    } catch (e) {
      debugPrint(
        'ReferenceRanges: refresh no disponible ($e); se usa el caché.',
      );
    } finally {
      if (httpClient == null) client.close();
    }
  }

  /// Bandas del indicador para este paciente (vacío = sin rangos aplicables).
  /// Para pintar zonas de color en las gráficas.
  List<ServerBand> bandsOf(String indicatorCode) =>
      List.unmodifiable(_byIndicator[indicatorCode] ?? const []);

  /// Banda a la que pertenece [value] para el indicador, o null si no hay rangos
  /// aplicables (el llamador cae a su fallback). Valores fuera de la escala se
  /// ajustan a la banda extrema (una lectura absurda sigue siendo "muy alto").
  ServerBand? classify(String indicatorCode, num value) {
    final bands = _byIndicator[indicatorCode];
    if (bands == null || bands.isEmpty) return null;
    for (final b in bands) {
      if (value >= b.minValue && value <= b.maxValue) return b;
    }
    if (value < bands.first.minValue) return bands.first;
    return bands.last;
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        _apply(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('ReferenceRanges: caché ilegible, se ignora ($e).');
    }
  }

  void _apply(Map<String, dynamic> json) {
    final parsed = <String, List<ServerBand>>{};
    for (final ind in (json['indicators'] as List<dynamic>? ?? [])) {
      final map = ind as Map<String, dynamic>;
      final code = map['indicatorCode'] as String?;
      if (code == null) continue;
      final bands =
          (map['bands'] as List<dynamic>? ?? [])
              .map((b) => ServerBand.fromJson(b as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.minValue.compareTo(b.minValue));
      if (bands.isNotEmpty) parsed[code] = bands;
    }
    _byIndicator = parsed;
  }

  /// Siembra el store en pruebas (sin red ni prefs).
  @visibleForTesting
  void setForTesting(Map<String, List<ServerBand>> data) {
    _byIndicator = {
      for (final e in data.entries)
        e.key: [...e.value]..sort((a, b) => a.minValue.compareTo(b.minValue)),
    };
  }
}
