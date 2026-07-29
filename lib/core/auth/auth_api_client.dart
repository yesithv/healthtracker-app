import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:myvitals_healthtracker_app/core/config/api_config.dart';
import 'package:myvitals_healthtracker_app/core/utils/text_format.dart';

/// Identidad + perfil básico del paciente devuelto por register/login. Los nombres se
/// normalizan a Title Case aquí (el legacy los guarda EN MAYÚSCULAS) para que toda la
/// app los vea ya presentables.
class PatientAccount {
  final String publicId;
  final String? firstName;
  final String? lastName;
  final DateTime? birthDate;

  /// Formato del servidor: F | M | OTHER | UNKNOWN.
  final String? sex;
  final String? email;
  final String? source;
  final bool migrated;

  const PatientAccount({
    required this.publicId,
    this.firstName,
    this.lastName,
    this.birthDate,
    this.sex,
    this.email,
    this.source,
    this.migrated = false,
  });

  factory PatientAccount.fromJson(Map<String, dynamic> json) => PatientAccount(
    publicId: json['publicId'] as String,
    firstName: _titleOrNull(json['firstName'] as String?),
    lastName: _titleOrNull(json['lastName'] as String?),
    birthDate: json['birthDate'] == null
        ? null
        : DateTime.tryParse(json['birthDate'] as String),
    sex: json['sex'] as String?,
    email: json['email'] as String?,
    source: json['source'] as String?,
    migrated: json['migrated'] as bool? ?? false,
  );

  /// El sexo del servidor traducido al formato del perfil de la app
  /// ('male'/'female'; '' = desconocido, no se hidrata).
  String get genderForApp => switch (sex) {
    'F' => 'female',
    'M' => 'male',
    _ => '',
  };

  static String? _titleOrNull(String? v) {
    final t = toTitleCase(v);
    return t.isEmpty ? null : t;
  }
}

/// Resultado del lookup de identificación (solo booleanos; sin PII antes de verificar).
class LookupResult {
  final bool exists;
  final bool inLegacy;
  const LookupResult({required this.exists, required this.inLegacy});
}

/// Error de autenticación con un mensaje presentable al usuario.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

/// Fallo de TRANSPORTE, no de datos: sin conexión, timeout, o el servidor caído
/// (5xx). Reintentarlo más tarde puede funcionar sin que el usuario cambie nada.
///
/// Extiende [AuthException] a propósito, para que todo el código que ya hacía
/// `on AuthException` siga capturándolo igual. Quien necesite decidir entre
/// «reintenta luego» y «corrige el dato» captura primero este tipo.
class AuthNetworkException extends AuthException {
  const AuthNetworkException(super.message);
}

/// Cliente de los endpoints públicos de cuenta (`/api/v1/auth/*`).
class AuthApiClient {
  final http.Client _http;
  final Duration timeout;

  AuthApiClient({
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
  }) : _http = httpClient ?? http.Client();

  /// Registra un paciente nuevo (source=APP). [sex] en formato de la app ('male'/'female').
  /// [country] es ISO 3166-1 alpha-2 ('CO', 'MX'...); el backend lo valida contra su
  /// catálogo y lo descarta si no lo reconoce (nunca falla el registro por esto).
  Future<PatientAccount> register({
    required String firstName,
    String? lastName,
    DateTime? birthDate,
    String? sex,
    required String email,
    String? phone,
    String? city,
    String? country,
    String? documentType,
    String? documentNumber,
  }) async {
    final body = {
      'firstName': firstName,
      'lastName': ?lastName,
      if (birthDate != null) 'birthDate': _dateOnly(birthDate),
      'sex': ?sex,
      'email': email,
      'phone': ?phone,
      'city': ?city,
      'country': ?country,
      'documentType': ?documentType,
      'documentNumber': ?documentNumber,
    };
    return _post('/api/v1/auth/register', body);
  }

  /// Resultado del lookup: [exists] = ya hay cuenta (→ verificar); [inLegacy] = no hay
  /// cuenta pero SÍ historial en el legacy (→ ofrecer alta self-service).
  Future<LookupResult> lookup(String identifier) async {
    final map = await _postRaw('/api/v1/auth/lookup', {
      'identifier': identifier,
    });
    return LookupResult(
      exists: map['exists'] as bool? ?? false,
      inLegacy: map['inLegacy'] as bool? ?? false,
    );
  }

  /// Alta self-service: trae el historial del legacy (persona + atenciones + indicadores)
  /// y deja la cuenta lista para verificar. Timeout largo: incluye el backfill completo.
  Future<void> activate(String identifier) async {
    await _postRaw('/api/v1/auth/activate', {
      'identifier': identifier,
    }, timeoutOverride: const Duration(seconds: 90));
  }

  Future<Map<String, dynamic>> _postRaw(
    String path,
    Map<String, dynamic> body, {
    Duration? timeoutOverride,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final http.Response resp;
    try {
      resp = await _http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeoutOverride ?? timeout);
    } catch (e) {
      throw AuthNetworkException('No se pudo conectar con el servidor: $e');
    }
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    // 5xx = el servidor está caído o falló por su cuenta: reintentable.
    if (resp.statusCode >= 500) throw AuthNetworkException(_messageFrom(resp));
    throw AuthException(_messageFrom(resp));
  }

  /// Inicia sesión por documento (migrado) o email (APP) + contraseña.
  Future<PatientAccount> login({
    required String identifier,
    required String password,
  }) {
    return _post('/api/v1/auth/login', {
      'identifier': identifier,
      'password': password,
    });
  }

  Future<PatientAccount> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final http.Response resp;
    try {
      resp = await _http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } catch (e) {
      throw AuthNetworkException('No se pudo conectar con el servidor: $e');
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return PatientAccount.fromJson(
        jsonDecode(resp.body) as Map<String, dynamic>,
      );
    }
    if (resp.statusCode >= 500) throw AuthNetworkException(_messageFrom(resp));
    throw AuthException(_messageFrom(resp));
  }

  /// Extrae el `detail` del ProblemDetail (RFC 7807) que devuelve la API, con un fallback.
  String _messageFrom(http.Response resp) {
    try {
      final map = jsonDecode(resp.body) as Map<String, dynamic>;
      final detail = map['detail'] ?? map['title'];
      if (detail is String && detail.isNotEmpty) return detail;
    } catch (_) {
      // cuerpo no-JSON; se usa el fallback
    }
    if (resp.statusCode == 401) return 'Credenciales inválidas.';
    if (resp.statusCode == 409) return 'La cuenta ya existe.';
    return 'Error del servidor (${resp.statusCode}).';
  }

  /// yyyy-MM-dd (LocalDate del backend).
  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void close() => _http.close();
}
