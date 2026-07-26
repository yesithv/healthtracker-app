import 'package:flutter/material.dart';

import 'tokens/app_surfaces.dart';
import 'tokens/app_typography.dart';
import 'tokens/clinical_palette.dart';
import 'tokens/metric_palette.dart';

Never _missing(String name) {
  throw FlutterError(
    'Falta la extensión de tema $name.\n'
    'Toda ThemeData de la app debe construirse desde AppThemeCatalog para que '
    'los tokens estén instalados. Si estás en un test, envuelve el widget con '
    'MaterialApp(theme: AppThemeCatalog.themeOf(AppThemeId.pulsoClinico)).',
  );
}

/// Acceso a los tokens del tema desde un [ThemeData].
///
/// Cada getter es una búsqueda en el mapa de extensiones del tema —O(1), sin
/// reconstrucción y sin suscripción a ningún provider—, así que llamarlos en
/// pleno `build` no tiene coste medible.
extension AppThemeTokens on ThemeData {
  AppSurfaces get surfaces =>
      extension<AppSurfaces>() ?? _missing('AppSurfaces');

  ClinicalPalette get clinical =>
      extension<ClinicalPalette>() ?? _missing('ClinicalPalette');

  MetricPalette get metrics =>
      extension<MetricPalette>() ?? _missing('MetricPalette');

  AppTypography get type =>
      extension<AppTypography>() ?? _missing('AppTypography');
}

/// Atajos sobre el contexto, para que una pantalla escriba
/// `context.surfaces.card` en lugar de `Theme.of(context).surfaces.card`.
///
/// Ojo: cada getter llama a [Theme.of], que suscribe el widget a los cambios de
/// tema. Eso es exactamente lo que queremos (así el cambio de tema repinta),
/// pero conviene resolverlo UNA vez al principio del `build` y reutilizar la
/// variable local, no llamarlo veinte veces en el mismo árbol.
extension AppThemeContext on BuildContext {
  AppSurfaces get surfaces => Theme.of(this).surfaces;
  ClinicalPalette get clinical => Theme.of(this).clinical;
  MetricPalette get metrics => Theme.of(this).metrics;
  AppTypography get type => Theme.of(this).type;
}
