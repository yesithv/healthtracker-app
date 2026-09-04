import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/config/api_config.dart';
import 'package:myvitals_healthtracker_app/core/constants/measurement_unit.dart';
import 'package:myvitals_healthtracker_app/core/sync/sync_api_client.dart'
    show SyncException;
import 'package:myvitals_healthtracker_app/core/utils/text_format.dart';

/// El perfil del paciente tal y como lo guarda el servidor (`GET /api/v1/me`).
///
/// Es lo que hace que reinstalar la app no cueste el nombre, la fecha de
/// nacimiento, las metas ni el idioma: hasta ahora todo eso vivía solo en
/// `SharedPreferences` y volvía a cero con el móvil nuevo.
class ServerProfile {
  final String? email;

  /// El documento con solo las últimas cifras a la vista. Se muestra, no se edita:
  /// es la clave contra la que se contrasta el legacy.
  final String? documentMasked;
  final bool migrated;

  final String? firstName;
  final String? lastName;
  final DateTime? birthDate;

  /// Formato del servidor: F | M | OTHER | UNKNOWN.
  final String? sex;
  final String? phone;
  final String? countryCode;
  final String? activityLevel;

  final String? locale;
  final MeasurementUnit? unit;

  /// La versión de los términos que esta persona aceptó, o `null` si no aceptó
  /// ninguna. Los pacientes migrados llegan con `null`: aceptaron los de la
  /// clínica de nutrición, que es otra empresa.
  final String? termsVersion;

  /// La versión vigente, la que sirve el servidor hoy. Viene en el mismo `GET
  /// /me` para poder comparar sin una segunda llamada.
  final String? currentTermsVersion;

  /// Hasta cuándo llega la historia que la clínica trajo de su sistema, o `null` si esta
  /// persona no viene de allí.
  ///
  /// La app lo enseña: una historia clínica migrada tiene una fecha de corte, y si el
  /// sincronizador lleva días parado, callarlo es enseñar datos viejos como si fueran de hoy.
  final DateTime? clinicDataSyncedAt;

  /// Por qué canales acepta que se le contacte.
  final ServerConsents consents;

  /// `null` si el paciente nunca se puso metas, que no es lo mismo que metas vacías.
  final ServerGoals? goals;

  const ServerProfile({
    this.email,
    this.documentMasked,
    this.migrated = false,
    this.firstName,
    this.lastName,
    this.birthDate,
    this.sex,
    this.phone,
    this.countryCode,
    this.activityLevel,
    this.locale,
    this.unit,
    this.termsVersion,
    this.currentTermsVersion,
    this.clinicDataSyncedAt,
    this.consents = const ServerConsents(),
    this.goals,
  });

  factory ServerProfile.fromJson(Map<String, dynamic> json) {
    final identity = json['identity'] as Map<String, dynamic>? ?? const {};
    final personal = json['personal'] as Map<String, dynamic>? ?? const {};
    final preferences =
        json['preferences'] as Map<String, dynamic>? ?? const {};
    final goals = json['goals'] as Map<String, dynamic>?;

    return ServerProfile(
      email: identity['email'] as String?,
      documentMasked: identity['documentMasked'] as String?,
      migrated: identity['migrated'] as bool? ?? false,
      // El legacy guarda los nombres EN MAYÚSCULAS; se normalizan aquí para que
      // toda la app los vea ya presentables.
      firstName: _titleOrNull(personal['firstName'] as String?),
      lastName: _titleOrNull(personal['lastName'] as String?),
      birthDate: personal['birthDate'] == null
          ? null
          : DateTime.tryParse(personal['birthDate'] as String),
      sex: personal['sex'] as String?,
      phone: personal['phone'] as String?,
      countryCode: personal['countryCode'] as String?,
      activityLevel: personal['activityLevel'] as String?,
      locale: preferences['locale'] as String?,
      unit: _unitFromJson(preferences['unitSystem'] as String?),
      termsVersion: identity['termsVersion'] as String?,
      currentTermsVersion: identity['currentTermsVersion'] as String?,
      clinicDataSyncedAt: identity['clinicDataSyncedAt'] == null
          ? null
          : DateTime.tryParse(
              identity['clinicDataSyncedAt'] as String,
            )?.toLocal(),
      consents: ServerConsents.fromJson(
        json['consents'] as Map<String, dynamic>? ?? const {},
      ),
      goals: goals == null ? null : ServerGoals.fromJson(goals),
    );
  }

