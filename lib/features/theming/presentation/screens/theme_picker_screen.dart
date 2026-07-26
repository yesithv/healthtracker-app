import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/theme_catalog.dart';
import '../../../../core/theme/theme_context.dart';
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
    // `watch` es correcto aquí: al elegir, esta pantalla debe repintar la marca
    // de selección al instante.
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return Scaffold(
      backgroundColor: surfaces.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _Header(mode: mode),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(24, 12, 24, _isSettings ? 32 : 24),
                itemCount: AppThemeCatalog.specs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, i) {
                  final spec = AppThemeCatalog.specs[i];
                  return ThemePreviewCard(
                    spec: spec,
                    isSelected: spec.id == themeProvider.themeId,
                    // Aplica al instante: el usuario ve el cambio en la propia
                    // pantalla —cabecera y textos incluidos— antes de continuar.
                    onSelect: () => themeProvider.select(spec.id),
                  );
                },
              ),
            ),
            // En Perfil no hay CTA: la elección ya quedó guardada al tocar la
            // ficha, y añadir un «guardar» sugeriría que sin él no se aplica.
            if (!_isSettings)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: surfaces.brand,
                      foregroundColor: surfaces.onBrand,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          surfaces.radiusControl,
                        ),
                      ),
                    ),
                    onPressed: () {
                      // Deja constancia de que el usuario ya eligió, aunque no
                      // haya tocado ninguna ficha, y sigue al arranque normal.
                      themeProvider.select(themeProvider.themeId);
                      context.go('/splash');
                    },
                    child: Text(
                      'Continuar con ${themeProvider.spec.name}',
                      textAlign: TextAlign.center,
                      style: theme.type.button.copyWith(
                        fontSize: 16,
                        color: surfaces.onBrand,
                      ),
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

class _Header extends StatelessWidget {
  const _Header({required this.mode});

  final ThemePickerMode mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final isSettings = mode == ThemePickerMode.settings;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, isSettings ? 8 : 24, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSettings) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: surfaces.brand,
                ),
                onPressed: () => context.pop(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text('BANCO DE TEMAS', style: theme.type.sectionLabel),
          const SizedBox(height: 10),
          Text(
            isSettings ? 'Tema de la app' : 'Elige el aspecto',
            style: theme.type.screenTitle,
          ),
          const SizedBox(height: 10),
          Text(
            isSettings
                ? 'El cambio se aplica al instante y se recuerda. La navegación, '
                      'los iconos y el significado de cada color se mantienen intactos.'
                : 'Cambia colores y tipografía. La navegación, los iconos y '
                      'el significado de cada color se mantienen intactos.',
            style: theme.type.body,
          ),
        ],
      ),
    );
  }
}
