import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myvitals_healthtracker_app/core/sync/server_import_mapper.dart';
import 'package:myvitals_healthtracker_app/core/sync/measurement_read_client.dart';
import 'package:myvitals_healthtracker_app/core/sync/sync_api_client.dart';

/// Lo que ve el paciente del legacy la primera vez que entra: **su historia**.
///
/// El fixture no está escrito a mano. Es la respuesta literal de
/// `GET /api/v1/me/measurements` recorriendo el ecosistema completo —MySQL con los datos
/// de NutryApp, la ACL, la migración del BackOffice-Api y la curación— para María Gómez.
/// Así, si alguna pieza de esa cadena cambia el contrato, esta prueba se entera antes que
/// el paciente.
///
/// María tiene en el legacy **dos atenciones expuestas** (una tercera está abierta y una
/// cuarta inactiva: ninguna debe salir). De ahí salen dos registros de antropometría y dos
/// de composición corporal.
void main() {
  final payload = File(
    'test/fixtures/me_measurements_maria.json',
  ).readAsStringSync();

  test('la serie del servidor se parsea entera', () {
    final points = (jsonDecode(payload) as List)
        .map((e) => ServerMeasurement.fromJson(e as Map<String, dynamic>))
        .toList();

    expect(points, hasLength(28));
    expect(points.every((p) => p.isFromLegacy), isTrue);
    // 14 indicadores por atención: si la curación deja de escribir alguno, se nota aquí.
    expect(points.map((p) => p.indicatorCode).toSet(), hasLength(14));
  });

  test('bajarla reconstruye las dos atenciones como registros locales', () async {
    final client = MeasurementReadClient(
      httpClient: MockClient(
        (_) async => http.Response(
          payload,
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );

    final imported = ServerImportMapper.fromServer(await client.fetchMine());

    expect(imported.anthropometric, hasLength(2));
    expect(imported.bodyComposition, hasLength(2));

    final primera = imported.anthropometric.first;
    expect(primera.weight, 70.1);
    // El servidor entrega la talla en metros y la app la guarda en centímetros.
    expect(primera.height, 162.0);
    expect(primera.bmi, 26.7);
    expect(primera.waistCm, 86.0);
    // Vinieron del servidor: no deben volver a subirse.
    expect(imported.anthropometric.every((r) => r.isSynced), isTrue);

    final composicion = imported.bodyComposition.first;
    expect(composicion.bodyFatPercent, 32.0);
    expect(composicion.musclePct, 27.0);
    expect(composicion.bmrKcal, 1850);
    expect(composicion.metabolicAge, 35);
    // El legacy guarda 7.5 y el modelo local es entero: se redondea a 8. Queda escrito
    // aquí porque es una pérdida de precisión deliberada, no un descuido.
    expect(composicion.visceralFatLevel, 8);
  });

  test('un error del servidor no se traga en silencio', () async {
    final client = MeasurementReadClient(
      httpClient: MockClient(
        (_) async => http.Response('{"detail":"nope"}', 500),
      ),
    );

    expect(client.fetchMine(), throwsA(isA<SyncException>()));
  });
}
