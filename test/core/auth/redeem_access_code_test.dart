import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myvitals_healthtracker_app/core/auth/auth_api_client.dart';

/// El canje del código que la clínica dicta por teléfono: la puerta por la que entra
/// **todo paciente que ya existía en NutryApp**.
///
/// No había ni una prueba de este camino. Y el riesgo no es teórico: la respuesta del
/// servidor se parsea a mano, así que un cambio de nombre de campo la rompe en silencio
/// —la app se quedaría sin poder entrar y nada en el código lo delataría—.
///
/// El JSON de aquí abajo NO está inventado: es la respuesta literal de la
/// HealthTracker-Api recorriendo el flujo completo contra el legacy (María Gómez, del
/// juego de datos de nutryapp-acl). Si el contrato cambia, este test se entera.
void main() {
  /// Cliente que responde lo que se le diga, sin tocar la red.
  AuthApiClient clientThat({required int status, required String body}) =>
      AuthApiClient(
        httpClient: MockClient(
          (_) async => http.Response(
            body,
            status,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );

  const respuestaReal = '''
{"sessionToken":"p7K0dUPNflKlNccaEacdUHVY2_Lujqz7v3SF3Ms4gI8",
 "expiresAt":"2026-11-27T12:54:20.330640274Z",
 "account":{"publicId":"5744d2aa-2473-4d3b-8707-6ca5bfe6b183","firstName":"María",
            "lastName":"Gómez","birthDate":"1990-04-12","sex":"F",
            "email":"maria@example.com","source":"LEGACY","migrated":true}}''';

  test('canjear el código devuelve la sesión y la ficha del paciente', () async {
    final session = await clientThat(
      status: 200,
      body: respuestaReal,
    ).redeemAccessCode(documentNumber: '1032456789', code: '482913');

    expect(session.token, 'p7K0dUPNflKlNccaEacdUHVY2_Lujqz7v3SF3Ms4gI8');
    expect(session.expiresAt?.toUtc().year, 2026);
    expect(session.account.publicId, '5744d2aa-2473-4d3b-8707-6ca5bfe6b183');
    expect(session.account.firstName, 'María');
    expect(session.account.source, 'LEGACY');
    expect(session.account.migrated, isTrue);
    // El legacy guarda los nombres en mayúsculas; la app los muestra presentables.
    expect(session.account.genderForApp, 'female');
  });

  test('el nombre en mayúsculas del legacy llega presentable', () async {
    final body = jsonEncode({
      'sessionToken': 't',
      'account': {
        'publicId': 'p',
        'firstName': 'MARÍA JOSÉ',
        'lastName': 'GÓMEZ ARIAS',
      },
    });

    final session = await clientThat(
      status: 200,
      body: body,
    ).redeemAccessCode(documentNumber: '1032456789', code: '482913');

    expect(session.account.firstName, 'María José');
    expect(session.account.lastName, 'Gómez Arias');
  });

  test(
    'un código inválido llega con el mensaje del servidor y no como error de red',
    () async {
      final body = jsonEncode({
        'type': 'about:blank',
        'title': 'Unauthorized',
        'status': 401,
        'detail':
            'El código no es válido o ha caducado. Pide uno nuevo a la clínica.',
      });

      expect(
        () => clientThat(
          status: 401,
          body: body,
        ).redeemAccessCode(documentNumber: '1032456789', code: '000000'),
        throwsA(
          isA<AuthException>()
              // La distinción importa: un 401 es «corrige el dato», no «reintenta luego».
              .having((e) => e is AuthNetworkException, 'es de red', isFalse)
              .having((e) => e.message, 'mensaje', contains('no es válido')),
        ),
      );
    },
  );

  test(
    'un servidor caído sí es un error de red, para poder reintentar',
    () async {
      expect(
        () => clientThat(
          status: 503,
          body: '{"detail":"Service Unavailable"}',
        ).redeemAccessCode(documentNumber: '1032456789', code: '482913'),
        throwsA(isA<AuthNetworkException>()),
      );
    },
  );

  test(
    'el canje manda documento Y código: sin el documento, seis dígitos al azar acertarían',
    () async {
      late Map<String, dynamic> enviado;
      final client = AuthApiClient(
        httpClient: MockClient((request) async {
          enviado = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(respuestaReal, 200);
        }),
      );

      await client.redeemAccessCode(
        documentNumber: '1032456789',
        code: '482913',
      );

      expect(enviado, {'documentNumber': '1032456789', 'code': '482913'});
    },
  );
}
