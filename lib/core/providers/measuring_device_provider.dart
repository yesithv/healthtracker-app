import 'package:flutter/foundation.dart';
import 'package:myvitals_healthtracker_app/core/diagnostics/debug_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/config/api_config.dart';
import 'package:myvitals_healthtracker_app/core/demo/demo_session.dart';
import 'package:myvitals_healthtracker_app/core/sync/device_api_client.dart';

/// La báscula (bioimpedancia) que usa el paciente. Igual que el resto de la app es
/// LOCAL-FIRST: la elección se guarda al instante en SharedPreferences (para verla offline
/// y responder de inmediato) y se sincroniza best-effort a la API (`PUT /me/device`), que es
/// la que el servidor usa para interpretar las mediciones (`/me/reference-ranges`).
///
/// "Ninguna" es una elección explícita distinta de "aún no elige": lo primero silencia el
/// prompt del onboarding; lo segundo lo dispara.
class MeasuringDeviceProvider extends ChangeNotifier {
  static const _kCode = 'measuring_device_code';
  static const _kName = 'measuring_device_name';
  static const _kChosen = 'measuring_device_chosen';
  static const _kPending = 'measuring_device_pending_sync';

  // Catálogo mínimo de respaldo: permite elegir aunque la API no responda todavía.
  static const List<MeasuringDevice> _fallbackCatalog = [
    MeasuringDevice(
      code: 'OMRON_HBF514C',
      brand: 'Omron',
      model: 'HBF-514C',
      name: 'Omron HBF-514C',
      deviceType: 'BIOIMPEDANCE',
    ),
  ];

  final DeviceApiClient _client;

  List<MeasuringDevice> _catalog = _fallbackCatalog;
  String? _selectedCode;
  String? _selectedName;
  bool _hasChosen = false;
  bool _pendingSync = false;
  bool _loadingCatalog = false;
  String? _catalogError;

  MeasuringDeviceProvider({DeviceApiClient? client})
      : _client = client ?? DeviceApiClient();

  List<MeasuringDevice> get catalog => _catalog;
  String? get selectedCode => _selectedCode;
  String? get selectedName => _selectedName;

  /// El usuario ya tomó una decisión (elegir una báscula o "ninguna").
  bool get hasChosen => _hasChosen;

  /// Debe preguntarse en el onboarding (aún no ha decidido).
  bool get shouldPrompt => !_hasChosen;

  /// Eligió explícitamente "no uso ninguna".
  bool get usesNoDevice => _hasChosen && _selectedCode == null;

  bool get pendingSync => _pendingSync;
  bool get loadingCatalog => _loadingCatalog;
  String? get catalogError => _catalogError;

  /// La demo se excluye a propósito: tiene sesión sembrada, así que sin esto
  /// intentaría traer el catálogo de una API que no existe y la pantalla del
  /// dispositivo saldría en la captura con el aviso de «no se pudo cargar». Sin
  /// red, el catálogo de respaldo ya trae la báscula que la demo usa.
  bool get _canSync =>
      !DemoSession.instance.isActive &&
      (PatientSession.instance.isAuthenticated || ApiConfig.isSyncConfigured);

  /// Carga la elección local y refresca catálogo/selección desde la API (best-effort).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCode = prefs.getString(_kCode);
    _selectedName = prefs.getString(_kName);
    _hasChosen = prefs.getBool(_kChosen) ?? false;
    _pendingSync = prefs.getBool(_kPending) ?? false;
    notifyListeners();
    await refresh();
  }

  /// Refresca el catálogo y reconcilia con el servidor (best-effort; nunca lanza).
  Future<void> refresh() async {
    if (!_canSync) {
      return;
    }
    _loadingCatalog = true;
    _catalogError = null;
    notifyListeners();
    try {
      _catalog = await _client.fetchCatalog();
    } catch (e) {
      _catalogError = e.toString();
      _catalog = _fallbackCatalog; // sigue usable offline
    }

    try {
      if (_pendingSync) {
        // Hay un cambio local sin subir: el local manda, empújalo.
        await _client.setMyDeviceCode(_selectedCode);
        _pendingSync = false;
        await _persist();
      } else {
        // Adopta la selección del servidor solo si tiene valor (NULL es ambiguo:
        // "ninguna" vs "nunca eligió", así que no degradamos el estado local).
        final serverCode = await _client.fetchMyDeviceCode();
        if (serverCode != null) {
          _selectedCode = serverCode;
          _selectedName = _nameFor(serverCode);
          _hasChosen = true;
          await _persist();
        }
      }
    } catch (e) {
      debugLogError('MeasuringDevice.refresh', e);
      // best-effort: sin red seguimos con lo local.
    }

    _loadingCatalog = false;
    notifyListeners();
  }

  /// Fija la báscula del paciente (local + sync best-effort).
  Future<void> select(MeasuringDevice device) async {
    _selectedCode = device.code;
    _selectedName = device.name;
    _hasChosen = true;
    await _applyAndSync(device.code);
  }

  /// El paciente declara que no usa bioimpedancia.
  Future<void> selectNone() async {
    _selectedCode = null;
    _selectedName = null;
    _hasChosen = true;
    await _applyAndSync(null);
  }

  Future<void> _applyAndSync(String? code) async {
    _pendingSync = true; // asume pendiente hasta confirmar
    await _persist();
    notifyListeners();
    if (!_canSync) {
      return;
    }
    try {
      await _client.setMyDeviceCode(code);
      _pendingSync = false;
      await _persist();
      notifyListeners();
    } catch (e) {
      debugLogError('MeasuringDevice.setCode', e);
      // queda pendiente; se reintenta en el próximo refresh().
    }
  }

  String _nameFor(String code) {
    for (final d in _catalog) {
      if (d.code == code) return d.name;
    }
    return _selectedName ?? code;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedCode != null) {
      await prefs.setString(_kCode, _selectedCode!);
    } else {
      await prefs.remove(_kCode);
    }
    if (_selectedName != null) {
      await prefs.setString(_kName, _selectedName!);
    } else {
      await prefs.remove(_kName);
    }
    await prefs.setBool(_kChosen, _hasChosen);
    await prefs.setBool(_kPending, _pendingSync);
  }
}
