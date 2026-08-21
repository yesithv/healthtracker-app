import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/providers/measuring_device_provider.dart';
import 'package:myvitals_healthtracker_app/core/sync/device_api_client.dart';
import 'package:myvitals_healthtracker_app/core/sync/sync_api_client.dart'
    show SyncException;

/// Fake del cliente HTTP: sustituye la red para probar la lógica local-first del provider.
class _FakeDeviceApiClient extends DeviceApiClient {
  List<MeasuringDevice> catalog;
  String? serverCode;
  bool failSet;
  String? lastSet;
  bool setCalled = false;

  _FakeDeviceApiClient({
    this.catalog = const [],
    this.serverCode,
    this.failSet = false,
  });

  @override
  Future<List<MeasuringDevice>> fetchCatalog() async => catalog;

  @override
  Future<String?> fetchMyDeviceCode() async => serverCode;

  @override
  Future<void> setMyDeviceCode(String? code) async {
    setCalled = true;
    lastSet = code;
    if (failSet) throw const SyncException('boom');
    serverCode = code;
  }
}

const _omron = MeasuringDevice(
  code: 'OMRON_HBF514C',
  brand: 'Omron',
  model: 'HBF-514C',
  name: 'Omron HBF-514C',
  deviceType: 'BIOIMPEDANCE',
);
const _tanita = MeasuringDevice(
  code: 'TANITA_BC601',
  brand: 'Tanita',
  model: 'BC-601',
  name: 'Tanita BC-601',
  deviceType: 'BIOIMPEDANCE',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // _canSync exige paciente autenticado; simúlalo.
    await PatientSession.instance.save(publicId: 'p1');
  });

  test(
    'sin elección previa: pide elegir y carga el catálogo de la API',
    () async {
      final fake = _FakeDeviceApiClient(
        catalog: [_omron, _tanita],
        serverCode: null,
      );
      final provider = MeasuringDeviceProvider(client: fake);

      await provider.load();

      expect(provider.shouldPrompt, isTrue);
      expect(provider.hasChosen, isFalse);
      expect(provider.catalog, hasLength(2));
    },
  );

  test('elegir báscula: persiste, sincroniza y deja de pedir', () async {
    final fake = _FakeDeviceApiClient(catalog: [_omron]);
    final provider = MeasuringDeviceProvider(client: fake);
    await provider.load();

    await provider.select(_omron);

    expect(provider.selectedCode, 'OMRON_HBF514C');
    expect(provider.usesNoDevice, isFalse);
    expect(provider.hasChosen, isTrue);
    expect(provider.pendingSync, isFalse);
    expect(fake.lastSet, 'OMRON_HBF514C');
  });

  test('"no uso ninguna" es una elección explícita (usesNoDevice)', () async {
    final fake = _FakeDeviceApiClient(catalog: [_omron]);
    final provider = MeasuringDeviceProvider(client: fake);
    await provider.load();

    await provider.selectNone();

    expect(provider.usesNoDevice, isTrue);
    expect(provider.selectedCode, isNull);
    expect(provider.shouldPrompt, isFalse);
    expect(fake.setCalled, isTrue);
    expect(fake.lastSet, isNull);
  });

  test(
    'sin red al elegir: queda pendiente y se empuja en el siguiente refresh',
    () async {
      final fake = _FakeDeviceApiClient(catalog: [_omron], failSet: true);
      final provider = MeasuringDeviceProvider(client: fake);
      await provider.load();

      await provider.select(_omron);
      expect(
        provider.pendingSync,
        isTrue,
      ); // falló la subida, pero la elección quedó local

      fake.failSet = false; // vuelve la red
      await provider.refresh();

      expect(provider.pendingSync, isFalse);
      expect(fake.lastSet, 'OMRON_HBF514C');
    },
  );

  test(
    'reconcilia con el servidor: adopta la selección remota si existe',
    () async {
      final fake = _FakeDeviceApiClient(
        catalog: [_omron, _tanita],
        serverCode: 'TANITA_BC601',
      );
      final provider = MeasuringDeviceProvider(client: fake);

      await provider.load();

      expect(provider.selectedCode, 'TANITA_BC601');
      expect(provider.selectedName, 'Tanita BC-601');
      expect(provider.hasChosen, isTrue);
    },
  );
}
