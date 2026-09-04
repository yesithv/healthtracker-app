import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/profile/profile_api_client.dart';
import 'package:myvitals_healthtracker_app/core/profile/profile_sync_service.dart';
import 'package:myvitals_healthtracker_app/core/providers/health_goals_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/locale_units_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quién manda sobre el perfil: **el servidor al entrar, el teléfono al editar**.
///
/// Las tres reglas que hacen que esa frase no se rompa en la práctica son las que se
/// prueban aquí. Ninguna es cosmética: la primera evita perder lo que la persona acaba
/// de escribir, la segunda evita reescribirle la ficha clínica sin que nadie toque nada,
/// y la tercera evita que traer datos del servidor dispare un envío de vuelta.
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  const perfilDelServidor = {
    'identity': {'email': 'maria@example.com', 'migrated': true},
    'personal': {
      'firstName': 'MARÍA',
      'lastName': 'GÓMEZ',
      'birthDate': '1985-03-14',
      'sex': 'F',
      'phone': '3001234567',
      'countryCode': 'CO',
      'activityLevel': 'very_active',
    },
    'preferences': {'locale': 'en', 'unitSystem': 'IMPERIAL'},
    'goals': {'enabled': true, 'targetWeightKg': 68.5},
  };

  /// Peticiones vistas por el cliente falso, para poder mirar qué se envió.
  late List<http.Request> peticiones;

  /// Los servicios creados en cada prueba. Se cierran al terminar: escuchan a
  /// [PatientSession], que es un singleton, y uno vivo de la prueba anterior
  /// reaccionaría al login de la siguiente.
  late List<ProfileSyncService> creados;

  ProfileSyncService serviceWith({
    required UserProfileProvider profile,
    required LocaleUnitsProvider localeUnits,
    required HealthGoalsProvider goals,
    Map<String, dynamic> serverProfile = perfilDelServidor,
  }) {
    final service = ProfileSyncService(
      profile: profile,
      localeUnits: localeUnits,
      goals: goals,
      client: ProfileApiClient(
        httpClient: MockClient((request) async {
          peticiones.add(request);
          return http.Response(
            jsonEncode(serverProfile),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );
    creados.add(service);
    return service;
  }

  /// Deja lista una sesión: sin ella el servicio calla, que es lo correcto pero no
  /// lo que estas pruebas quieren mirar.
  Future<void> abrirSesion() =>
      PatientSession.instance.save(publicId: 'p-1', token: 'tok');

  setUp(() async {
    peticiones = [];
    creados = [];
    SharedPreferences.setMockInitialValues({});
    await abrirSesion();

    // Fuera de la web el perfil busca la foto en el directorio de documentos, y en
    // una prueba no hay plugin nativo que responda: sin esto, el provider nunca
    // termina de cargar y todo lo demás espera para siempre.
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.createTempSync('profile_sync').path,
    );
  });

  tearDown(() {
    for (final service in creados) {
      service.dispose();
    }
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
  });

  test('hidratar rellena los huecos de un teléfono recién instalado', () async {
    final profile = UserProfileProvider();
    final localeUnits = LocaleUnitsProvider();
    final goals = HealthGoalsProvider();
    await profile.ready;

    await serviceWith(
      profile: profile,
      localeUnits: localeUnits,
      goals: goals,
    ).hydrateFromServer();

    expect(profile.userName, 'María Gómez');
    expect(profile.userEmail, 'maria@example.com');
    expect(profile.birthDate, DateTime(1985, 3, 14));
    expect(profile.userGender, 'female');
    expect(profile.userPhone, '3001234567');
    expect(profile.userCountryCode, 'CO');
    expect(profile.userActivityLevel, 'very_active');
    expect(localeUnits.locale.languageCode, 'en');
    expect(goals.medicalGoalsEnabled, isTrue);
    expect(goals.targetWeight, 68.5);
  });

  test('hidratar NO pisa lo que la persona ya escribió', () async {
    // El caso real: se editó el perfil sin red y la subida quedó pendiente. Si al
    // arrancar la hidratación pisara, esa edición se perdería sin dejar rastro.
    SharedPreferences.setMockInitialValues({
      'user_name': 'Mi Nombre',
      'user_activity_level': 'sedentary',
      'user_language': 'es',
    });
    await abrirSesion();
    final profile = UserProfileProvider();
    final localeUnits = LocaleUnitsProvider();
    final goals = HealthGoalsProvider();
    await profile.ready;

    await serviceWith(
      profile: profile,
      localeUnits: localeUnits,
      goals: goals,
    ).hydrateFromServer();

    expect(profile.userName, 'Mi Nombre');
    expect(profile.userActivityLevel, 'sedentary');
    expect(localeUnits.locale.languageCode, 'es');
    // Y lo que aquí no había sí se rellena.
    expect(profile.userPhone, '3001234567');
  });

  test('hidratar no dispara un envío de vuelta', () async {
    final profile = UserProfileProvider();
    await profile.ready;
    final service = serviceWith(
      profile: profile,
      localeUnits: LocaleUnitsProvider(),
      goals: HealthGoalsProvider(),
    );

    await service.hydrateFromServer();
    // La hidratación escribe en los providers, y los providers avisan. Sin silenciar
    // el envío mientras tanto, traer el perfil acabaría escribiéndolo otra vez.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(peticiones.where((r) => r.method == 'PUT'), isEmpty);
  });

  test('el nombre no viaja si nadie lo ha cambiado', () async {
    // La app guarda UN campo de nombre, así que al enviarlo hay que partirlo por el
    // primer espacio. Para «María del Carmen» / «Gómez Pérez» esa partida no es la del
    // legacy: mandarla sin que nadie toque nada le reescribiría la ficha.
    final profile = UserProfileProvider();
    await profile.ready;
    final service = serviceWith(
      profile: profile,
      localeUnits: LocaleUnitsProvider(),
      goals: HealthGoalsProvider(),
    );
    await service.hydrateFromServer();

    await service.pushNow();

    final put = peticiones.lastWhere((r) => r.method == 'PUT');
    final enviado = jsonDecode(put.body) as Map<String, dynamic>;
    expect(enviado.containsKey('firstName'), isFalse);
    expect(enviado.containsKey('lastName'), isFalse);
  });

  test('el nombre viaja partido cuando la persona sí lo cambia', () async {
    final profile = UserProfileProvider();
    await profile.ready;
    final service = serviceWith(
      profile: profile,
      localeUnits: LocaleUnitsProvider(),
      goals: HealthGoalsProvider(),
    );
    await service.hydrateFromServer();

    await profile.updatePersonalInfo(
      name: 'Ana Ruiz Soto',
      dob: DateTime(1990, 1, 1),
      email: 'ana@example.com',
      gender: 'female',
      activityLevel: 'sedentary',
    );
    await service.pushNow();

    final put = peticiones.lastWhere((r) => r.method == 'PUT');
    final enviado = jsonDecode(put.body) as Map<String, dynamic>;
    expect(enviado['firstName'], 'Ana');
    expect(enviado['lastName'], 'Ruiz Soto');
  });

  test('sin sesión no se habla con el servidor', () async {
    await PatientSession.instance.clear();
    final profile = UserProfileProvider();
    await profile.ready;

    final leido = await serviceWith(
      profile: profile,
      localeUnits: LocaleUnitsProvider(),
      goals: HealthGoalsProvider(),
    ).hydrateFromServer();

    expect(leido, isNull);
    expect(peticiones, isEmpty);
  });
}
