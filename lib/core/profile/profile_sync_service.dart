import 'dart:async';

import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/config/api_config.dart';
import 'package:myvitals_healthtracker_app/core/demo/demo_session.dart';
import 'package:myvitals_healthtracker_app/core/diagnostics/debug_log.dart';
import 'package:myvitals_healthtracker_app/core/profile/profile_api_client.dart';
import 'package:myvitals_healthtracker_app/core/providers/health_goals_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/locale_units_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';

/// Mantiene el perfil del teléfono y el del servidor diciendo lo mismo.
///
/// <h3>Quién manda</h3>
///
/// **El servidor manda al entrar**, porque un teléfono recién instalado no sabe
/// nada; **el teléfono manda al editar**, porque es donde la persona escribe. Por
/// eso la hidratación solo rellena huecos —nunca pisa lo que ya hay— y el envío
/// solo lleva lo que tiene valor.
///
/// <h3>Sin red no se pierde nada</h3>
///
/// El perfil ya está guardado en local antes de llegar aquí. Si el envío falla,
/// se reintenta en el siguiente cambio o en el siguiente arranque con sesión. Es
/// la misma política que la subida de mediciones: nada se marca como enviado
/// hasta que el servidor lo confirma.
class ProfileSyncService {
  final UserProfileProvider _profile;
  final LocaleUnitsProvider _localeUnits;
  final HealthGoalsProvider _goals;
  final ProfileApiClient _client;

  /// Espera tras un cambio antes de enviar, para que editar tres campos seguidos
  /// no sean tres peticiones.
  final Duration debounce;

  Timer? _timer;

  /// Silencia el envío mientras la propia hidratación escribe en los providers:
  /// sin esto, traer el perfil del servidor dispararía un envío de vuelta.
  bool _hydrating = false;

  /// El nombre completo que el servidor tiene ahora mismo, o `null` si aún no se
  /// ha leído. Ver [_nameToSend]: sin este dato el nombre NO se manda.
  String? _serverFullName;

  ProfileSyncService({
    required UserProfileProvider profile,
    required LocaleUnitsProvider localeUnits,
    required HealthGoalsProvider goals,
    ProfileApiClient? client,
    this.debounce = const Duration(seconds: 2),
  }) : _profile = profile,
       _localeUnits = localeUnits,
       _goals = goals,
       _client = client ?? ProfileApiClient() {
    _profile.addListener(_onChanged);
    _localeUnits.addListener(_onChanged);
    _goals.addListener(_onChanged);
    PatientSession.instance.addListener(_onSessionChanged);

    // Con la sesión ya restaurada al arrancar no habrá evento de login, así que
    // la primera lectura se programa aquí.
    if (_canTalkToServer) {
      unawaited(hydrateFromServer());
    }
  }

  /// Trae el perfil del servidor y rellena lo que el teléfono no sepa.
  ///
  /// No lanza: sin conexión, sin sesión o con el servidor caído el resultado es
  /// el mismo —no se hidrata nada— y la app sigue con lo que tenga en local.
  ///
  /// @return el perfil leído, o `null` si no se pudo leer.
  Future<ServerProfile?> hydrateFromServer() async {
    if (!_canTalkToServer) return null;

    final ServerProfile profile;
    try {
      profile = await _client.fetchMine();
    } catch (e) {
      debugLogError('ProfileSync.hydrate', e);
      return null;
    }

    _hydrating = true;
    try {
      await _profile.hydrateIdentity(
        name: profile.fullName,
        email: profile.email,
        birthDate: profile.birthDate,
        gender: profile.genderForApp,
        phone: profile.phone,
        countryCode: profile.countryCode,
        activityLevel: profile.activityLevel,
      );
      await _localeUnits.ensureDefaults(
        languageCode: profile.locale,
        unit: profile.unit,
      );
      // Se escribe SIEMPRE, también cuando llega null: si esta persona deja de venir del legacy
      // —o el servidor deja de saberlo— una fecha vieja guardada en el teléfono seguiría
      // afirmando que su historia está más al día de lo que está.
      await _profile.setClinicDataSyncedAt(profile.clinicDataSyncedAt);
      final goals = profile.goals;
      if (goals != null) {
        await _goals.hydrate(
          enabled: goals.enabled,
          weight: goals.targetWeightKg,
          bodyFat: goals.targetBodyFatPct,
          muscleMass: goals.targetMusclePct,
          visceralFat: goals.targetVisceralLevel,
        );
      }
    } finally {
      _hydrating = false;
    }

    _serverFullName = profile.fullName;
    return profile;
  }

