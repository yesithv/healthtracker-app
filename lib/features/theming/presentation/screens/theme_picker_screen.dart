import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/theme_catalog.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/secondary_app_bar.dart';
import '../../../../core/widgets/settings_page_layout.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../widgets/theme_preview_card.dart';

/// Desde dónde se ha abierto el selector. Cambia el remate de la pantalla, no
/// su contenido: el listado de temas es exactamente el mismo en ambos casos.
enum ThemePickerMode {
  /// Pantalla 0 del arranque: sin vuelta atrás, y un CTA que sigue al splash.
  onboarding,

  /// Perfil → Tema de la app: con vuelta atrás y sin CTA, porque la elección
  /// ya se aplica y se guarda en el momento de tocar la ficha.
  settings,
}

/// Selector de tema.
///
/// UNA sola pantalla para los dos sitios donde aparece —el arranque y Perfil—,
/// que es justo lo que pedía reciclarla: el muestrario, la persistencia y el
/// comportamiento viven en un único lugar, y [ThemePickerMode] solo decide si
/// se remata con un CTA o con una flecha de volver.
///
/// Usa [SettingsPageLayout], la MISMA maqueta que «Recordatorios», «Idioma» o
/// «Privacidad»: icono redondo, título, descripción y contenido. Antes tenía
/// una cabecera propia —un rótulo pequeño arriba y el título a la izquierda—,
/// así que era la única pantalla de ajuste de la app que no se parecía a las
/// demás.
///
/// El listado se construye desde [AppThemeCatalog.specs], así que un tema nuevo
/// aparece aquí sin tocar esta pantalla.
///
/// Es también el único lugar de la app, junto al widget raíz, que escucha a
/// [ThemeProvider]: todo lo demás lee el tema por `Theme.of(context)`.
class ThemePickerScreen extends StatelessWidget {
  const ThemePickerScreen({super.key, required this.mode});

  final ThemePickerMode mode;

  bool get _isSettings => mode == ThemePickerMode.settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // `watch` es correcto aquí: al elegir, esta pantalla debe repintar la marca
    // de selección al instante.
    final themeProvider = context.watch<ThemeProvider>();
    final surfaces = Theme.of(context).surfaces;

    return Scaffold(
      backgroundColor: surfaces.canvas,
      body: SafeArea(
        // La cabecera de ajustes trae su propio SafeArea.
        top: !_isSettings,
        child: Column(
          children: [
            // En Perfil se entra desde una fila, así que lleva la cabecera de
            // la app con su flecha; en la pantalla 0 no hay a dónde volver.
            if (_isSettings) const SecondaryAppBar(),
            Expanded(
              child: SingleChildScrollView(
                child: SettingsPageLayout(
                  icon: Icons.palette_outlined,
                  title: _isSettings
                      ? l10n.profileAppTheme
                      : l10n.themePickTitle,
                  description: _isSettings
                      ? l10n.themeSettingsBody
                      : l10n.themePickBody,
                  // En Perfil no hay botón: la elección ya quedó guardada al
                  // tocar la ficha, y añadir un «guardar» sugeriría que sin él
                  // no se aplica.
                  showConfirmButton: !_isSettings,
                  confirmLabel: l10n.themeContinueWith(themeProvider.spec.name),
                  onConfirm: () {
                    // Deja constancia de que el usuario ya eligió, aunque no
                    // haya tocado ninguna ficha, y sigue al arranque normal.
                    themeProvider.select(themeProvider.themeId);
                    context.go('/splash');
                  },
                  child: Column(
                    children: [
                      for (final spec in AppThemeCatalog.specs) ...[
                        ThemePreviewCard(
                          spec: spec,
                          isSelected: spec.id == themeProvider.themeId,
                          // Aplica al instante: el usuario ve el cambio en la
                          // propia pantalla —cabecera y textos incluidos— antes
                          // de continuar.
                          onSelect: () => themeProvider.select(spec.id),
                        ),
                        if (spec != AppThemeCatalog.specs.last)
                          const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
