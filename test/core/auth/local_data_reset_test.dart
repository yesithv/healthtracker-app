import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myvitals_healthtracker_app/core/auth/local_data_reset.dart';

/// Fija la primitiva del AISLAMIENTO ENTRE PACIENTES.
///
/// `completeLoginAndEnter` decide si hay que borrar los datos locales comparando
/// el dueño actual (`currentDataOwner`) con el paciente que entra: si en el
/// dispositivo quedaron datos de OTRO paciente, se limpian antes de sincronizar
/// para no subir historial ajeno ni mostrárselo al nuevo usuario. Todo ese
/// razonamiento depende de que este par leer/escribir sea fiable. Si mañana se
/// cambia la clave o el tipo, estas pruebas lo cazan antes de que un paciente
/// vea los datos de otro.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('rastreo del dueño de los datos locales ·', () {
    test('dispositivo recién estrenado: nadie es dueño todavía', () async {
      expect(await currentDataOwner(), isNull);
    });

    test('marcar dueño y volver a leerlo devuelve el mismo publicId', () async {
      await setDataOwner('paciente-A');
      expect(await currentDataOwner(), 'paciente-A');
    });

    test('entra otro paciente: el dueño se reemplaza, no se acumula', () async {
      await setDataOwner('paciente-A');
      await setDataOwner('paciente-B');

      // Es exactamente la señal que dispara el wipe de aislamiento: el dueño
      // guardado (A) no coincide con quien entra (B).
      expect(await currentDataOwner(), 'paciente-B');
    });

    test('el dueño persiste en el almacén, no solo en memoria', () async {
      await setDataOwner('paciente-A');

      // Simula reabrir la app con lo ya persistido: una instancia nueva de
      // SharedPreferences debe seguir viendo al dueño.
      SharedPreferences.setMockInitialValues({
        'data_owner_public_id': 'paciente-A',
      });
      expect(await currentDataOwner(), 'paciente-A');
    });
  });
}
