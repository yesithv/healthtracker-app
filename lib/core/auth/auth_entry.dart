import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:myvitals_healthtracker_app/core/auth/auth_api_client.dart';
import 'package:myvitals_healthtracker_app/core/auth/local_data_reset.dart';
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/constants/measurement_unit.dart';
import 'package:myvitals_healthtracker_app/core/providers/locale_units_provider.dart';
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

  await onboarding.setComplete();
  await setDataOwner(account.publicId);

  router.go('/dashboard');
}
