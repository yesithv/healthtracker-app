import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/anthropometric_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/body_composition_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/lipid_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/vital_sign_record.dart';
import 'package:myvitals_healthtracker_app/core/database/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// La capa que guarda lo que el paciente escribe, contra SQLite de verdad.
///
/// Es el sitio donde vive su historial antes de llegar a ninguna parte: si el guardado
/// se pierde aquí, no hay sincronización que lo salve. De ahí que se pruebe contra el
/// motor real y no contra un doble —el mismo criterio que en el servidor, donde las
/// pruebas de integración corren sobre PostgreSQL y no sobre H2—.
void main() {
  setUpAll(() {
    // Base propia para este fichero: `flutter test` corre los ficheros en paralelo
    // y compartir el archivo los bloquea entre sí («database is locked»).
    DatabaseService.useDatabaseFile('test-record-repositories.db');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AnthropometricRepository.instance.clearAll();
    await VitalSignsRepository.instance.clearAll();
    await LipidRepository.instance.clearAll();
    await BodyCompositionRepository.instance.clearAll();
  });

  AnthropometricRecord antro({
    String? id,
    required DateTime date,
    double weight = 78.4,
    bool isSynced = false,
  }) => AnthropometricRecord(
    id: id,
    date: date,
    weight: weight,
    height: 172,
    bmi: 26.5,
    isSynced: isSynced,
  );

  group('guardar y leer', () {
    test('un registro guardado vuelve entero, con sus opcionales', () async {
      final record = AnthropometricRecord(
        date: DateTime(2026, 5, 4, 10),
        weight: 78.4,
        height: 172,
        bmi: 26.5,
        waistCm: 88.5,
        hipCm: 101,
        comment: 'en ayunas',
      );

      await AnthropometricRepository.instance.insert(record);

      final saved = (await AnthropometricRepository.instance.getAll()).single;
      expect(saved.id, record.id);
      expect(saved.date, DateTime(2026, 5, 4, 10));
      expect(saved.weight, 78.4);
      expect(saved.waistCm, 88.5);
      expect(saved.hipCm, 101);
      expect(saved.comment, 'en ayunas');
      // Nace pendiente de subir: es lo que hace que la sincronización lo recoja.
      expect(saved.isSynced, isFalse);
    });

    test('las cuatro familias se guardan cada una en su tabla', () async {
      await AnthropometricRepository.instance.insert(
        antro(date: DateTime(2026, 5, 4)),
      );
      await VitalSignsRepository.instance.insert(
        VitalSignRecord(
          date: DateTime(2026, 5, 4),
          systolic: 124,
          diastolic: 79,
          heartRate: 68,
        ),
      );
      await LipidRepository.instance.insert(
        LipidRecord(date: DateTime(2026, 5, 4), totalCholesterol: 190),
      );
      await BodyCompositionRepository.instance.insert(
        BodyCompositionRecord(date: DateTime(2026, 5, 4), bodyFatPercent: 22.1),
      );

      expect(await AnthropometricRepository.instance.getAll(), hasLength(1));
      expect(await VitalSignsRepository.instance.getAll(), hasLength(1));
      expect(await LipidRepository.instance.getAll(), hasLength(1));
      expect(await BodyCompositionRepository.instance.getAll(), hasLength(1));
    });

    test('la lista llega con la medición más reciente primero', () async {
      await AnthropometricRepository.instance.insert(
        antro(date: DateTime(2026, 1, 1), weight: 80),
      );
      await AnthropometricRepository.instance.insert(
        antro(date: DateTime(2026, 6, 1), weight: 76),
      );

      final all = await AnthropometricRepository.instance.getAll();
      expect(all.first.weight, 76);
      // El historial se lee de lo último hacia atrás: si el orden se invierte, las
      // pantallas enseñan el peso viejo como si fuera el de hoy.
      expect(all.last.weight, 80);
    });

    test('guardar con un id que ya existe reemplaza, no duplica', () async {
      final date = DateTime(2026, 5, 4);
      await AnthropometricRepository.instance.insert(
        antro(id: 'mismo', date: date, weight: 78),
      );
      await AnthropometricRepository.instance.insert(
        antro(id: 'mismo', date: date, weight: 76),
      );

      final all = await AnthropometricRepository.instance.getAll();
      expect(all, hasLength(1));
      expect(all.single.weight, 76);
    });
  });

  group('lo que sostiene la sincronización', () {
    test(
      'getUnsynced trae solo lo pendiente, y en orden cronológico',
      () async {
        await AnthropometricRepository.instance.insert(
          antro(id: 'nuevo-2', date: DateTime(2026, 6, 1)),
        );
        await AnthropometricRepository.instance.insert(
          antro(id: 'nuevo-1', date: DateTime(2026, 1, 1)),
        );
        await AnthropometricRepository.instance.insert(
          antro(id: 'ya-subido', date: DateTime(2026, 3, 1), isSynced: true),
        );

        final pending = await AnthropometricRepository.instance.getUnsynced();

        expect(pending.map((r) => r.id), ['nuevo-1', 'nuevo-2']);
      },
    );

    test('markSynced los saca de la cola de pendientes', () async {
      await AnthropometricRepository.instance.insert(
        antro(id: 'a', date: DateTime(2026, 1, 1)),
      );
      await AnthropometricRepository.instance.insert(
        antro(id: 'b', date: DateTime(2026, 2, 1)),
      );

      await AnthropometricRepository.instance.markSynced(['a']);

      expect(
        (await AnthropometricRepository.instance.getUnsynced()).map(
          (r) => r.id,
        ),
        ['b'],
      );
    });

    test('markSynced con una lista vacía no toca nada', () async {
      // Ocurre cuando una familia no tenía nada que subir. Sin esta guarda, el SQL
      // saldría con un `IN ()` que SQLite rechaza.
      await AnthropometricRepository.instance.insert(
        antro(id: 'a', date: DateTime(2026, 1, 1)),
      );

      await AnthropometricRepository.instance.markSynced([]);

      expect(
        await AnthropometricRepository.instance.getUnsynced(),
        hasLength(1),
      );
    });
  });

  group('editar y borrar', () {
    test('actualizar cambia la fila y no crea otra', () async {
      final record = antro(id: 'x', date: DateTime(2026, 5, 4), weight: 78);
      await AnthropometricRepository.instance.insert(record);

      final changed = await AnthropometricRepository.instance.update(
        antro(id: 'x', date: DateTime(2026, 5, 4), weight: 75),
      );

      expect(changed, 1);
      final all = await AnthropometricRepository.instance.getAll();
      expect(all, hasLength(1));
      expect(all.single.weight, 75);
    });

    test('actualizar algo que no existe no afecta a ninguna fila', () async {
      final changed = await AnthropometricRepository.instance.update(
        antro(id: 'fantasma', date: DateTime(2026, 5, 4)),
      );

      expect(changed, isZero);
    });

    test('borrar quita solo el suyo', () async {
      await AnthropometricRepository.instance.insert(
        antro(id: 'a', date: DateTime(2026, 1, 1)),
      );
      await AnthropometricRepository.instance.insert(
        antro(id: 'b', date: DateTime(2026, 2, 1)),
      );

      expect(await AnthropometricRepository.instance.delete('a'), 1);

      expect(
        (await AnthropometricRepository.instance.getAll()).map((r) => r.id),
        ['b'],
      );
    });

    test(
      'clearAll vacía la tabla: es lo que aísla a un paciente de otro',
      () async {
        await AnthropometricRepository.instance.insert(
          antro(date: DateTime(2026, 1, 1)),
        );

        await AnthropometricRepository.instance.clearAll();

        // Al cerrar sesión no puede quedar nada del anterior: ni visible, ni subible
        // a la cuenta del siguiente.
        expect(await AnthropometricRepository.instance.getAll(), isEmpty);
        expect(await AnthropometricRepository.instance.count(), isZero);
      },
    );
  });

  group('paginación y caché', () {
    test(
      'getPaginated devuelve la página pedida, la más reciente primero',
      () async {
        for (var month = 1; month <= 5; month++) {
          await AnthropometricRepository.instance.insert(
            antro(date: DateTime(2026, month, 1), weight: 70.0 + month),
          );
        }

        final page = await AnthropometricRepository.instance.getPaginated(
          limit: 2,
          offset: 2,
        );

        expect(page.map((r) => r.weight), [73.0, 72.0]);
      },
    );

    test(
      'la caché en memoria refleja la escritura sin volver a consultar',
      () async {
        // Las pantallas leen `items` de forma síncrona en cada rebuild; si la caché no
        // se refrescara al escribir, el registro recién guardado no aparecería hasta
        // reabrir la pantalla.
        await AnthropometricRepository.instance.insert(
          antro(id: 'recien', date: DateTime(2026, 5, 4)),
        );

        expect(AnthropometricRepository.instance.items.map((r) => r.id), [
          'recien',
        ]);
        expect(AnthropometricRepository.instance.isLoaded, isTrue);
      },
    );
  });
}
