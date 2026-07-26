import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/theme_catalog.dart';

/// Preferencia de tema del usuario.
///
/// Deliberadamente minúsculo: guarda un enum y nada más. Ese es el punto —
/// cuanto menos estado tenga, menos widgets se suscriben y menos se reconstruye
/// al cambiar de tema.
///
/// REGLA DE USO: las pantallas NO deben escuchar este provider. El tema activo
/// se lee siempre con `Theme.of(context)` (o los atajos de `theme_context.dart`),
/// que propaga el cambio por el `InheritedWidget` del propio Flutter. El único
/// oyente legítimo es el widget raíz, que alimenta `MaterialApp.theme`, más el
/// selector de temas, que necesita marcar la opción activa. Si una pantalla
/// hiciera `watch` aquí, se reconstruiría entera sin necesidad.
class ThemeProvider extends ChangeNotifier {
  static const String _prefsKey = 'app_theme_id';

  ThemeProvider._(this._themeId, this._hasChosen);

  AppThemeId _themeId;
  bool _hasChosen;

  AppThemeId get themeId => _themeId;

  /// `true` si el usuario ya eligió un tema alguna vez. Permite que el selector
  /// se muestre sólo la primera vez sin necesidad de otra bandera aparte.
  bool get hasChosen => _hasChosen;

  ThemeData get theme => AppThemeCatalog.themeOf(_themeId);

  AppThemeSpec get spec => AppThemeCatalog.specOf(_themeId);

  /// Lee la preferencia ANTES de `runApp`.
  ///
  /// Cargarla de forma perezosa haría que el primer frame saliera con el tema
  /// por defecto y cambiara un instante después: un destello visible en cada
  /// arranque. Son unos milisegundos de lectura de `SharedPreferences` a cambio
  /// de que la app aparezca ya vestida.
  static Future<ThemeProvider> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      final parsed = AppThemeId.tryParse(raw);
      return ThemeProvider._(
        parsed ?? AppThemeCatalog.fallback,
        parsed != null,
      );
    } catch (e) {
      debugPrint('No se pudo leer la preferencia de tema: $e');
      return ThemeProvider._(AppThemeCatalog.fallback, false);
    }
  }

  /// Constructor para tests y para arranques donde no interesa el disco.
  @visibleForTesting
  factory ThemeProvider.forTest({
    AppThemeId id = AppThemeCatalog.fallback,
    bool hasChosen = false,
  }) => ThemeProvider._(id, hasChosen);

  Future<void> select(AppThemeId id) async {
    // Elegir el tema que ya estaba activo sigue contando como elección: es lo
    // que permite salir del selector la primera vez sin cambiar nada.
    final changed = id != _themeId || !_hasChosen;
    _themeId = id;
    _hasChosen = true;
    if (changed) notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, id.name);
    } catch (e) {
      // La preferencia no sobrevivirá al reinicio, pero la sesión actual sí
      // respeta la elección: degradar es mejor que fallar.
      debugPrint('No se pudo guardar la preferencia de tema: $e');
    }
  }
}
