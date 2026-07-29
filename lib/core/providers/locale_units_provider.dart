import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/measurement_unit.dart';

/// Owns the app language and measurement-unit preference. Extracted from the
/// former God-object PreferencesProvider so changing the locale/unit only
/// rebuilds the widgets that depend on them (notably the root MaterialApp).
class LocaleUnitsProvider extends ChangeNotifier {
  static const List<String> supportedLanguages = ['en', 'es', 'de', 'pt', 'it'];
  static const String _langKey = 'user_language';
  static const String _unitKey = 'user_measurement_unit';

  Locale _locale = _defaultLocale();
  MeasurementUnit _unit = MeasurementUnit.metric;

  Locale get locale => _locale;
  MeasurementUnit get unit => _unit;

  LocaleUnitsProvider() {
    _load();
  }

  /// Idioma inicial autodetectado del DISPOSITIVO: recorre la lista de idiomas
  /// preferidos del sistema (en orden) y toma el primero que la app soporta; si
  /// ninguno lo está, cae a español (público principal hispanohablante). Solo
  /// aplica cuando el usuario NO ha elegido idioma manualmente (ver [_load]); su
  /// elección en preferencias siempre manda.
  static Locale _defaultLocale() {
    for (final locale in ui.PlatformDispatcher.instance.locales) {
      if (supportedLanguages.contains(locale.languageCode)) {
        return Locale(locale.languageCode);
      }
    }
    return const Locale('es');
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final String? langCode = prefs.getString(_langKey);
    if (langCode != null) {
      _locale = Locale(langCode);
    }

    final String? unitName = prefs.getString(_unitKey);
    if (unitName != null) {
      try {
        _unit = MeasurementUnit.values.byName(unitName);
      } catch (_) {
        _unit = MeasurementUnit.metric;
      }
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (!supportedLanguages.contains(locale.languageCode)) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, locale.languageCode);
  }

  Future<void> setUnit(MeasurementUnit unit) async {
    _unit = unit;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_unitKey, unit.name);
  }

  /// Aplica idioma/unidades por defecto SOLO si el usuario nunca ha elegido
  /// (no pisa una preferencia persistida). Pensado para el login de un paciente
  /// migrado del legacy: español + sistema métrico.
  Future<void> ensureDefaults({
    String? languageCode,
    MeasurementUnit? unit,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    var changed = false;

    if (languageCode != null &&
        prefs.getString(_langKey) == null &&
        supportedLanguages.contains(languageCode)) {
      _locale = Locale(languageCode);
      await prefs.setString(_langKey, languageCode);
      changed = true;
    }
    if (unit != null && prefs.getString(_unitKey) == null) {
      _unit = unit;
      await prefs.setString(_unitKey, unit.name);
      changed = true;
    }
    if (changed) notifyListeners();
  }

  /// Re-reads language/unit from storage (e.g. after a restored backup).
  Future<void> reload() => _load();
}
