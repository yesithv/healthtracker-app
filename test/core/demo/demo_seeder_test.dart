import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/demo/demo_seeder.dart';
import 'package:myvitals_healthtracker_app/core/providers/health_goals_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/onboarding_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/reminders_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';

/// La siembra de la demo escribe las claves de `SharedPreferences` a mano,
/// porque cada provider guarda las suyas en constantes privadas. Es un acuerdo
/// tácito, y los acuerdos tácitos se rompen callando: bastaría renombrar
/// `user_name` para que la demo arrancara sin nombre y nadie se enterara hasta
/// ver la captura.
///
/// Así que aquí no se comprueban las claves —eso sería repetir el mismo mapa—
/// sino el EFECTO: se levantan los providers de verdad sobre lo sembrado y se
/// exige que cada uno encuentre lo suyo.
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(DemoSeeder.demoPreferences());

    // Fuera de la web, el perfil busca la foto en el directorio de documentos.
    // No hay plugin nativo en una prueba, así que se responde con un directorio
    // temporal: sin foto dentro, que es el caso que interesa comprobar aquí
    // (el resto de los campos del perfil).
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.createTempSync('demo_seeder').path,
    );
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
  });

  test('el perfil llega completo a la tarjeta del panel', () async {
    final profile = UserProfileProvider();
    await profile.ready;

    expect(profile.userName, DemoSeeder.demoName);
    expect(profile.userEmail, DemoSeeder.demoEmail);
    expect(profile.userPhone, DemoSeeder.demoPhone);
    expect(profile.userCountryCode, DemoSeeder.demoCountry);
    expect(profile.userGender, isNotEmpty);
    expect(profile.birthDate, isNotNull);
    expect(profile.defaultDeviceName, isNotEmpty);
    // El nivel de actividad tiene que ser una de las claves que la pantalla de
    // Información personal reconoce; un valor fuera de ese juego —como el antiguo
    // 'moderate'— se enseñaría como si no estuviera puesto.
    expect(
      profile.userActivityLevel,
      isIn(const [
        'sedentary',
        'lightly_active',
        'moderately_active',
        'very_active',
        'extra_active',
      ]),
    );
    // La demo NO se abre con el bloqueo biométrico puesto: pediría huella antes
    // de dejar ver el panel, justo a quien viene a tomar una captura.
    expect(profile.isBiometricEnabled, isFalse);
  });

  test('la puerta de acceso queda abierta', () async {
    // Sin sesión y sin el asistente completado, el arranque manda a la portada
    // en vez de al panel, y la demo no enseñaría nada.
    final onboarding = OnboardingProvider();
    await onboarding.ready;
    expect(onboarding.isComplete, isTrue);

    await PatientSession.instance.load();
    expect(PatientSession.instance.isAuthenticated, isTrue);
  });

  test('los objetivos de salud están activos y son mixtos', () async {
    final goals = HealthGoalsProvider();
    await Future<void>.delayed(Duration.zero);

    expect(goals.medicalGoalsEnabled, isTrue);
    expect(goals.targetWeight, isNotNull);
    expect(goals.targetBodyFat, isNotNull);
    expect(goals.targetMuscleMass, isNotNull);
    expect(goals.targetVisceralFat, isNotNull);
  });

  test('los recordatorios llegan con unos encendidos y otros apagados', () async {
    final reminders = RemindersProvider();
    await Future<void>.delayed(Duration.zero);

    expect(reminders.reminders, hasLength(4));
    expect(reminders.reminders.where((r) => r.isEnabled), isNotEmpty);
    expect(reminders.reminders.where((r) => !r.isEnabled), isNotEmpty);
  });

  test('la siembra NO impone idioma, unidades ni tema', () {
    // La demo se entra desde la portada, y tiene que verse con el idioma y el
    // tema que el visitante ya tenía: imponerlos la haría dejar de parecerse a
    // la app que se le está enseñando. Sólo el arranque guionizado de las
    // capturas puede pisarlos, y para eso están las banderas de compilación.
    final seed = DemoSeeder.demoPreferences();
    expect(seed.containsKey('user_language'), isFalse);
    expect(seed.containsKey('user_measurement_unit'), isFalse);
    expect(seed.containsKey('app_theme_id'), isFalse);
  });
}
