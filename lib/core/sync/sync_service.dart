import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/config/api_config.dart';
import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/core/sync/measurement_download_service.dart';
import 'package:myvitals_healthtracker_app/core/sync/measurement_mapper.dart';
import 'package:myvitals_healthtracker_app/core/sync/sync_api_client.dart';

enum SyncStatus { idle, syncing, success, error, notConfigured }

/// Orquesta la sincronización SALIENTE (app → API): reúne los registros locales no
/// sincronizados de las 4 familias, los aplana con [MeasurementMapper], los sube con
/// [SyncApiClient] y, solo si la subida tiene éxito, los marca como sincronizados.
///
/// Es un [ChangeNotifier] para que la UI muestre estado/última sincronización. La
/// política es simple y segura: idempotente (el servidor hace upsert por clave natural),
/// y ante cualquier fallo NO marca nada, así el próximo intento reintenta lo pendiente.
class SyncService extends ChangeNotifier {
  final AnthropometricRepository _anthropometric;
  final VitalSignsRepository _vitals;
  final LipidRepository _lipid;
  final BodyCompositionRepository _body;
  final SyncApiClient _client;
  final MeasurementDownloadService _download;

  /// Espera tras un guardado antes de sincronizar, para coalescer ráfagas de
  /// escrituras (p. ej. guardar varios registros seguidos) en una sola subida.
  final Duration autoSyncDebounce;

  SyncService({
    required AnthropometricRepository anthropometric,
    required VitalSignsRepository vitals,
    required LipidRepository lipid,
    required BodyCompositionRepository body,
    SyncApiClient? client,
    MeasurementDownloadService? download,
    this.autoSyncDebounce = const Duration(seconds: 2),
  }) : _anthropometric = anthropometric,
       _vitals = vitals,
       _lipid = lipid,
       _body = body,
       _client = client ?? SyncApiClient(),
       _download = download ?? MeasurementDownloadService() {
    _attachAutoSync();
    // Si la app arranca con una sesión ya restaurada (PatientSession.load() corre
    // antes de construir los providers), no habrá evento de login que dispare el
    // sync: se programa aquí la sincronización inicial (sube pendientes + baja
    // el historial del servidor).
    if (PatientSession.instance.isAuthenticated) {
      _debounce = Timer(autoSyncDebounce, syncNow);
    }
  }

  SyncStatus _status = SyncStatus.idle;
  String? _message;
  DateTime? _lastSyncedAt;

  Timer? _debounce;

  /// Silencia el auto-sync mientras el propio servicio escribe en los repos
  /// ([_markAllSynced] dispara `refresh`→`notifyListeners`), para no reentrar.
  bool _muteAutoSync = false;

  SyncStatus get status => _status;
  String? get message => _message;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  bool get isSyncing => _status == SyncStatus.syncing;

  /// Escucha los 4 repositorios: cuando cambian (guardar/editar un registro),
  /// programa una sincronización con debounce.
  void _attachAutoSync() {
    _anthropometric.addListener(_onRecordsChanged);
    _vitals.addListener(_onRecordsChanged);
    _lipid.addListener(_onRecordsChanged);
    _body.addListener(_onRecordsChanged);
    // Al iniciar sesión se vuelca lo que quedó pendiente de antes de loguearse.
    PatientSession.instance.addListener(_onSessionChanged);
  }

  void _onSessionChanged() {
    if (PatientSession.instance.isAuthenticated) {
      _debounce?.cancel();
      _debounce = Timer(autoSyncDebounce, syncNow);
    }
  }

  /// Reacciona a un cambio en cualquier repositorio (guardar/editar/borrar un
  /// registro). No molesta si no hay sesión (no cambia el estado visible); solo
  /// agenda el sync cuando sí puede correr. Se re-arma incluso si hay una sync en
  /// curso: así un guardado durante la subida no se pierde (el debounce coalesce
  /// y `syncNow` es reentrante-seguro).
  void _onRecordsChanged() {
    if (_muteAutoSync) return;

    final hasPatient =
        PatientSession.instance.isAuthenticated ||
        ApiConfig.patientPublicId.isNotEmpty;
    if (ApiConfig.baseUrl.isEmpty || !hasPatient) return;

    _debounce?.cancel();
    _debounce = Timer(autoSyncDebounce, syncNow);
  }

