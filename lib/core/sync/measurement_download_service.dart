import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/core/sync/measurement_read_client.dart';
import 'package:myvitals_healthtracker_app/core/sync/server_import_mapper.dart';

/// Sincronización ENTRANTE (API → app): baja la serie del paciente autenticado y
/// materializa en la BD local lo que el teléfono no tenga, que es lo que leen el
/// dashboard y los historiales (local-first).
///
/// <h3>Qué baja</h3>
///
/// **Las cuatro familias, y tanto lo migrado del legacy como lo que el propio paciente
/// registró.** Hasta ahora bajaba solo antropometría y composición corporal del legacy:
/// quien reinstalaba la app recuperaba su historia de la clínica y perdía todo lo que
/// había escrito él. El servidor lo tenía; nadie se lo devolvía.
///
/// <h3>Idempotente, y ahora por identidad</h3>
///
/// Un registro que vuelve del servidor trae el `clientId` con el que nació aquí, así que
/// se reconoce por su id y no por parecerse. Cuando no lo trae —el legacy nunca lo
/// tuvo— se cae al criterio anterior, el instante de la medición. Repetir la descarga
/// (cada entrada, cada «Sincronizar ahora») no duplica nada.
class MeasurementDownloadService {
  final MeasurementReadClient _client;
  final AnthropometricRepository _anthropometric;
  final VitalSignsRepository _vitals;
  final LipidRepository _lipid;
  final BodyCompositionRepository _body;

  MeasurementDownloadService({
    MeasurementReadClient? client,
    AnthropometricRepository? anthropometric,
    VitalSignsRepository? vitals,
    LipidRepository? lipid,
    BodyCompositionRepository? body,
  }) : _client = client ?? MeasurementReadClient(),
       _anthropometric = anthropometric ?? AnthropometricRepository.instance,
       _vitals = vitals ?? VitalSignsRepository.instance,
       _lipid = lipid ?? LipidRepository.instance,
       _body = body ?? BodyCompositionRepository.instance;

  /// Baja e importa el historial. Devuelve cuántos registros locales NUEVOS se
  /// crearon. Lanza [SyncException] si la API no responde (el llamador decide si
  /// es fatal; en el sync es best-effort).
  Future<int> importFromServer() async {
    final batch = ServerImportMapper.fromServer(await _client.fetchMine());
    if (batch.isEmpty) return 0;

    var inserted = 0;
    inserted += await _importFamily(batch.anthropometric, _anthropometric);
    inserted += await _importFamily(batch.vitalSigns, _vitals);
    inserted += await _importFamily(batch.lipids, _lipid);
    inserted += await _importFamily(batch.bodyComposition, _body);
    return inserted;
  }

  /// Inserta los que el teléfono no conozca ya.
  ///
  /// Se comparan **id e instante a la vez**: el id reconoce lo que salió de este
  /// teléfono, y el instante cubre lo migrado del legacy, que nunca tuvo id propio.
  /// Bastaría el id si todo lo hubiera creado la app, y bastaría el instante si nada
  /// pudiera repetirlo; ninguna de las dos cosas es cierta.
  ///
  /// La identidad y la fecha se leen por el propio repositorio (`idOf` y el
  /// `measurement_date` de su `toMap`), que es la abstracción que ya comparten las
  /// cuatro familias: los modelos son data classes independientes y no tienen —ni
  /// necesitan— una interfaz común.
  Future<int> _importFamily<T>(
    List<T> incoming,
    RecordRepository<T> repository,
  ) async {
    final existing = await repository.getAll();
    final knownIds = existing.map(repository.idOf).toSet();
    final knownInstants = existing
        .map((r) => repository.toMap(r)['measurement_date'] as String)
        .toSet();

    var inserted = 0;
    for (final record in incoming) {
      final isNewId = knownIds.add(repository.idOf(record));
      final isNewInstant = knownInstants.add(
        repository.toMap(record)['measurement_date'] as String,
      );
      if (!isNewId || !isNewInstant) continue;
      await repository.insert(record);
      inserted++;
    }
    return inserted;
  }

  void close() => _client.close();
}
