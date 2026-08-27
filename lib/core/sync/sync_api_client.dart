import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/config/api_config.dart';
import 'package:myvitals_healthtracker_app/core/sync/measurement_mapper.dart';

/// Resultado que devuelve la API tras un ingest: cuántos puntos guardó y el
/// detalle de los rechazados (el ingest es tolerante: acepta lo válido).
class IngestResult {
  final int accepted;
  final int rejected;
  final List<String> rejectionReasons;

  const IngestResult({
    required this.accepted,
    required this.rejected,
    this.rejectionReasons = const [],
  });
}

/// Error de sincronización (red, timeout o respuesta no-2xx de la API).
class SyncException implements Exception {
  final String message;
  const SyncException(this.message);
  @override
  String toString() => 'SyncException: $message';
}

/// Cliente HTTP de la sincronización. Solo conoce el transporte: recibe items ya
/// aplanados por [MeasurementMapper] y los sube al endpoint de mediciones.
class SyncApiClient {
  final http.Client _http;
  final Duration timeout;

  SyncApiClient({
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
  }) : _http = httpClient ?? http.Client();

  /// Sube el lote al paciente autenticado. Lanza [SyncException] si la API no
  /// responde 2xx (el llamador NO marca esos registros como sincronizados).
  Future<IngestResult> postMeasurements(List<IngestItem> items) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/me/measurements');
    final body = jsonEncode({
      'measurements': items.map((e) => e.toJson()).toList(),
    });

    final http.Response resp;
    try {
      resp = await _http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              // El token de sesión que el servidor emitió al canjear el código.
              ...PatientSession.instance.authHeaders,
            },
            body: body,
          )
          .timeout(timeout);
    } catch (e) {
      throw SyncException('No se pudo conectar con la API: $e');
    }

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw SyncException('La API respondió ${resp.statusCode}: ${resp.body}');
    }

    return _parse(resp.body);
  }

  IngestResult _parse(String responseBody) {
    if (responseBody.isEmpty) {
      return const IngestResult(accepted: 0, rejected: 0);
    }
    final map = jsonDecode(responseBody) as Map<String, dynamic>;
    final rejections = (map['rejections'] as List<dynamic>? ?? [])
        .map(
          (r) =>
              (r as Map<String, dynamic>)['reason']?.toString() ??
              'desconocido',
        )
        .toList();
    return IngestResult(
      accepted: (map['accepted'] as num?)?.toInt() ?? 0,
      rejected: (map['rejected'] as num?)?.toInt() ?? 0,
      rejectionReasons: rejections,
    );
  }

  void close() => _http.close();
}
