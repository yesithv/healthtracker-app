import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/export/data_export_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// El derecho de acceso, por fin ejercible desde la app.
///
/// `GET /me/export` existía desde hacía tiempo y **no lo llamaba nadie**: el derecho
/// estaba implementado en el servidor y no había manera de usarlo. Lo que se prueba aquí
/// es el trozo que se puede probar sin el diálogo del sistema: que se pide con la sesión
/// del paciente, que el volcado llega **tal cual** y que un fallo no pasa por bueno.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PatientSession.instance.save(publicId: 'p-1', token: 'tok-123');
  });

  test('pide el volcado con la sesión del paciente', () async {
    late http.Request visto;
    final service = DataExportService(
      httpClient: MockClient((request) async {
        visto = request;
        return http.Response('{"patient":{}}', 200);
      }),
    );

    await service.fetchMine();

    expect(visto.url.path, '/api/v1/me/export');
    // Sin esta cabecera el servidor respondería 401, que es exactamente lo que debe
    // pasarle a quien no tiene sesión.
    expect(visto.headers['Authorization'], 'Bearer tok-123');
  });

  test('el volcado llega tal cual, sin reinterpretarlo', () async {
    // Una exportación tiene que poder contrastarse con lo que hay en la base;
    // parsearla para volver a serializarla solo añadiría un sitio donde perder algo.
    const crudo =
        '{"patient":{"firstName":"María"},"measurements":[{"value":70.1}]}';
    final service = DataExportService(
      httpClient: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(crudo),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );

    expect(await service.fetchMine(), crudo);
  });

  test('un error del servidor no se traga en silencio', () async {
    final service = DataExportService(
      httpClient: MockClient(
        (_) async => http.Response('{"detail":"nope"}', 500),
      ),
    );

    expect(service.fetchMine(), throwsA(isA<Exception>()));
  });

  test('sin red, compartir devuelve error y no un éxito silencioso', () async {
    // Cancelar y fallar no son lo mismo, y ninguno de los dos puede leerse como
    // «tus datos se descargaron».
    final service = DataExportService(
      httpClient: MockClient((_) async => throw const SocketFailure()),
    );

    expect((await service.downloadAndShare('María')).name, 'error');
  });
}

/// Excepción de transporte simulada.
class SocketFailure implements Exception {
  const SocketFailure();
}
