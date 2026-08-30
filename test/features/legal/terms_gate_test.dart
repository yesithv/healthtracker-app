import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myvitals_healthtracker_app/core/auth/auth_api_client.dart';
import 'package:myvitals_healthtracker_app/core/auth/auth_entry.dart';
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/profile/profile_api_client.dart';
import 'package:myvitals_healthtracker_app/core/profile/profile_sync_service.dart';
import 'package:myvitals_healthtracker_app/core/providers/health_goals_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/locale_units_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/onboarding_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';

/// La puerta legal, recorrida por donde se entra de verdad.
///
/// **El hueco que cierra.** Un paciente **migrado** del legacy entraba al
/// dashboard sin haber aceptado nada: `terms_version` en NULL. Había aceptado
/// los términos de la clínica de nutrición, que es otra empresa, así que este
/// producto trataba sus datos sin ninguna base propia. Y cuando el texto cambia,
/// lo que firmó ya no es lo que rige.
///
/// Lo que se prueba no es la pantalla sino **la decisión**: `completeLoginAndEnter`
/// es el único sitio por el que se entra, y es ahí donde se mira. Una prueba de
/// la pantalla sola pasaría igual aunque nadie la enrutara nunca.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PatientSession.instance.clear();
  });

  /// El `GET /me` que devuelve el servidor, con los términos en el estado que
  /// pida cada prueba.
  http.Client meThatSays({
    String? termsVersion,
    String? currentTermsVersion = '2026-08',
  }) => MockClient((request) async {
    return http.Response(
      jsonEncode({
        'identity': {
          'email': 'maria@example.com',
          'migrated': true,
          'termsVersion': ?termsVersion,
          'currentTermsVersion': ?currentTermsVersion,
        },
        'personal': {'firstName': 'María'},
        'preferences': {'locale': 'es', 'unitSystem': 'METRIC'},
      }),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });

  /// Monta lo justo para poder llamar a `completeLoginAndEnter` y ver a dónde
  /// deja al paciente. Las dos rutas de destino son marcadores: lo que importa
  /// es cuál de las dos se pinta.
  Future<String> destinationAfterLogin(
    WidgetTester tester,
    http.Client meClient,
  ) async {
    final profile = UserProfileProvider();
    final onboarding = OnboardingProvider();
    final localeUnits = LocaleUnitsProvider();
    final goals = HealthGoalsProvider();
    final sync = ProfileSyncService(
      profile: profile,
      localeUnits: localeUnits,
      goals: goals,
      client: ProfileApiClient(httpClient: meClient),
    );

    final router = GoRouter(
      initialLocation: '/entrando',
      routes: [
        GoRoute(
          path: '/entrando',
          builder: (context, state) => const _EntryTrigger(
            account: PatientAccount(
              publicId: 'p-1',
              firstName: 'María',
              source: 'LEGACY',
              migrated: true,
            ),
          ),
        ),
        GoRoute(path: '/dashboard', builder: (_, _) => const Text('DASHBOARD')),
        GoRoute(path: '/terminos', builder: (_, _) => const Text('TERMINOS')),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: profile),
          ChangeNotifierProvider.value(value: onboarding),
          ChangeNotifierProvider.value(value: localeUnits),
          Provider.value(value: sync),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Se cierra aquí y no en un tearDown: el servicio deja programado el envío
    // del perfil con un temporizador, y el marco de pruebas lo daría por
    // pendiente antes de que el tearDown llegue a correr.
    sync.dispose();

    if (find.text('TERMINOS').evaluate().isNotEmpty) return '/terminos';
    if (find.text('DASHBOARD').evaluate().isNotEmpty) return '/dashboard';
    return 'ninguna';
  }

  testWidgets('un migrado sin términos aceptados NO llega al dashboard', (
    tester,
  ) async {
    final destino = await destinationAfterLogin(tester, meThatSays());

    expect(destino, '/terminos');
  });

  testWidgets(
    'quien aceptó una versión anterior vuelve a pasar por la puerta',
    (tester) async {
      // Los términos cambiaron: lo que firmó ya no es lo que rige.
      final destino = await destinationAfterLogin(
        tester,
        meThatSays(termsVersion: '2025-01'),
      );

      expect(destino, '/terminos');
    },
  );

  testWidgets('quien ya aceptó la versión vigente entra directo', (
    tester,
  ) async {
    final destino = await destinationAfterLogin(
      tester,
      meThatSays(termsVersion: '2026-08'),
    );

    expect(destino, '/dashboard');
  });

  testWidgets('sin servidor se entra igual, no se deja a nadie fuera', (
    tester,
  ) async {
    // Dejar a alguien fuera de sus propios datos por un problema NUESTRO sería
    // peor que pedirle la aceptación en el siguiente arranque.
    final destino = await destinationAfterLogin(
      tester,
      MockClient((_) async => http.Response('', 503)),
    );

    expect(destino, '/dashboard');
  });
}

/// Dispara la entrada en cuanto se pinta, que es como ocurre en la app: la
/// pantalla del código llama y se va.
class _EntryTrigger extends StatefulWidget {
  final PatientAccount account;

  const _EntryTrigger({required this.account});

  @override
  State<_EntryTrigger> createState() => _EntryTriggerState();
}

class _EntryTriggerState extends State<_EntryTrigger> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      completeLoginAndEnter(
        context,
        widget.account,
        sessionToken: 'tok-123',
        identifier: 'maria@example.com',
      );
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
