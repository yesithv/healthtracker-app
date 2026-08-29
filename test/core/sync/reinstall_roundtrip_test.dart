import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myvitals_healthtracker_app/core/database/database_service.dart';
import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/core/sync/measurement_download_service.dart';
import 'package:myvitals_healthtracker_app/core/sync/measurement_read_client.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// **Reinstalar la app y recuperarlo todo.** La prueba que da sentido a la fase.
///
/// El fixture no está escrito a mano: es la respuesta literal de
/// `GET /api/v1/me/measurements` recorriendo el ecosistema completo —MySQL con los datos
/// de NutryApp, la ACL, la migración y la curación— para María Gómez, después de que
/// registrara desde la app uno de cada una de las cuatro familias. 28 puntos del legacy
/// y 10 suyos.
///
/// Se parte de una base vacía, que es exactamente lo que hay tras reinstalar: el teléfono
/// no sabe nada y el servidor es su única memoria.
void main() {
  setUpAll(() {
    DatabaseService.useDatabaseFile('test-reinstall-roundtrip.db');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AnthropometricRepository.instance.clearAll();
    await VitalSignsRepository.instance.clearAll();
    await LipidRepository.instance.clearAll();
    await BodyCompositionRepository.instance.clearAll();
  });

  final payload = File(
    'test/fixtures/me_measurements_reinstall.json',
  ).readAsStringSync();

  MeasurementDownloadService elServidorReal() => MeasurementDownloadService(
    client: MeasurementReadClient(
      httpClient: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(payload),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    ),
  );

  test('un teléfono vacío recupera su historia y lo suyo', () async {
    await elServidorReal().importFromServer();

    // Del legacy: las dos atenciones de María, como antes de esta fase.
    final antro = await AnthropometricRepository.instance.getAll();
    final body = await BodyCompositionRepository.instance.getAll();
    expect(antro.length, greaterThanOrEqualTo(3));
    expect(body.length, greaterThanOrEqualTo(3));

    // Y lo que él registró, que antes NO volvía en ninguna de las cuatro familias.
    expect(antro.map((r) => r.id), contains('e2e-antro'));
    expect(body.map((r) => r.id), contains('e2e-body'));
    expect(
      (await VitalSignsRepository.instance.getAll()).map((r) => r.id),
      contains('e2e-vital'),
    );
    expect(
      (await LipidRepository.instance.getAll()).map((r) => r.id),
      contains('e2e-lipid'),
    );
  });

  test(
    'vuelve con el laboratorio, la báscula y el estado de actividad',
    () async {
      await elServidorReal().importFromServer();

      final vital = (await VitalSignsRepository.instance.getAll()).firstWhere(
        (r) => r.id == 'e2e-vital',
      );
      final lipid = (await LipidRepository.instance.getAll()).single;
      final body = (await BodyCompositionRepository.instance.getAll())
          .firstWhere((r) => r.id == 'e2e-body');

      // Sin esto se recuperarían cifras sueltas: un colesterol sin saber de qué
      // laboratorio, una bioimpedancia sin saber con qué báscula.
      expect(vital.activityState, 'reposo');
      expect(lipid.labName, 'Laboratorio Central');
      expect(body.deviceName, 'Omron HBF-516');
    },
  );

  test('los valores son los que se registraron, no aproximaciones', () async {
    await elServidorReal().importFromServer();

    final vital = (await VitalSignsRepository.instance.getAll()).firstWhere(
      (r) => r.id == 'e2e-vital',
    );
    expect(vital.systolic, 118);
    expect(vital.diastolic, 76);
    expect(vital.heartRate, 64);

    final lipid = (await LipidRepository.instance.getAll()).single;
    expect(lipid.totalCholesterol, 188);
    expect(lipid.triglycerides, 121);

    final antro = (await AnthropometricRepository.instance.getAll()).firstWhere(
      (r) => r.id == 'e2e-antro',
    );
    expect(antro.weight, 77.2);
    // El servidor guarda la talla en metros y la app la maneja en cm.
    expect(antro.height, 162.0);
  });

  test('nada de lo recuperado se vuelve a subir', () async {
    await elServidorReal().importFromServer();

    // Vino del servidor: si naciera pendiente, la siguiente sincronización lo
    // devolvería y el ciclo no pararía nunca.
    expect(await AnthropometricRepository.instance.getUnsynced(), isEmpty);
    expect(await VitalSignsRepository.instance.getUnsynced(), isEmpty);
    expect(await LipidRepository.instance.getUnsynced(), isEmpty);
    expect(await BodyCompositionRepository.instance.getUnsynced(), isEmpty);
  });
}
