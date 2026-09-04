import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sesión del paciente: el token con el que habla con la API, su identidad pública
/// (`public_id`) y sus datos básicos.
///
/// El token lo emite el servidor al canjear el código que el staff le dictó por teléfono.
/// Es opaco —no lleva nada dentro que la app pueda leer— y es lo único que autentica: se
/// manda en `Authorization: Bearer`. El `publicId` ya NO autentica nada; queda porque es
/// como se sabe de quién son los datos guardados en el dispositivo.
///
/// El token vive en `SharedPreferences`, que en Android/iOS es almacenamiento privado de
/// la app pero no cifrado: quien tenga el dispositivo desbloqueado y root puede leerlo.
/// Es el mismo nivel de exposición que tendría una cookie de sesión, y por eso el servidor
/// puede revocarla en el acto.
///
/// Singleton (como los repositorios) para que el código de red no-widget pueda
/// leer el token sin depender del árbol de widgets; a la vez es
/// [ChangeNotifier] para que la UI reaccione al login/logout.
class PatientSession extends ChangeNotifier {
  PatientSession._();
  static final PatientSession instance = PatientSession._();

  static const _kToken = 'session_token';
  static const _kExpiresAt = 'session_expires_at';
  static const _kPublicId = 'session_patient_public_id';
  static const _kFirstName = 'session_patient_first_name';
  static const _kLastName = 'session_patient_last_name';
  static const _kSource = 'session_patient_source';

  String? _token;
  DateTime? _expiresAt;
  String? _publicId;
  String? _firstName;
  String? _lastName;
  String? _source;

  /// Token opaco de sesión. Nulo = no hay sesión.
  String? get token => _token;

  /// Cuándo caduca la sesión en el servidor (informativo: quien manda es el servidor).
  DateTime? get expiresAt => _expiresAt;

  String? get publicId => _publicId;
  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String? get source => _source;

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  /// Cabeceras de autenticación para cualquier llamada a `/api/v1/me/**`. Vacías sin
  /// sesión: la API responderá 401, que es exactamente lo que debe pasar.
  Map<String, String> get authHeaders =>
      isAuthenticated ? {'Authorization': 'Bearer $_token'} : const {};

  bool get isMigrated => _source == 'LEGACY';

  /// Carga la sesión persistida (llamar al arrancar la app).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kToken);
    final expires = prefs.getString(_kExpiresAt);
    _expiresAt = expires == null ? null : DateTime.tryParse(expires);
    _publicId = prefs.getString(_kPublicId);
    _firstName = prefs.getString(_kFirstName);
    _lastName = prefs.getString(_kLastName);
    _source = prefs.getString(_kSource);
    notifyListeners();
  }

  /// Guarda la sesión y la identidad devueltas al canjear el código.
  Future<void> save({
    required String publicId,
    String? token,
    DateTime? expiresAt,
    String? firstName,
    String? lastName,
    String? source,
  }) async {
    // El token es opcional para no perder el que ya hay al refrescar solo el perfil.
    if (token != null && token.isNotEmpty) {
      _token = token;
      _expiresAt = expiresAt;
    }
    _publicId = publicId;
    _firstName = firstName;
    _lastName = lastName;
    _source = source;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await _setOrRemove(prefs, _kToken, _token);
    await _setOrRemove(prefs, _kExpiresAt, _expiresAt?.toIso8601String());
    await prefs.setString(_kPublicId, publicId);
    await _setOrRemove(prefs, _kFirstName, firstName);
    await _setOrRemove(prefs, _kLastName, lastName);
    await _setOrRemove(prefs, _kSource, source);
  }

  /// Cierra la sesión (borra la identidad; NO borra los registros locales).
  Future<void> clear() async {
    _token = null;
    _expiresAt = null;
    _publicId = null;
    _firstName = null;
    _lastName = null;
    _source = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kExpiresAt);
    await prefs.remove(_kPublicId);
    await prefs.remove(_kFirstName);
    await prefs.remove(_kLastName);
    await prefs.remove(_kSource);
  }

  Future<void> _setOrRemove(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    if (value == null || value.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
  }
}
