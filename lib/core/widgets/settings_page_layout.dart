import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/tone.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/widgets/settings_page_header.dart';

/// LA MAQUETA COMÚN de una pantalla de ajuste: icono redondo, título,
/// descripción, contenido y —si hace falta— un botón de confirmar.
///
/// Vivía dentro de `features/profile`, pero es el template general de la app:
/// cualquier pantalla que presente una decisión al usuario se ve así. Al
/// moverla a `core/widgets` puede usarla también el selector de tema, que no
/// cuelga de Perfil.
class SettingsPageLayout extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget child;
  final VoidCallback onConfirm;
  final bool showConfirmButton;

  /// Texto del botón de confirmar. Por defecto «Guardar preferencias», que es
  /// lo que dicen casi todas; el selector de tema lo cambia porque ahí el botón
  /// no guarda nada —la elección ya se aplicó— sino que sigue adelante.
  final String? confirmLabel;

  /// Acento DE ORIENTACIÓN de la sección, que se pasa tal cual al encabezado
  /// para que el icono lleve el color de la fila que abrió esta pantalla.
  final Tone? accent;

  const SettingsPageLayout({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
    required this.onConfirm,
    this.showConfirmButton = true,
    this.confirmLabel,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // El encabezado (ícono + título + descripción) vive en su propio
          // widget para poder reutilizarlo también en las pantallas hub.
          SettingsPageHeader(
            icon: icon,
            title: title,
            description: description,
            accent: accent,
          ),
          const SizedBox(height: 32),
          child,
          const SizedBox(height: 40),
          if (showConfirmButton) ...[
            ElevatedButton.icon(
              onPressed: onConfirm,
              icon: const Icon(Icons.check_circle_outline, size: 20),
              style: ElevatedButton.styleFrom(
                backgroundColor: surfaces.brand,
                foregroundColor: surfaces.onBrand,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(surfaces.radiusControl),
                ),
                elevation: 0,
              ),
              label: Text(
                confirmLabel ?? l10n.savePreferences,
                style: theme.type.button.copyWith(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}