  /// Sube todo lo pendiente. Reentrante-seguro: si ya hay una sync en curso, no hace nada.
  Future<void> syncNow() async {
    if (_status == SyncStatus.syncing) return;

    final hasPatient =
        PatientSession.instance.isAuthenticated ||
        ApiConfig.patientPublicId.isNotEmpty;
    if (ApiConfig.baseUrl.isEmpty || !hasPatient) {
      _set(
        SyncStatus.notConfigured,
        'Inicia sesión para sincronizar (falta identidad del paciente).',
      );
      return;
    }

    _set(SyncStatus.syncing, 'Sincronizando…');

    // 1. Reunir pendientes y aplanar, recordando qué ids aporta cada repositorio.
    final anthro = await _anthropometric.getUnsynced();
    final vitals = await _vitals.getUnsynced();
    final lipid = await _lipid.getUnsynced();
    final body = await _body.getUnsynced();

    final items = <IngestItem>[
      for (final r in anthro) ...MeasurementMapper.fromAnthropometric(r),
      for (final r in vitals) ...MeasurementMapper.fromVitalSign(r),
      for (final r in lipid) ...MeasurementMapper.fromLipid(r),
      for (final r in body) ...MeasurementMapper.fromBodyComposition(r),
    ];

    final hadRecords =
        anthro.isNotEmpty ||
        vitals.isNotEmpty ||
        lipid.isNotEmpty ||
        body.isNotEmpty;

    if (!hadRecords) {
      // Nada que subir: igual se BAJA el historial del servidor (primer login de
      // un paciente migrado: su historia del legacy aparece en los historiales).
      final pulled = await _pull();
      _lastSyncedAt = DateTime.now();
      _set(
        SyncStatus.success,
        pulled > 0
            ? 'Historial actualizado: $pulled registro(s) descargado(s).'
            : 'Todo al día. No hay datos nuevos.',
      );
      return;
    }

    try {
      // 2. Subir (si hay algún item; un registro sin campos medidos igual se marca).
      final result = items.isEmpty
          ? const IngestResult(accepted: 0, rejected: 0)
          : await _client.postMeasurements(items);

      // 3. Éxito: marcar sincronizados todos los registros que se intentaron.
      // Silenciado: markSynced dispara refresh→notifyListeners y reentraría el auto-sync.
      _muteAutoSync = true;
      try {
        await _anthropometric.markSynced(anthro.map((r) => r.id));
        await _vitals.markSynced(vitals.map((r) => r.id));
        await _lipid.markSynced(lipid.map((r) => r.id));
        await _body.markSynced(body.map((r) => r.id));
      } finally {
        _muteAutoSync = false;
      }

      // 4. Bajar lo nuevo del servidor (best-effort; no invalida la subida).
      final pulled = await _pull();

      _lastSyncedAt = DateTime.now();
      final rejectedNote = result.rejected > 0
          ? ' (${result.rejected} descartada/s)'
          : '';
      final pulledNote = pulled > 0 ? ' · $pulled descargado(s)' : '';
      _set(
        SyncStatus.success,
        '${result.accepted} medición/es sincronizada/s$rejectedNote$pulledNote.',
      );
    } on SyncException catch (e) {
      _set(SyncStatus.error, 'No se pudo sincronizar: ${e.message}');
    } catch (e) {
      _set(SyncStatus.error, 'Error inesperado al sincronizar: $e');
    }
  }

  /// Baja el historial del servidor hacia la BD local. Best-effort: si la API no
  /// responde devuelve 0 y el sync no falla por eso. Silenciado: los inserts del
  /// import disparan refresh→notify y reentrarían el auto-sync.
  Future<int> _pull() async {
    _muteAutoSync = true;
    try {
      return await _download.importFromServer();
    } catch (e) {
      debugPrint('Sync: descarga del historial no disponible: $e');
      return 0;
    } finally {
      _muteAutoSync = false;
    }
  }

  void _set(SyncStatus status, String message) {
    _status = status;
    _message = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _anthropometric.removeListener(_onRecordsChanged);
    _vitals.removeListener(_onRecordsChanged);
    _lipid.removeListener(_onRecordsChanged);
    _body.removeListener(_onRecordsChanged);
    PatientSession.instance.removeListener(_onSessionChanged);
    _client.close();
    _download.close();
    super.dispose();
  }
}
