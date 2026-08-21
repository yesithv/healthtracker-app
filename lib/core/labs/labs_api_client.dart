import 'dart:convert';

import 'package:myvitals_healthtracker_app/core/diagnostics/debug_log.dart';

import 'package:http/http.dart' as http;

import 'package:myvitals_healthtracker_app/core/config/api_config.dart';

import 'lab.dart';

/// Lee el catálogo público de laboratorios de la HealthTracker-Api
/// (`GET /api/v1/labs`). Sin catálogo (API caída) devuelve lista vacía: la pantalla
/// cae a "Otro" con texto libre, así el usuario nunca queda bloqueado.
class LabsApiClient {
  final http.Client _http;
  final Duration timeout;

  LabsApiClient({
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 6),
  }) : _http = httpClient ?? http.Client();

  Future<List<Lab>> fetchLabs() async {
    if (ApiConfig.baseUrl.isEmpty) return const [];
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/labs');
      final resp = await _http.get(uri).timeout(timeout);
      if (resp.statusCode < 200 ||
          resp.statusCode >= 300 ||
          resp.body.isEmpty) {
        return const [];
      }
      final list = jsonDecode(resp.body) as List<dynamic>;
      return list.map((e) => Lab.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugLogError('Labs.fetch', e);
      // Sin red / error: la app usa el fallback "Otro" (texto libre).
      return const [];
    }
  }

  void close() => _http.close();
}
