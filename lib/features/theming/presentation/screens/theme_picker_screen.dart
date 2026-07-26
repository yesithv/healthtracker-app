import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/theme_catalog.dart';
import '../../../../core/theme/theme_context.dart';
import '../widgets/theme_preview_card.dart';

/// PANTALLA 0 — selector de tema.
///
/// TEMPORAL Y A PROPÓSITO: es el banco de pruebas de la prueba de concepto.
/// Está montada como primera pantalla para poder recorrer el flujo completo
/// (arranque → bienvenida → asistente → panel) con un tema u otro sin
/// reinstalar nada. Su sitio definitivo es Perfil → Preferencias; moverla es
/// borrar la ruta `/` de aquí y añadir una entrada en el perfil, porque la
/// pantalla no sabe nada de por dónde se ha llegado a ella.
///
/// Es también el único lugar de la app, junto al widget raíz, que escucha a
/// [ThemeProvider]: todo lo demás lee el tema por `Theme.of(context)`.
class ThemePickerScreen extends StatelessWidget {
  const ThemePickerScreen({super.key});

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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BANCO DE TEMAS', style: theme.type.sectionLabel),
                  const SizedBox(height: 10),
                  Text('Elige el aspecto', style: theme.type.screenTitle),
                  const SizedBox(height: 10),
                  Text(
                    'Cambia colores y tipografía. La navegación, los iconos y '
                    'el significado de cada color se mantienen intactos.',
                    style: theme.type.body,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                itemCount: AppThemeCatalog.specs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 20),
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
                    // Selecciona explícitamente el tema en curso para dejar
                    // constancia de que el usuario ya eligió, y sigue al
                    // arranque normal.
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
