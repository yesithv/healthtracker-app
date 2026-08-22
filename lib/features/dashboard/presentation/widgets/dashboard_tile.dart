import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens/tone.dart';

/// Andamiaje común de las minicards del fondo del Dashboard (Medicamentos y
/// Citas). Centraliza lo que ambas repetían a mano —el board decorado con el
/// filete neutro del tema, el efecto táctil (Material + InkWell recortado al
/// radio de la card) y la cabecera de icono + título— para que cada minicard
/// solo aporte su [child] adaptativo.
///
/// El ripple es el mismo recipe que usan las tarjetas principales: `Material`
/// transparente sobre el `Container` decorado y un `InkWell` con el radio de la
/// card, sin `splashColor` propio (usa la tinta por defecto del tema).
class DashboardTile extends StatelessWidget {
  const DashboardTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.child,
    this.titleColor,
    this.headerTrailing,
  });

  final IconData icon;
  final String title;

  /// Color del icono y el título de la cabecera. Por defecto, el color de marca.
  final Color? titleColor;

  /// Widget opcional al final de la cabecera (p. ej. el punto de semáforo de
  /// Citas).
  final Widget? headerTrailing;

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final tint = titleColor ?? surfaces.brand;

    return Container(
      decoration: surfaces.cardDecoration(
        borderColor: surfaces.divider,
        borderWidth: 1.5,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(surfaces.radiusCard),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            // El alto lo manda el contenido (mainAxisSize.min): la fila lo iguala
            // con su gemela vía IntrinsicHeight.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: tint),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.type.sectionLabel.copyWith(color: tint),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (headerTrailing != null) headerTrailing!,
                  ],
                ),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// CTA compacto para cuando la minicard aún no tiene datos, y así no dejarla
/// vacía. Compartido por Medicamentos y Citas.
class DashboardTileAddContent extends StatelessWidget {
  const DashboardTileAddContent({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Row(
      children: [
        Icon(Icons.add_circle_outline, size: 20, color: surfaces.brand),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.type.cardTitle.copyWith(
              fontSize: 15,
              color: surfaces.brand,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Chip pequeño con icono + texto, teñido con un [Tone] (racha, aviso, «vencida»
/// …). Compartido por Medicamentos y Citas.
class DashboardTileChip extends StatelessWidget {
  const DashboardTileChip({
    super.key,
    required this.icon,
    required this.text,
    required this.tone,
  });

  final IconData icon;
  final String text;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: BorderRadius.circular(surfaces.radiusControl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tone.accent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: theme.type.meta.copyWith(color: tone.accent),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
