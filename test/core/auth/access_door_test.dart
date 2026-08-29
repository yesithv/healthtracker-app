import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myvitals_healthtracker_app/core/auth/auth_api_client.dart';

/// La puerta, desde el lado de la app.
///
/// Sustituye a las pruebas del alta diferida, que fijaban un comportamiento que ya no existe:
/// crear cuentas sin verificar el correo. Lo que hay que sujetar ahora es otra cosa —y más
/// importante—: que la app **no puede distinguir** quién tiene cuenta y quién no, porque la
/// respuesta del servidor es la misma; y que el 409 del alta lleva a llamar a la clínica en vez
/// de tratarse como un error cualquiera.
void main() {
  AuthApiClient clientThat({
    required int status,
    String body = '{}',
    void Function(http.Request request)? onRequest,
  }) => AuthApiClient(
    httpClient: MockClient((request) async {
      onRequest?.call(request);
      return http.Response(
        body,
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
  );

  group('pedir el código', () {
    test('la puerta acepta un 202 sin cuerpo', () async {
      // El servidor responde lo mismo exista o no la cuenta, y no manda nada que leer.
      await clientThat(status: 202, body: '').startAccess('maria@example.com');
    });

    test('el correo viaja recortado', () async {
      late Map<String, dynamic> enviado;
      final client = clientThat(
        status: 202,
        body: '{"next":"VERIFY_CODE"}',
        onRequest: (r) => enviado = jsonDecode(r.body) as Map<String, dynamic>,
      );

      await client.startAccess('  maria@example.com  ');

      expect(enviado, {'email': 'maria@example.com'});
    });

    test(
      'un servidor caído es un error de red, para poder reintentar',
      () async {
        expect(
          () => clientThat(status: 503).startAccess('maria@example.com'),
          throwsA(isA<AuthNetworkException>()),
        );
      },
    );
  });

  group('canjear el código del correo', () {
    test('con ficha, entra', () async {
      final body = jsonEncode({
        'sessionToken': 'token-1',
        'expiresAt': '2026-11-27T12:54:20Z',
        'next': 'HOME',
        'account': {'publicId': 'p-1', 'firstName': 'MARÍA', 'source': 'APP'},
      });

      final session = await clientThat(
        status: 200,
        body: body,
      ).verifyEmailCode(email: 'maria@example.com', code: '123456');

      expect(session.needsSignup, isFalse);
      expect(session.token, 'token-1');
      expect(session.account?.firstName, 'María');
    });

    test('sin ficha, manda al alta y no trae cuenta', () async {
      final body = jsonEncode({'sessionToken': 'token-2', 'next': 'SIGNUP'});

      final session = await clientThat(
        status: 200,
        body: body,
      ).verifyEmailCode(email: 'nueva@example.com', code: '123456');

      expect(session.needsSignup, isTrue);
      expect(session.account, isNull);
    });

    test('un código equivocado no dice por qué', () async {
      final body = jsonEncode({
        'status': 401,
        'detail': 'El código no es válido o ha caducado. Pide uno nuevo.',
      });

      expect(
        () => clientThat(
          status: 401,
          body: body,
        ).verifyEmailCode(email: 'maria@example.com', code: '000000'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'mensaje',
            contains('no es válido'),
          ),
        ),
      );
    });
  });

  group('el alta', () {
    test('manda la sesión en la cabecera y los términos aceptados', () async {
      late http.Request visto;
      final client = clientThat(
        status: 200,
        body: jsonEncode({
          'publicId': 'p-9',
          'firstName': 'Ana',
          'source': 'APP',
        }),
        onRequest: (r) => visto = r,
      );

      await client.signup(
        sessionToken: 'token-3',
        firstName: 'Ana',
        documentNumber: '5550001',
        termsAccepted: true,
      );

      expect(visto.headers['Authorization'], 'Bearer token-3');
      final body = jsonDecode(visto.body) as Map<String, dynamic>;
      expect(body['documentNumber'], '5550001');
      expect(body['termsAccepted'], isTrue);
    });

    test(
      'un documento que ya existe llega como CallClinic, no como error',
      () async {
        // La app distingue por la marca y no por el texto: comparar frases traducibles se rompe
        // en cuanto alguien mejora una de ellas.
        final body = jsonEncode({
          'status': 409,
          'reason': 'CALL_CLINIC',
          'detail': 'Ese documento ya está registrado en la clínica.',
        });

        expect(
          () => clientThat(status: 409, body: body).signup(
            sessionToken: 'token-3',
            firstName: 'Ana',
            documentNumber: '1032456789',
            termsAccepted: true,
          ),
          throwsA(isA<CallClinicException>()),
        );
      },
    );

    test('un 409 sin marca sigue siendo un error normal', () async {
      expect(
        () => clientThat(status: 409, body: '{"detail":"otra cosa"}').signup(
          sessionToken: 'token-3',
          firstName: 'Ana',
          documentNumber: '1032456789',
          termsAccepted: true,
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e is CallClinicException,
            'es CallClinic',
            isFalse,
          ),
        ),
      );
    });
  });
}
