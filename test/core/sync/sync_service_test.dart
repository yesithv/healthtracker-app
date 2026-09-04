import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/core/sync/measurement_download_service.dart';
import 'package:myvitals_healthtracker_app/core/sync/measurement_read_client.dart';
import 'package:myvitals_healthtracker_app/core/sync/sync_api_client.dart';
import 'package:myvitals_healthtracker_app/core/sync/sync_service.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/anthropometric_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/lipid_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/vital_sign_record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myvitals_healthtracker_app/core/database/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// La subida (app → API), y sobre todo **qué pasa cuando falla**.
///
/// La regla que sostiene todo lo demás: si la subida no llega, **no se marca nada como
/// sincronizado**. Es lo único que hace que el siguiente intento reintente lo pendiente;
/// marcarlo por optimismo perdería el registro para siempre, porque nadie volvería a
/// mirarlo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Base propia para este fichero: `flutter test` corre los ficheros en paralelo
    // y compartir el archivo los bloquea entre sí («database is locked»).
    DatabaseService.useDatabaseFile('test-sync-service.db');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PatientSession.instance.save(publicId: 'p-1', token: 'tok');
    await AnthropometricRepository.instance.clearAll();
    await VitalSignsRepository.instance.clearAll();
    await LipidRepository.instance.clearAll();
    await BodyCompositionRepository.instance.clearAll();
  });

  /// Un servicio con red falsa. [uploadStatus] gobierna la subida; la bajada siempre
  /// devuelve una serie vacía salvo que se diga otra cosa.
  SyncService serviceWith({
    int uploadStatus = 201,
    List<Map<String, dynamic>> serverSeries = const [],
    List<String>? uploadedBodies,
    Duration debounce = const Duration(seconds: 2),
  }) {
    final upload = MockClient((request) async {
      uploadedBodies?.add(request.body);
      return http.Response(
        uploadStatus >= 200 && uploadStatus < 300
            ? '{"accepted":1,"rejected":0}'
            : '{"detail":"nope"}',
        uploadStatus,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final download = MockClient(
      (_) async => http.Response(
        jsonEncode(serverSeries),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    return SyncService(
      anthropometric: AnthropometricRepository.instance,
      vitals: VitalSignsRepository.instance,
      lipid: LipidRepository.instance,
      body: BodyCompositionRepository.instance,
      client: SyncApiClient(httpClient: upload),
      download: MeasurementDownloadService(
        client: MeasurementReadClient(httpClient: download),
      ),
      autoSyncDebounce: debounce,
    );
  }

  Future<void> unRegistroPendiente() =>
      AnthropometricRepository.instance.insert(
        AnthropometricRecord(
          id: 'antro-1',
          date: DateTime(2026, 5, 4, 10),
          weight: 78.4,
          height: 172,
          bmi: 26.5,
        ),
      );

  test('una subida correcta marca lo pendiente como sincronizado', () async {
    await unRegistroPendiente();
    final service = serviceWith();

    await service.syncNow();

    expect(service.status, SyncStatus.success);
    expect(await AnthropometricRepository.instance.getUnsynced(), isEmpty);
    service.dispose();
  });

  test(
    'si la subida falla NO se marca nada: el próximo intento lo reintenta',
    () async {
      await unRegistroPendiente();
      final service = serviceWith(uploadStatus: 500);

      await service.syncNow();

      expect(service.status, SyncStatus.error);
      // Lo que importa: sigue en la cola. Marcarlo habría perdido el registro, porque
      // nadie vuelve a mirar lo que ya está marcado.
      expect(
        await AnthropometricRepository.instance.getUnsynced(),
        hasLength(1),
      );
      service.dispose();
    },
  );

  test('sube las cuatro familias en un solo lote', () async {
    await unRegistroPendiente();
    await VitalSignsRepository.instance.insert(
      VitalSignRecord(
        date: DateTime(2026, 5, 4, 11),
        systolic: 124,
        diastolic: 79,
        heartRate: 68,
      ),
    );
    final bodies = <String>[];
    final service = serviceWith(uploadedBodies: bodies);

    await service.syncNow();

    expect(
      bodies,
      hasLength(1),
      reason: 'una sola petición, no una por familia',
    );
    final enviado = jsonDecode(bodies.single) as Map<String, dynamic>;
    final codes = (enviado['measurements'] as List)
        .map((m) => (m as Map<String, dynamic>)['indicatorCode'])
        .toSet();
    expect(codes, containsAll(['WEIGHT', 'HEIGHT', 'BMI']));
    expect(codes, containsAll(['BP_SYSTOLIC', 'BP_DIASTOLIC', 'HEART_RATE']));
    service.dispose();
  });

  test('sin nada que subir igual se baja el historial del servidor', () async {
    // Es el primer arranque de un paciente migrado: no tiene nada suyo que enviar y
    // su historia entera está al otro lado.
    final service = serviceWith(
      serverSeries: [
        {
          'indicatorCode': 'WEIGHT',
          'indicatorName': 'Peso',
          'measuredAt': '2026-04-18T10:00:00Z',
          'value': 70.5,
          'source': 'LEGACY',
        },
        {
          'indicatorCode': 'HEIGHT',
          'indicatorName': 'Talla',
          'measuredAt': '2026-04-18T10:00:00Z',
          'value': 1.62,
          'source': 'LEGACY',
        },
      ],
    );

    await service.syncNow();

    expect(service.status, SyncStatus.success);
    expect(await AnthropometricRepository.instance.getAll(), hasLength(1));
    service.dispose();
  });

  test('sin sesión no sale a la red y lo dice', () async {
    await PatientSession.instance.clear();
    await unRegistroPendiente();
    final bodies = <String>[];
    final service = serviceWith(uploadedBodies: bodies);

    await service.syncNow();

    expect(service.status, SyncStatus.notConfigured);
    expect(bodies, isEmpty);
    expect(await AnthropometricRepository.instance.getUnsynced(), hasLength(1));
    service.dispose();
  });

  test(
    'una ráfaga de guardados es una sola subida, no una por registro',
    () async {
      // La espera corta existe para esto: registrar tres cosas seguidas no debe ser
      // tres peticiones.
      final bodies = <String>[];
      final service = serviceWith(uploadedBodies: bodies);
      addTearDown(service.dispose);

      await unRegistroPendiente();
      await VitalSignsRepository.instance.insert(
        VitalSignRecord(
          date: DateTime(2026, 5, 4, 11),
          systolic: 120,
          diastolic: 80,
          heartRate: 65,
        ),
      );
      await LipidRepository.instance.insert(
        LipidRecord(date: DateTime(2026, 5, 4, 12), totalCholesterol: 190),
      );

      // La espera por defecto son dos segundos; se deja pasar algo más.
      await Future<void>.delayed(const Duration(milliseconds: 2500));

      expect(bodies, hasLength(1));
    },
  );
}
