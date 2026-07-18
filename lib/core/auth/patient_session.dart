import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sesión del paciente: su identidad pública (`public_id`) y datos básicos tras
/// registrarse o iniciar sesión. El `publicId` es lo que se envía a la API como
/// `X-Patient-Public-Id` para sincronizar y leer datos (andamio de Fase 0; en
/// Fase 1 lo reemplaza el token del IdP).
///
/// Singleton (como los repositorios) para que el código de red no-widget pueda
/// leer el `publicId` sin depender del árbol de widgets; a la vez es
/// [ChangeNotifier] para que la UI reaccione al login/logout.
class PatientSession extends ChangeNotifier {
  PatientSession._();
  static final PatientSession instance = PatientSession._();

  static const _kPublicId = 'session_patient_public_id';
  static const _kFirstName = 'session_patient_first_name';
  static const _kLastName = 'session_patient_last_name';
  static const _kSource = 'session_patient_source';

  String? _publicId;
  String? _firstName;
  String? _lastName;
  String? _source;

  String? get publicId => _publicId;
  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String? get source => _source;

  bool get isAuthenticated => _publicId != null && _publicId!.isNotEmpty;
  bool get isMigrated => _source == 'LEGACY';

  /// Carga la sesión persistida (llamar al arrancar la app).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _publicId = prefs.getString(_kPublicId);
    _firstName = prefs.getString(_kFirstName);
    _lastName = prefs.getString(_kLastName);
    _source = prefs.getString(_kSource);
    notifyListeners();
  }

  /// Guarda la identidad devuelta por register/login.
  Future<void> save({
    required String publicId,
    String? firstName,
    String? lastName,
    String? source,
  }) async {
    _publicId = publicId;
    _firstName = firstName;
    _lastName = lastName;
    _source = source;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPublicId, publicId);
    await _setOrRemove(prefs, _kFirstName, firstName);
    await _setOrRemove(prefs, _kLastName, lastName);
    await _setOrRemove(prefs, _kSource, source);
  }

  /// Cierra la sesión (borra la identidad; NO borra los registros locales).
  Future<void> clear() async {
    _publicId = null;
    _firstName = null;
    _lastName = null;
    _source = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPublicId);
    await prefs.remove(_kFirstName);
    await prefs.remove(_kLastName);
    await prefs.remove(_kSource);
  }

  Future<void> _setOrRemove(SharedPreferences prefs, String key, String? value) async {
    if (value == null || value.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
  }
}