  /// Envía el perfil actual. No lanza: un fallo deja el cambio guardado en local
  /// y pendiente para el siguiente intento.
  Future<void> pushNow() async {
    if (!_canTalkToServer) return;

    final name = _nameToSend();
    try {
      final saved = await _client.save(
        firstName: name?.$1,
        lastName: name?.$2,
        birthDate: _profile.birthDate,
        sex: _profile.userGender,
        phone: _profile.userPhone,
        countryCode: _profile.userCountryCode,
        // Solo si lo ha dicho: el servidor guarda NULL cuando no lo ha
        // declarado, y 'sedentary' es aquí el valor por defecto de una
        // pantalla, no una respuesta de la persona.
        activityLevel: _profile.activityLevelSet
            ? _profile.userActivityLevel
            : null,
        locale: _localeUnits.locale.languageCode,
        unit: _localeUnits.unit,
        goals: ServerGoals(
          enabled: _goals.medicalGoalsEnabled,
          targetWeightKg: _goals.targetWeight,
          targetBodyFatPct: _goals.targetBodyFat,
          targetMusclePct: _goals.targetMuscleMass,
          targetVisceralLevel: _goals.targetVisceralFat,
        ),
      );
      _serverFullName = saved.fullName;
    } catch (e) {
      debugLogError('ProfileSync.push', e);
    }
  }

  void dispose() {
    _timer?.cancel();
    _profile.removeListener(_onChanged);
    _localeUnits.removeListener(_onChanged);
    _goals.removeListener(_onChanged);
    PatientSession.instance.removeListener(_onSessionChanged);
    _client.close();
  }

  /// El nombre partido en nombre y apellidos, o `null` si no hay que mandarlo.
  ///
  /// **Solo viaja si la persona lo ha cambiado**, y la razón es concreta: la app
  /// guarda un único campo de nombre, así que al enviarlo hay que partirlo por el
  /// primer espacio. Para un paciente migrado —«María del Carmen» / «Gómez
  /// Pérez» en el legacy— esa partida no coincide con la del origen, y mandarla
  /// sin que nadie haya tocado nada reescribiría su ficha clínica sola.
  (String, String)? _nameToSend() {
    final current = _profile.userName.trim();
    if (current.isEmpty || _serverFullName == null) return null;
    if (current == _serverFullName!.trim()) return null;

    final space = current.indexOf(' ');
    if (space < 0) return (current, '');
    return (current.substring(0, space), current.substring(space + 1).trim());
  }

  void _onChanged() {
    if (_hydrating || !_canTalkToServer) return;
    _timer?.cancel();
    _timer = Timer(debounce, pushNow);
  }

  void _onSessionChanged() {
    if (PatientSession.instance.isAuthenticated) {
      unawaited(hydrateFromServer());
    } else {
      // Al cerrar sesión, lo que quedara agendado iría con el token de otro.
      _timer?.cancel();
      _serverFullName = null;
    }
  }

  /// La demo tiene sesión sembrada pero no tiene servidor detrás.
  bool get _canTalkToServer =>
      ApiConfig.isConfigured &&
      PatientSession.instance.isAuthenticated &&
      !DemoSession.instance.isActive;
}
