import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/core/sync/measurement_download_service.dart';
import 'package:myvitals_healthtracker_app/core/sync/measurement_read_client.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/anthropometric_record.dart';
import 'package:myvitals_healthtracker_app/core/database/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// La vuelta completa: lo que el servidor guarda acaba en la BD local del teléfono.
///
/// Contra SQLite de verdad (`sqflite_common_ffi`, el patrón que ya usan las pruebas de
/// medicamentos y citas). Un doble del repositorio comprobaría que llamamos a `insert`;
/// lo que hay que comprobar es que **el historial aparece**, y eso solo lo dice la base.
void main() {
  setUpAll(() {
    // Base propia para este fichero: `flutter test` corre los ficheros en paralelo
    // y compartir el archivo los bloquea entre sí («database is locked»).
    DatabaseService.useDatabaseFile('test-measurement-download-service.db');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AnthropometricRepository.instance.clearAll();
    await VitalSignsRepository.instance.clearAll();
    await LipidRepository.instance.clearAll();
    await BodyCompositionRepository.instance.clearAll();
  });

  /// Un teléfono recién instalado que pregunta al servidor: cuatro registros, uno de
  /// cada familia, todos hechos por el propio paciente desde la app.
  List<Map<String, dynamic>> lasCuatroFamilias() {
    Map<String, dynamic> p(
      String code,
      num value,
      String clientId, {
      String at = '2026-05-04T10:00:00Z',
    }) => {
      'indicatorCode': code,
      'indicatorName': code,
      'measuredAt': at,
      'value': value,
      'source': 'APP',
      'context': jsonEncode({'clientId': clientId}),
    };

    return [
      p('WEIGHT', 78.4, 'antro-1'),
      p('HEIGHT', 1.72, 'antro-1'),
      p('BMI', 26.5, 'antro-1'),
      p('BP_SYSTOLIC', 124, 'vital-1'),
      p('BP_DIASTOLIC', 79, 'vital-1'),
      p('HEART_RATE', 68, 'vital-1'),
      p('CHOLESTEROL_TOTAL', 190, 'lipid-1'),
      p('CHOLESTEROL_HDL', 52, 'lipid-1'),
      p('BODY_FAT', 22.1, 'body-1'),
      p('MUSCLE_MASS', 40.5, 'body-1'),
    ];
  }

  MeasurementDownloadService serviceServing(
    List<Map<String, dynamic>> points,
  ) => MeasurementDownloadService(
    client: MeasurementReadClient(
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode(points),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    ),
  );

  test('las cuatro familias vuelven, no solo dos', () async {
    // Antes volvían antropometría y composición corporal. Los signos vitales y los
    // lípidos que el paciente registró no volvían nunca: se subían y se perdían.
    final inserted = await serviceServing(
      lasCuatroFamilias(),
    ).importFromServer();

    expect(inserted, 4);
    expect(await AnthropometricRepository.instance.getAll(), hasLength(1));
    expect(await VitalSignsRepository.instance.getAll(), hasLength(1));
    expect(await LipidRepository.instance.getAll(), hasLength(1));
    expect(await BodyCompositionRepository.instance.getAll(), hasLength(1));
  });

  test('los registros vuelven con su identidad y ya sincronizados', () async {
    await serviceServing(lasCuatroFamilias()).importFromServer();

    final vital = (await VitalSignsRepository.instance.getAll()).single;
    // El mismo id que tuvo en este teléfono: es el mismo registro, no otro parecido.
    expect(vital.id, 'vital-1');
    // Y no se vuelve a subir: vino del servidor.
    expect(vital.isSynced, isTrue);
  });

  test('bajar dos veces no duplica nada', () async {
    final service = serviceServing(lasCuatroFamilias());

    final primera = await service.importFromServer();
    final segunda = await service.importFromServer();

    expect(primera, 4);
    expect(segunda, isZero);
    expect(await VitalSignsRepository.instance.getAll(), hasLength(1));
  });

  test('no pisa un registro que el teléfono ya tenía', () async {
    // El caso normal: el móvil conserva sus datos y además pregunta al servidor. Lo
    // que baja coincide con lo que ya hay y no entra nada — que es lo que hacía
    // seguro dejar entrar los puntos APP.
    await AnthropometricRepository.instance.insert(
      AnthropometricRecord(
        id: 'antro-1',
        date: DateTime.parse('2026-05-04T10:00:00Z').toLocal(),
        weight: 99,
        height: 172,
        bmi: 33.4,
      ),
    );

    await serviceServing(lasCuatroFamilias()).importFromServer();

    final local = (await AnthropometricRepository.instance.getAll()).single;
    expect(local.weight, 99, reason: 'lo del teléfono no se sobrescribe');
  });

  test('una serie vacía no toca la base', () async {
    expect(await serviceServing([]).importFromServer(), isZero);
    expect(await AnthropometricRepository.instance.getAll(), isEmpty);
  });
}