  /// Si hay que pedirle que acepte antes de dejarle entrar.
  ///
  /// Es `true` tanto para quien no aceptó nunca —el caso de los migrados— como
  /// para quien aceptó una versión anterior: los términos cambiaron y lo que
  /// firmó ya no es lo que rige.
  ///
  /// Un servidor que no diga cuál es la vigente no bloquea a nadie: sería
  /// dejar a la gente fuera de sus propios datos por un despliegue a medias.
  bool get termsPending =>
      currentTermsVersion != null && termsVersion != currentTermsVersion;

  /// Cuántos días lleva sin actualizarse la historia que vino de la clínica.
  ///
  /// `null` cuando esta persona no viene de allí y no hay nada que fechar.
  int? get clinicDataAgeDays => clinicDataSyncedAt == null
      ? null
      : DateTime.now().difference(clinicDataSyncedAt!).inDays;

  /// El nombre completo, o cadena vacía si el servidor no sabe ninguno.
  String get fullName => [
    firstName,
    lastName,
  ].where((s) => s != null && s.trim().isNotEmpty).join(' ');

  /// El sexo traducido al formato del perfil de la app ('male'/'female';
  /// '' = desconocido, y entonces no se hidrata nada).
  String get genderForApp => switch (sex) {
    'F' => 'female',
    'M' => 'male',
    _ => '',
  };

  static MeasurementUnit? _unitFromJson(String? value) => switch (value) {
    'METRIC' => MeasurementUnit.metric,
    'IMPERIAL' => MeasurementUnit.imperial,
    _ => null,
  };

  static String? _titleOrNull(String? v) {
    final t = toTitleCase(v);
    return t.isEmpty ? null : t;
  }
}

/// Por qué canales acepta el paciente que se le contacte.
///
/// Cada canal tiene **tres** estados y los tres significan algo distinto:
/// `true` concede, `false` **revoca** —que es de lo que va todo esto— y `null`
/// es «nunca lo ha dicho». Lo último no es un «no»: quien no respondió no ha
/// revocado nada, y la app tiene que poder preguntárselo en vez de dar por
/// hecha una respuesta que nadie dio.
class ServerConsents {
  final bool? phone;
  final bool? messages;
  final bool? email;

  const ServerConsents({this.phone, this.messages, this.email});

  factory ServerConsents.fromJson(Map<String, dynamic> json) => ServerConsents(
    phone: json['phone'] as bool?,
    messages: json['messages'] as bool?,
    email: json['email'] as bool?,
  );

  /// Solo los canales que hay algo que decir sobre ellos: mandar un `null` como
  /// `false` revocaría en silencio lo que la persona no ha tocado.
  Map<String, dynamic> toJson() => {
    if (phone != null) 'phone': phone,
    if (messages != null) 'messages': messages,
    if (email != null) 'email': email,
  };

  bool get isEmpty => phone == null && messages == null && email == null;
}

/// Las metas del paciente en el servidor. Se leen y se escriben enteras.
class ServerGoals {
  final bool enabled;
  final double? targetWeightKg;
  final double? targetBodyFatPct;
  final double? targetMusclePct;
  final int? targetVisceralLevel;

  const ServerGoals({
    required this.enabled,
    this.targetWeightKg,
    this.targetBodyFatPct,
    this.targetMusclePct,
    this.targetVisceralLevel,
  });

