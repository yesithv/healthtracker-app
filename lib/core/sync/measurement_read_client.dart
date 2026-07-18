import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/config/api_config.dart';
import 'package:myvitals_healthtracker_app/core/sync/sync_api_client.dart' show SyncException;

/// Un punto de la serie del paciente tal como lo devuelve la API (GET /me/measurements).
/// Incluye [source] para distinguir lo importado del legacy ('LEGACY') de lo propio ('APP').
class ServerMeasurement {
  final String indicatorCode;
  final String indicatorName;
  final String? unit;
  final DateTime measuredAt;
  final num? value;
  final String source;
  final String? note;

  const ServerMeasurement({
    required this.indicatorCode,
    required this.indicatorName,
    this.unit,
    required this.measuredAt,
    this.value,
    required this.source,
    this.note,
  });

  factory ServerMeasurement.fromJson(Map<String, dynamic> json) => ServerMeasurement(
        indicatorCode: json['indicatorCode'] as String,
        indicatorName: json['indicatorName'] as String? ?? json['indicatorCode'] as String,
        unit: json['unit'] as String?,
        measuredAt: DateTime.parse(json['measuredAt'] as String).toLocal(),
        value: json['value'] as num?,
        source: json['source'] as String? ?? 'APP',
        note: json['note'] as String?,
      );

  bool get isFromLegacy => source == 'LEGACY';
}

/// Lee del servidor la serie del paciente autenticado (su historia, incluida la
/// que se trajo del legacy en la migración).
class MeasurementReadClient {
  final http.Client _http;
  final Duration timeout;

  MeasurementReadClient({http.Client? httpClient, this.timeout = const Duration(seconds: 20)})
      : _http = httpClient ?? http.Client();

  Future<List<ServerMeasurement>> fetchMine() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/me/measurements');
    final http.Response resp;
    try {
      resp = await _http.get(uri, headers: {
        'X-Patient-Public-Id': PatientSession.instance.publicId ?? ApiConfig.patientPublicId,
      }).timeout(timeout);
    } catch (e) {
      throw SyncException('No se pudo conectar con la API: $e');
    }

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw SyncException('La API respondió ${resp.statusCode}: ${resp.body}');
    }

    final list = jsonDecode(resp.body) as List<dynamic>;
    return list
        .map((e) => ServerMeasurement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void close() => _http.close();
}
