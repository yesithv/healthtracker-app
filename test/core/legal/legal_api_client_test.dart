import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/legal/legal_api_client.dart';
import 'package:myvitals_healthtracker_app/core/sync/sync_api_client.dart'
    show SyncException;
import 'package:shared_preferences/shared_preferences.dart';

/// Leer los textos legales y aceptar los términos.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PatientSession.instance.save(publicId: 'p-1', token: 'tok-123');
  });

  test('los textos se piden en el idioma de la app y SIN sesión', () async {
    late http.Request visto;
    final client = LegalApiClient(
      httpClient: MockClient((request) async {
        visto = request;
        return http.Response(
          jsonEncode({
            'document': 'terms',
            'version': '2026-08',
            'locale': 'en',
            'translated': true,
            'body': '# Terms of use',
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final doc = await client.fetch(LegalApiClient.terms, locale: 'en');

    expect(visto.url.path, '/api/v1/legal/terms');
    expect(visto.url.queryParameters['locale'], 'en');
    // Sin cabecera de sesión a propósito: hay que poder leer qué se va a
    // aceptar ANTES de tener cuenta, y también después de darse de baja.
    expect(visto.headers.containsKey('Authorization'), isFalse);
    expect(doc.version, '2026-08');
    expect(doc.translated, isTrue);
    expect(doc.body, contains('Terms of use'));
  });

  test('un documento servido en otro idioma llega diciéndolo', () async {
    final client = LegalApiClient(
      httpClient: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'document': 'terms',
            'version': '2026-08',
            'locale': 'es',
            'translated': false,
            'body': '# Términos de uso',
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final doc = await client.fetch(LegalApiClient.terms, locale: 'fr');

    // La pantalla lo avisa: que alguien acepte un contrato creyendo haberlo
    // leído en su idioma es peor que decirle que está en otro.
    expect(doc.locale, 'es');
    expect(doc.translated, isFalse);
  });

  test(
    'la aceptación va con la sesión y con la versión del texto leído',
    () async {
      late http.Request visto;
      final client = LegalApiClient(
        httpClient: MockClient((request) async {
          visto = request;
          return http.Response('', 204);
        }),
      );

      await client.acceptTerms('2026-08');

      expect(visto.url.path, '/api/v1/me/terms');
      expect(visto.method, 'POST');
      expect(visto.headers['Authorization'], 'Bearer tok-123');
      expect(
        (jsonDecode(visto.body) as Map<String, dynamic>)['version'],
        '2026-08',
      );
    },
  );

  test('un rechazo del servidor no pasa por aceptación', () async {
    // El servidor devuelve 409 cuando la versión no es la vigente. Tragárselo
    // dejaría al paciente dentro creyendo que aceptó algo que no quedó escrito.
    final client = LegalApiClient(
      httpClient: MockClient(
        (_) async => http.Response('{"detail":"..."}', 409),
      ),
    );

    expect(() => client.acceptTerms('1999-01'), throwsA(isA<SyncException>()));
  });
}
