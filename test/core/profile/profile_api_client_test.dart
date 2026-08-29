import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myvitals_healthtracker_app/core/constants/measurement_unit.dart';
import 'package:myvitals_healthtracker_app/core/profile/profile_api_client.dart';

/// El contrato de `/api/v1/me`, que es lo que hace que reinstalar la app no cueste el
/// perfil entero.
///
/// Lo que estas pruebas sujetan no es que el cliente hable HTTP, sino la regla que
/// sostiene el diseño: **lo que el teléfono no sabe no viaja**. El servidor entiende un
/// campo ausente como «no lo toques», así que mandar un hueco como cadena vacía sería
/// pedirle que borre —y en un paciente migrado, lo que borraría son los datos que vinieron
/// de NutryApp y que él nunca tecleó—.
void main() {
  /// Guarda el cuerpo del último PUT para poder mirarlo.
  late Map<String, dynamic> enviado;

  ProfileApiClient clientThatEchoes({String responseBody = '{}'}) =>
      ProfileApiClient(
        httpClient: MockClient((request) async {
          if (request.method == 'PUT') {
            enviado = jsonDecode(request.body) as Map<String, dynamic>;
          }
          return http.Response(
            responseBody,
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

  setUp(() => enviado = {});

  const perfilCompleto = '''
{"identity":{"publicId":"5744d2aa-2473-4d3b-8707-6ca5bfe6b183",
             "email":"maria@example.com","documentMasked":"••••••6789",
             "source":"LEGACY","migrated":true,"termsVersion":null},
 "personal":{"firstName":"MARÍA","lastName":"GÓMEZ","birthDate":"1985-03-14",
             "sex":"F","phone":"3001234567","countryCode":"CO",
             "activityLevel":"very_active"},
 "preferences":{"locale":"es","unitSystem":"METRIC"},
 "goals":{"enabled":true,"targetWeightKg":68.5,"targetBodyFatPct":null,
          "targetMusclePct":null,"targetVisceralLevel":8}}''';

  group('leer el perfil', () {
    test('trae la ficha completa y la deja presentable', () async {
      final profile = await ProfileApiClient(
        httpClient: MockClient(
          (_) async => http.Response(
            perfilCompleto,
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      ).fetchMine();

      expect(profile.email, 'maria@example.com');
      expect(profile.migrated, isTrue);
      // El documento se muestra, no se edita: es la clave contra la que se contrasta
      // el legacy y solo viajan las últimas cifras.
      expect(profile.documentMasked, '••••••6789');
      // El legacy guarda los nombres EN MAYÚSCULAS.
      expect(profile.fullName, 'María Gómez');
      expect(profile.birthDate, DateTime(1985, 3, 14));
      expect(profile.genderForApp, 'female');
      expect(profile.activityLevel, 'very_active');
      expect(profile.unit, MeasurementUnit.metric);
      expect(profile.goals?.targetWeightKg, 68.5);
      expect(profile.goals?.targetVisceralLevel, 8);
    });

    test('sin metas el bloque llega nulo, que no es tenerlas vacías', () async {
      final profile = await ProfileApiClient(
        httpClient: MockClient(
          (_) async => http.Response('{"identity":{},"personal":{}}', 200),
        ),
      ).fetchMine();

      expect(profile.goals, isNull);
    });
  });

  group('guardar el perfil', () {
    test('un campo vacío NO viaja: ausente significa «no lo toques»', () async {
      await clientThatEchoes().save(
        firstName: '',
        lastName: '   ',
        phone: '',
        activityLevel: null,
        sex: 'male',
      );

      expect(enviado.containsKey('firstName'), isFalse);
      expect(enviado.containsKey('lastName'), isFalse);
      expect(enviado.containsKey('phone'), isFalse);
      expect(enviado.containsKey('activityLevel'), isFalse);
      // Y lo que sí tiene valor, sí va.
      expect(enviado['sex'], 'male');
    });

    test('la fecha viaja como día, no como instante', () async {
      // Un DateTime local a la izquierda de Greenwich, serializado como ISO completo,
      // llegaría al servidor como el día ANTERIOR. Aquí solo viaja la fecha.
      await clientThatEchoes().save(birthDate: DateTime(1985, 3, 14, 23, 30));

      expect(enviado['birthDate'], '1985-03-14');
    });

    test('las unidades viajan en el dialecto de la columna', () async {
      await clientThatEchoes().save(unit: MeasurementUnit.imperial);

      expect(enviado['unitSystem'], 'IMPERIAL');
    });

    test('unas metas sin nada que decir no se mandan', () async {
      // Se escriben enteras: mandar un bloque vacío borraría las del servidor, y eso
      // es justo lo que pasaría al tocar el teléfono desde un móvil recién instalado.
      await clientThatEchoes().save(
        goals: const ServerGoals(enabled: false),
        phone: '3001234567',
      );

      expect(enviado.containsKey('goals'), isFalse);
      expect(enviado['phone'], '3001234567');
    });

    test('unas metas apagadas pero con valores sí se mandan', () async {
      // Apagarlas no las borra: volver a encenderlas no debe obligar a reescribirlas.
      await clientThatEchoes().save(
        goals: const ServerGoals(enabled: false, targetWeightKg: 68.5),
      );

      expect(enviado['goals'], {'enabled': false, 'targetWeightKg': 68.5});
    });

    test('un error del servidor no pasa desapercibido', () async {
      final client = ProfileApiClient(
        httpClient: MockClient(
          (_) async => http.Response('{"detail":"nope"}', 400),
        ),
      );

      expect(() => client.save(phone: '300'), throwsA(isA<Exception>()));
    });
  });
}
