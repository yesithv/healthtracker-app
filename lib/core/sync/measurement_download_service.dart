import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/core/sync/legacy_import_mapper.dart';
import 'package:myvitals_healthtracker_app/core/sync/measurement_read_client.dart';

/// Sincronización ENTRANTE (API → app): baja la serie del paciente autenticado y
/// materializa el historial del LEGACY en la BD local, que es lo que leen el
/// dashboard y los historiales (local-first).
///
/// Idempotente: los registros se deduplican por instante de medición, así que
/// repetir la descarga (cada login, cada "Sincronizar ahora") no duplica nada.
class MeasurementDownloadService {
  final MeasurementReadClient _client;
  final AnthropometricRepository _anthropometric;
  final BodyCompositionRepository _body;

  MeasurementDownloadService({
    MeasurementReadClient? client,
    AnthropometricRepository? anthropometric,
    BodyCompositionRepository? body,
  })  : _client = client ?? MeasurementReadClient(),
        _anthropometric = anthropometric ?? AnthropometricRepository.instance,
        _body = body ?? BodyCompositionRepository.instance;

  /// Baja e importa el historial. Devuelve cuántos registros locales NUEVOS se
  /// crearon. Lanza [SyncException] si la API no responde (el llamador decide si
  /// es fatal; en el sync es best-effort).
  Future<int> importFromServer() async {
    final points = await _client.fetchMine();
    final batch = LegacyImportMapper.fromServer(points);
    if (batch.isEmpty) return 0;

    var inserted = 0;

    final existingAnthro = (await _anthropometric.getAll())
        .map((r) => r.date.toIso8601String())
        .toSet();
    for (final r in batch.anthropometric) {
      if (existingAnthro.add(r.date.toIso8601String())) {
        await _anthropometric.insert(r);
        inserted++;
      }
    }

    final existingBody =
        (await _body.getAll()).map((r) => r.date.toIso8601String()).toSet();
    for (final r in batch.bodyComposition) {
      if (existingBody.add(r.date.toIso8601String())) {
        await _body.insert(r);
        inserted++;
      }
    }

    return inserted;
  }

  void close() => _client.close();
}
