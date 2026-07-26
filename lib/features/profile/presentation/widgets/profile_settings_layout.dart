import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

class ProfileSettingsLayout extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget child;
  final VoidCallback onConfirm;
  final bool showConfirmButton;

  const ProfileSettingsLayout({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
    required this.onConfirm,
    this.showConfirmButton = true,
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
          // El ICONO es el mismo en todos los temas; sólo cambia su vestido.
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Color.lerp(surfaces.canvas, surfaces.brand, 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(child: Icon(icon, size: 32, color: surfaces.brand)),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.type.screenTitle,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.type.body,
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
                l10n.savePreferences,
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
