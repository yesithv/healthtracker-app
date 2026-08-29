import 'dart:convert';

import 'package:myvitals_healthtracker_app/core/diagnostics/debug_log.dart';

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

/// Sesión recién abierta al canjear el código que el staff dictó por teléfono.
///
/// Trae la ficha ya resuelta ([account]) para que la app entre sabiendo a quién ha dejado
/// entrar, sin una segunda vuelta contra el servidor.
class RedeemedSession {
  /// Token opaco de sesión. Se manda luego en `Authorization: Bearer`.
  final String token;

  /// Cuándo caduca en el servidor.
  final DateTime? expiresAt;

  final PatientAccount account;

  const RedeemedSession({
    required this.token,
    required this.account,
    this.expiresAt,
  });

  factory RedeemedSession.fromJson(Map<String, dynamic> json) =>
      RedeemedSession(
        token: json['sessionToken'] as String,
        expiresAt: json['expiresAt'] == null
            ? null
            : DateTime.tryParse(json['expiresAt'] as String),
        account: PatientAccount.fromJson(
          json['account'] as Map<String, dynamic>,
        ),
      );
}

/// Sesión abierta con el código que llegó al correo.
///
/// [needsSignup] distingue las dos salidas de la puerta: quien ya tiene ficha entra, y quien
/// acaba de verificar su correo todavía tiene que completar el alta. Esa sesión no da acceso a
/// datos: todo `/me/**` resuelve al paciente por su ficha, y aún no hay ninguna.
class AccessSession {
  final String token;
  final DateTime? expiresAt;
  final bool needsSignup;
  final PatientAccount? account;

  const AccessSession({
    required this.token,
    required this.needsSignup,
    this.expiresAt,
    this.account,
  });

  factory AccessSession.fromJson(Map<String, dynamic> json) => AccessSession(
    token: json['sessionToken'] as String,
    expiresAt: json['expiresAt'] == null
        ? null
        : DateTime.tryParse(json['expiresAt'] as String),
    needsSignup: json['next'] == 'SIGNUP',
    account: json['account'] == null
        ? null
        : PatientAccount.fromJson(json['account'] as Map<String, dynamic>),
  );
}

/// El documento del alta ya existe: hay que llamar a la clínica.
///
/// Es una excepción aparte para que la pantalla pueda llevar a quien la recibe al sitio
/// correcto sin leer el mensaje.
class CallClinicException extends AuthException {
  const CallClinicException(super.message);
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

  /// Primer paso de la puerta: pide el código para ese correo.
  ///
  /// La API responde SIEMPRE lo mismo, exista o no la cuenta: quien escribe una dirección no
  /// puede averiguar si pertenece a un paciente de la clínica. Lo que cambia es el correo que
  /// llega al buzón, y eso la app no lo ve ni tiene por qué.
  Future<void> startAccess(String email) async {
    await _postRaw('/api/v1/access/start', {'email': email.trim()});
  }

  /// Segundo paso: el código que llegó al correo. Abre sesión.
  ///
  /// [AccessSession.needsSignup] dice si esa cuenta todavía no tiene ficha; en ese caso la
  /// sesión solo sirve para completar el alta.
  Future<AccessSession> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    final map = await _postRaw('/api/v1/access/verify', {
      'email': email.trim(),
      'code': code,
    });
    return AccessSession.fromJson(map);
  }

  /// Tercer paso: el alta. Necesita el token que devolvió [verifyEmailCode].
  ///
  /// Lanza [CallClinicException] si el documento ya existe —en la clínica o en otra cuenta—:
  /// esa persona tiene que pasar por un agente, porque su historia clínica no se entrega por
  /// teclear un número.
  Future<PatientAccount> signup({
    required String sessionToken,
    required String firstName,
    String? lastName,
    DateTime? birthDate,
    String? sex,
    String? phone,
    String? country,
    String? documentType,
    required String documentNumber,
    required bool termsAccepted,
  }) async {
    final body = {
      'firstName': firstName,
      'lastName': ?lastName,
      'birthDate': ?(birthDate == null ? null : _dateOnly(birthDate)),
      'sex': ?sex,
      'phone': ?phone,
      'country': ?country,
      'documentType': ?documentType,
      'documentNumber': documentNumber,
      'termsAccepted': termsAccepted,
    };
    final map = await _postRaw(
      '/api/v1/access/signup',
      body,
      authorization: 'Bearer $sessionToken',
    );
    return PatientAccount.fromJson(map);
  }

  Future<Map<String, dynamic>> _postRaw(
    String path,
    Map<String, dynamic> body, {
    Duration? timeoutOverride,
    String? authorization,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final http.Response resp;
    try {
      resp = await _http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': ?authorization,
            },
            body: jsonEncode(body),
          )
          .timeout(timeoutOverride ?? timeout);
    } catch (e) {
      throw AuthNetworkException('No se pudo conectar con el servidor: $e');
    }
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      // 202 sin cuerpo (la puerta) es una respuesta válida y no hay nada que leer.
      if (resp.body.isEmpty) return const {};
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    // 5xx = el servidor está caído o falló por su cuenta: reintentable.
    if (resp.statusCode >= 500) throw AuthNetworkException(_messageFrom(resp));
    // El alta responde 409 con una marca cuando el documento ya existe. Se distingue por la
    // marca y no por el texto: comparar frases traducibles se rompe al mejorar una de ellas.
    if (resp.statusCode == 409 && _reasonOf(resp) == 'CALL_CLINIC') {
      throw CallClinicException(_messageFrom(resp));
    }
    throw AuthException(_messageFrom(resp));
  }

  /// Canjea el código de seis dígitos que un agente de la clínica le dictó al paciente
  /// por teléfono, después de verificar su identidad en esa llamada.
  ///
  /// Exige el documento ADEMÁS del código, y no es un trámite: acota el intento a una sola
  /// cuenta. Si bastara el código, probar seis dígitos al azar acertaría el de alguien.
  ///
  /// El servidor responde lo mismo para «no hay código», «caducó», «ya se usó» y «no es
  /// ese documento», así que la app no puede —ni debe— decir cuál de los cuatro fue.
  ///
  /// Timeout largo: el canje trae de paso el historial del legacy.
  Future<RedeemedSession> redeemAccessCode({
    required String documentNumber,
    required String code,
  }) async {
    final map = await _postRaw('/api/v1/auth/otp/redeem', {
      'documentNumber': documentNumber,
      'code': code,
    }, timeoutOverride: const Duration(seconds: 90));
    return RedeemedSession.fromJson(map);
  }

  /// La marca de la respuesta de error (`reason`), si la trae.
  String? _reasonOf(http.Response resp) {
    try {
      final map = jsonDecode(resp.body) as Map<String, dynamic>;
      return map['reason'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Extrae el `detail` del ProblemDetail (RFC 7807) que devuelve la API, con un fallback.
  String _messageFrom(http.Response resp) {
    try {
      final map = jsonDecode(resp.body) as Map<String, dynamic>;
      final detail = map['detail'] ?? map['title'];
      if (detail is String && detail.isNotEmpty) return detail;
    } catch (e) {
      debugLogError('Auth.parseProblemDetail', e);
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