  factory ServerGoals.fromJson(Map<String, dynamic> json) => ServerGoals(
    enabled: json['enabled'] as bool? ?? false,
    targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
    targetBodyFatPct: (json['targetBodyFatPct'] as num?)?.toDouble(),
    targetMusclePct: (json['targetMusclePct'] as num?)?.toDouble(),
    targetVisceralLevel: (json['targetVisceralLevel'] as num?)?.toInt(),
  );

  /// Sin nada que decir no se manda el bloque: ver [ProfileApiClient.save].
  bool get isEmpty =>
      !enabled &&
      targetWeightKg == null &&
      targetBodyFatPct == null &&
      targetMusclePct == null &&
      targetVisceralLevel == null;

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    if (targetWeightKg != null) 'targetWeightKg': targetWeightKg,
    if (targetBodyFatPct != null) 'targetBodyFatPct': targetBodyFatPct,
    if (targetMusclePct != null) 'targetMusclePct': targetMusclePct,
    if (targetVisceralLevel != null) 'targetVisceralLevel': targetVisceralLevel,
  };
}

/// Lee y escribe el perfil del paciente autenticado contra `/api/v1/me`.
class ProfileApiClient {
  final http.Client _http;
  final Duration timeout;

  ProfileApiClient({
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
  }) : _http = httpClient ?? http.Client();

  Future<ServerProfile> fetchMine() async {
    final http.Response resp;
    try {
      resp = await _http
          .get(_uri, headers: PatientSession.instance.authHeaders)
          .timeout(timeout);
    } catch (e) {
      throw SyncException('No se pudo conectar con la API: $e');
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw SyncException('La API respondió ${resp.statusCode}: ${resp.body}');
    }
    return ServerProfile.fromJson(
      jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>,
    );
  }

  /// Guarda el perfil.
  ///
  /// **Solo viaja lo que tiene valor.** Un campo ausente significa «no lo toques»
  /// para el servidor, y esa es justo la garantía que hace falta aquí: un móvil
  /// recién instalado no conoce casi nada del paciente, y mandar sus huecos como
  /// vacíos borraría la ficha que vino del legacy.
  ///
  /// Las metas siguen la misma idea a otro nivel: se escriben enteras, así que el
  /// bloque solo se manda cuando hay algo que decir. Sin esa condición, tocar el
  /// teléfono desde un móvil sin metas cargadas borraría las del servidor.
  Future<ServerProfile> save({
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? sex,
    String? phone,
    String? countryCode,
    String? activityLevel,
    String? locale,
    MeasurementUnit? unit,
    ServerConsents? consents,
    ServerGoals? goals,
  }) async {
    final body = <String, dynamic>{
      if (_has(firstName)) 'firstName': firstName!.trim(),
      if (_has(lastName)) 'lastName': lastName!.trim(),
      if (birthDate != null) 'birthDate': _isoDate(birthDate),
      if (_has(sex)) 'sex': sex,
      if (_has(phone)) 'phone': phone!.trim(),
      if (_has(countryCode)) 'countryCode': countryCode,
      if (_has(activityLevel)) 'activityLevel': activityLevel,
      if (_has(locale)) 'locale': locale,
      if (unit != null) 'unitSystem': unit.name.toUpperCase(),
      if (consents != null && !consents.isEmpty) 'consents': consents.toJson(),
      if (goals != null && !goals.isEmpty) 'goals': goals.toJson(),
    };

    final http.Response resp;
    try {
      resp = await _http
          .put(
            _uri,
            headers: {
              ...PatientSession.instance.authHeaders,
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } catch (e) {
      throw SyncException('No se pudo conectar con la API: $e');
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw SyncException('La API respondió ${resp.statusCode}: ${resp.body}');
    }
    return ServerProfile.fromJson(
      jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>,
    );
  }

  void close() => _http.close();

  Uri get _uri => Uri.parse('${ApiConfig.baseUrl}/api/v1/me');

  static bool _has(String? value) => value != null && value.trim().isNotEmpty;

  /// Solo la fecha: la hora del `DateTime` local no significa nada aquí y una
  /// zona horaria a la izquierda de Greenwich la convertiría en el día anterior.
  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
