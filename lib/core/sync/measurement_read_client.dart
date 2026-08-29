import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:myvitals_healthtracker_app/core/diagnostics/debug_log.dart';
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/config/api_config.dart';
import 'package:myvitals_healthtracker_app/core/sync/sync_api_client.dart'
    show SyncException;

/// Un punto de la serie del paciente tal como lo devuelve la API (GET /me/measurements).
/// Incluye [source] para distinguir lo importado del legacy ('LEGACY') de lo propio ('APP').
///
/// [context] es lo que evita que la vuelta pierda cosas: el laboratorio de un perfil
/// lipídico, la báscula de una bioimpedancia, el estado de actividad de una toma de
/// tensión y el `clientId` con el que el registro nació en este teléfono. Viene vacío
/// en lo migrado del legacy, que nunca tuvo esos metadatos.
class ServerMeasurement {
  final String indicatorCode;
  final String indicatorName;
  final String? unit;
  final DateTime measuredAt;
  final num? value;
  final String source;
  final String? note;
  final Map<String, dynamic> context;

  const ServerMeasurement({
    required this.indicatorCode,
    required this.indicatorName,
    this.unit,
    required this.measuredAt,
    this.value,
    required this.source,
    this.note,
    this.context = const {},
  });

  factory ServerMeasurement.fromJson(Map<String, dynamic> json) =>
      ServerMeasurement(
        indicatorCode: json['indicatorCode'] as String,
        indicatorName:
            json['indicatorName'] as String? ?? json['indicatorCode'] as String,
        unit: json['unit'] as String?,
        measuredAt: DateTime.parse(json['measuredAt'] as String).toLocal(),
        value: json['value'] as num?,
        source: json['source'] as String? ?? 'APP',
        note: json['note'] as String?,
        context: _decodeContext(json['context']),
      );

  bool get isFromLegacy => source == 'LEGACY';

  /// El id que este registro tuvo en el teléfono, si lo tuvo. Devolverlo al importar
  /// hace que reinstalar la app recupere los registros con su identidad, en vez de
  /// crear otros nuevos que solo se parecen.
  String? get clientId {
    final value = context['clientId'];
    return value is String && value.isNotEmpty ? value : null;
  }

  /// El contexto viaja como el JSONB crudo de la columna. Un servidor viejo no lo manda
  /// y una fila del legacy lo tiene a null: en los dos casos, sin contexto.
  static Map<String, dynamic> _decodeContext(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is! String || raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (e) {
      debugLogError('ServerMeasurement.context', e);
      return const {};
    }
  }
}

/// Lee del servidor la serie del paciente autenticado (su historia, incluida la
/// que se trajo del legacy en la migración).
class MeasurementReadClient {
  final http.Client _http;
  final Duration timeout;

  MeasurementReadClient({
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
  }) : _http = httpClient ?? http.Client();

  Future<List<ServerMeasurement>> fetchMine() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/me/measurements');
    final http.Response resp;
    try {
      resp = await _http
          .get(uri, headers: PatientSession.instance.authHeaders)
          .timeout(timeout);
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
