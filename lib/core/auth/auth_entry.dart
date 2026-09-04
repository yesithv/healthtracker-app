import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:myvitals_healthtracker_app/core/auth/auth_api_client.dart';
import 'package:myvitals_healthtracker_app/core/auth/local_data_reset.dart';
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/constants/measurement_unit.dart';
import 'package:myvitals_healthtracker_app/core/providers/locale_units_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/measuring_device_provider.dart';
import 'package:myvitals_healthtracker_app/core/profile/profile_sync_service.dart';
import 'package:myvitals_healthtracker_app/core/providers/onboarding_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';

/// Aplica una sesión recién abierta y entra al dashboard: guarda el token, hidrata el
/// perfil local con lo que el servidor sabe, aplica los defaults del paciente migrado
/// (español, métrico, báscula Omron) y marca el onboarding como completo antes de navegar.
///
/// [sessionToken] es lo único que autentica de aquí en adelante. Se pasa aparte de
/// [account] porque son cosas distintas: la cuenta dice QUIÉN es, el token dice que puede
/// pedir sus datos.
///
/// Lee los providers y el router del [context] ANTES de cualquier await para no usar el
/// BuildContext tras un gap asíncrono.
Future<void> completeLoginAndEnter(
  BuildContext context,
  PatientAccount account, {
  required String sessionToken,
  DateTime? sessionExpiresAt,
  String? identifier,
}) async {
  final profile = context.read<UserProfileProvider>();
  final onboarding = context.read<OnboardingProvider>();
  final localeUnits = context.read<LocaleUnitsProvider>();
  final profileSync = context.read<ProfileSyncService>();
  final devices = context.read<MeasuringDeviceProvider>();
  final router = GoRouter.of(context);

  // Aislamiento entre pacientes: si en el dispositivo quedaron datos de OTRO
  // paciente (p. ej. no se cerró sesión antes), se borran ANTES de guardar la
  // sesión — así el auto-sync (que se agenda al autenticar) no sube datos ajenos
  // a esta cuenta ni el usuario ve el historial del anterior.
  final owner = await currentDataOwner();
  if (owner != null && owner != account.publicId) {
    if (context.mounted) await wipeLocalUserData(context);
  }

  await PatientSession.instance.save(
    publicId: account.publicId,
    token: sessionToken,
    expiresAt: sessionExpiresAt,
    firstName: account.firstName,
    lastName: account.lastName,
    source: account.source,
  );

  // Hidrata el perfil local con lo que el servidor ya sabe (solo campos vacíos).
  final fullName = [
    account.firstName,
    account.lastName,
  ].where((s) => s != null && s.trim().isNotEmpty).join(' ');
  await profile.hydrateIdentity(
    name: fullName,
    email:
        account.email ??
        (identifier != null && identifier.contains('@') ? identifier : null),
    birthDate: account.birthDate,
    gender: account.genderForApp,
  );

  // Defaults del paciente migrado del legacy: español, sistema métrico y báscula Omron
  // (la de la consulta). Solo si el usuario no eligió antes.
  if (account.migrated) {
    await localeUnits.ensureDefaults(
      languageCode: 'es',
      unit: MeasurementUnit.metric,
    );
    await profile.setDefaultDeviceIfUnset('Omron');
  }

  // Y lo que la ficha del login no trae: teléfono, país, nivel de actividad,
  // metas, idioma y unidades. Se espera aquí —no se deja en segundo plano— para
  // que quien reinstala la app entre con su perfil completo y no lo vea aparecer
  // a trozos. Si falla, no rompe la entrada: se reintenta al arrancar.
  final serverProfile = await profileSync.hydrateFromServer();

  await onboarding.setComplete();
  await setDataOwner(account.publicId);

  // ── Las dos puertas de la entrada ──────────────────────────────────────────
  // Este es el ÚNICO sitio por el que se entra a la app, así que es el único
  // sitio donde hay que mirarlas. Van en este orden: primero lo legal, después
  // lo de producto.

  // 2ª — Qué báscula usa. Los rangos de grasa, músculo y grasa visceral viven en
  // la base **por dispositivo** (una Omron y una Tanita no miden igual a la misma
  // persona), así que quien no lo dice no recibe ninguno de los tres: solo el
  // IMC, que es universal. `shouldPrompt` existía desde el principio, documentado
  // como «debe preguntarse en el onboarding», y **no lo leía ninguna pantalla**:
  // la báscula solo se podía elegir entrando a mano en Perfil, cosa que nadie
  // recién registrado hace. Medido en el banco: 42 pacientes de 42 sin elegir, y
  // una tabla de 51 rangos por dispositivo que no le llegaba a nadie.
  await devices.load();
  final trasLoLegal = devices.shouldPrompt ? '/bienvenida/bascula' : '/dashboard';

  // 1ª — Los términos. Los pacientes migrados llegaban sin haber aceptado nada:
  // habían aceptado los de la clínica de nutrición, que es otra empresa. Y cuando
  // el texto cambia, lo que firmaron ya no es lo que rige.
  //
  // Si el perfil no se pudo leer —sin red, servidor caído— se entra igual: dejar
  // a alguien fuera de sus propios datos por un problema nuestro sería peor que
  // pedirle la aceptación en el siguiente arranque.
  //
  // La pantalla legal recibe a dónde seguir, para que aceptar los términos no se
  // salte la báscula.
  if (serverProfile?.termsPending == true) {
    router.go('/terminos', extra: trasLoLegal);
    return;
  }
  router.go(trasLoLegal);
}
