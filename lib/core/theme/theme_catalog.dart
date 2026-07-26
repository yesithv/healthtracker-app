import 'package:flutter/material.dart';

import 'theme_context.dart';
import 'themes/consulta_serena.dart';
import 'themes/pulso_clinico.dart';

/// Identidad estable de cada tema. El `name` de estos valores es lo que se
/// persiste en disco, así que RENOMBRAR una constante rompe la preferencia
/// guardada de los usuarios: añadir sí, renombrar no.
enum AppThemeId {
  pulsoClinico,
  consultaSerena;

  static AppThemeId? tryParse(String? raw) {
    if (raw == null) return null;
    for (final id in AppThemeId.values) {
      if (id.name == raw) return id;
    }
    return null;
  }
}

/// Ficha de un tema: su identidad, cómo se presenta al usuario y cómo se
/// construye.
@immutable
class AppThemeSpec {
  const AppThemeSpec({
    required this.id,
    required this.name,
    required this.tagline,
    required this.typeNote,
  });

  final AppThemeId id;

  /// Nombre visible. Es un nombre propio: no se traduce.
  final String name;

  /// Una frase sobre su carácter, para que elegir no sea adivinar.
  final String tagline;

  /// Cómo está construido su sistema tipográfico, en lenguaje humano.
  final String typeNote;

  ThemeData get theme => AppThemeCatalog.themeOf(id);
}

/// Registro de los temas disponibles.
///
/// Cada [ThemeData] se construye UNA vez y se memoiza. No es una optimización
/// prematura: `ColorScheme.fromSeed` deriva la rampa tonal con aritmética en
/// espacio HCT, y rehacerla en cada `build` del widget raíz sería gastar
/// milisegundos por frame para obtener siempre el mismo objeto. Memoizado, el
/// cambio de tema es una lectura de mapa más un repintado.
class AppThemeCatalog {
  const AppThemeCatalog._();

  /// El tema con el que arranca quien nunca ha elegido. Es el histórico: una
  /// actualización de la app no debe cambiarle el aspecto a nadie por su cuenta.
  static const AppThemeId fallback = AppThemeId.pulsoClinico;

  static const List<AppThemeSpec> specs = [
    AppThemeSpec(
      id: AppThemeId.pulsoClinico,
      name: 'Pulso Clínico',
      tagline: 'Azul hospitalario, tarjetas que flotan, cifras rotundas.',
      typeNote: 'Inter · 400 a 700 · jerarquía por peso',
    ),
    AppThemeSpec(
      id: AppThemeId.consultaSerena,
      name: 'Consulta Serena',
      tagline: 'Lienzo cálido, tarjetas planas, cifras en serif.',
      typeNote: 'Newsreader · IBM Plex Sans · IBM Plex Mono',
    ),
  ];

  static final Map<AppThemeId, ThemeData> _cache = {};

  static AppThemeSpec specOf(AppThemeId id) =>
      specs.firstWhere((s) => s.id == id);

  static ThemeData themeOf(AppThemeId id) {
    return _cache[id] ??= switch (id) {
      AppThemeId.pulsoClinico => PulsoClinico.build(),
      AppThemeId.consultaSerena => ConsultaSerena.build(),
    };
  }

  /// Muestrario de color de un tema, derivado de sus PROPIOS tokens.
  ///
  /// Se lee del tema en vez de mantener una lista de hexadecimales al lado:
  /// así el resumen visual del selector no puede desincronizarse de lo que el
  /// tema realmente pinta. Si mañana cambia un token, la ficha cambia con él.
  static List<({String label, Color color})> swatchesOf(AppThemeId id) {
    final t = themeOf(id);
    final s = t.surfaces;
    final c = t.clinical;
    return [
      (label: 'Marca', color: s.brand),
      (label: 'Lienzo', color: s.canvas),
      (label: 'Tarjeta', color: s.card),
      (label: 'Tinta', color: s.ink),
      (label: 'Óptimo', color: c.optimal.accent),
      (label: 'Atención', color: c.caution.accent),
      (label: 'Alto', color: c.alert.accent),
      (label: 'Bajo', color: c.info.accent),
    ];
  }
}
