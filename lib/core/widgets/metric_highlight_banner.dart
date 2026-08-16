import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens/tone.dart';

/// Mensaje destacado que encabeza un panel de historial: un icono en su pastilla,
/// un título y una línea de apoyo, todo teñido con un [Tone].
///
/// Estaba copiado casi igual en los cuatro historiales (`_buildGoodJobBanner`),
/// cada uno con sus verdes o su color de familia escritos a mano. Aquí se pide
/// el SIGNIFICADO en forma de tono —`clinical.optimal` para un «vas bien»,
/// `metrics.tone(familia)` para un encabezado neutro de indicador— y el widget
/// resuelve fondo, filete y tinta emparejados. Así el gesto es idéntico en todo
/// historial y los módulos que aún no lo usan pueden adoptarlo en una línea.
class MetricHighlightBanner extends StatelessWidget {
  const MetricHighlightBanner({
    super.key,
    required this.tone,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  /// Color con carga de significado. El fondo suave, el filete y la tinta salen
  /// todos de él para que nunca vuelvan a descuadrarse entre sí.
  final Tone tone;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: BorderRadius.circular(surfaces.radiusCard),
        border: Border.all(color: tone.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: tone.accent.withValues(alpha: 0.15),
            radius: 18,
            child: Icon(icon, color: tone.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.type.cardTitle.copyWith(
                    fontSize: 16,
                    color: tone.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.type.body.copyWith(
                    fontSize: 13,
                    color: tone.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
