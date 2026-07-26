import 'package:flutter/material.dart';

import 'theme_catalog.dart';

/// Fachada histórica del tema.
///
/// El sistema real vive en [AppThemeCatalog] y en `core/theme/tokens/`. Esta
/// clase se mantiene para que las pantallas que aún no se han migrado sigan
/// compilando: la migración es INCREMENTAL a propósito. Con ~1.160 colores
/// escritos a mano repartidos por la app, un cambio de golpe garantizaba dejar
/// media interfaz sin migrar y con aspecto roto; pantalla por pantalla, cada
/// paso es verificable.
///
/// Al migrar una pantalla, cambia `AppTheme.primaryColor` por el token que
/// corresponda —normalmente `Theme.of(context).surfaces.brand`— y borra el
/// import. Cuando no queden usos, este archivo desaparece.
/// OBSOLETO — no añadas usos nuevos. Sustituto:
/// `Theme.of(context).surfaces` / `.clinical` / `.metrics` / `.type`.
/// (Sin `@Deprecated` a propósito: la anotación dispara un warning en cada uso
/// dentro del propio paquete y `flutter analyze` los trata como fatales, así
/// que marcarla ahora rompería el build por las pantallas aún sin migrar.)
class AppTheme {
  /// Color de marca del tema HISTÓRICO. Ojo: es una constante, no sigue al tema
  /// activo. Cualquier pantalla que lo use se verá igual en todos los temas.
  static const Color primaryColor = Color(0xFF0D48A0);
  static const Color backgroundColor = Color(0xFFF4F6F9);

  /// Tema por defecto, para código que aún pide un [ThemeData] sin contexto.
  static ThemeData get lightTheme =>
      AppThemeCatalog.themeOf(AppThemeCatalog.fallback);
}
