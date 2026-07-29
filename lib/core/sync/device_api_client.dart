import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/config/api_config.dart';
import 'package:myvitals_healthtracker_app/core/sync/sync_api_client.dart'
    show SyncException;

/// Un dispositivo de medición (bioimpedancia/báscula) del catálogo que administra el
/// BackOffice. La app lo usa para el selector "¿qué báscula usas?".
class MeasuringDevice {
  final String code;
  final String brand;
  final String model;
  final String name;
  final String deviceType;

  const MeasuringDevice({
    required this.code,
    required this.brand,
    required this.model,
    required this.name,
    required this.deviceType,
  });

  factory MeasuringDevice.fromJson(Map<String, dynamic> json) =>
      MeasuringDevice(
        code: json['code'] as String,
        brand: json['brand'] as String? ?? '',
        model: json['model'] as String? ?? '',
        name: json['name'] as String? ?? json['code'] as String,
        deviceType: json['deviceType'] as String? ?? 'BIOIMPEDANCE',
      );
}

/// Cliente HTTP del catálogo de dispositivos y de la báscula del paciente.
///   GET /api/v1/measuring-devices     -> catálogo (público)
///   GET /api/v1/me/device             -> mi báscula (device o null)
///   PUT /api/v1/me/device             -> fija/limpia mi báscula
class DeviceApiClient {
  final http.Client _http;
  final Duration timeout;

  DeviceApiClient({
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
  }) : _http = httpClient ?? http.Client();

  Map<String, String> get _patientHeaders => {
    'X-Patient-Public-Id':
        PatientSession.instance.publicId ?? ApiConfig.patientPublicId,
  };

  /// Catálogo de dispositivos activos (recurso público).
  Future<List<MeasuringDevice>> fetchCatalog() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/measuring-devices');
    final http.Response resp;
    try {
      resp = await _http.get(uri).timeout(timeout);
    } catch (e) {
      throw SyncException('No se pudo conectar con la API: $e');
    }
    _ensure2xx(resp);
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list
        .map((e) => MeasuringDevice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Código de la báscula del paciente, o `null` si no usa ninguna.
  Future<String?> fetchMyDeviceCode() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/me/device');
    final http.Response resp;
    try {
      resp = await _http.get(uri, headers: _patientHeaders).timeout(timeout);
    } catch (e) {
      throw SyncException('No se pudo conectar con la API: $e');
    }
    _ensure2xx(resp);
    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    final device = map['device'] as Map<String, dynamic>?;
    return device?['code'] as String?;
  }

  /// Fija (o limpia con `null`) la báscula del paciente.
  Future<void> setMyDeviceCode(String? code) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/me/device');
    final http.Response resp;
    try {
      resp = await _http
          .put(
            uri,
            headers: {..._patientHeaders, 'Content-Type': 'application/json'},
            body: jsonEncode({'deviceCode': code}),
          )
          .timeout(timeout);
    } catch (e) {
      throw SyncException('No se pudo conectar con la API: $e');
    }
    _ensure2xx(resp);
  }

  void _ensure2xx(http.Response resp) {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw SyncException('La API respondió ${resp.statusCode}: ${resp.body}');
    }
  }

  void close() => _http.close();
}
