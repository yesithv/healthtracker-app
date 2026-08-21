import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens/clinical_palette.dart';
import '../../../../core/widgets/icon_badge.dart';

/// Aviso de inventario bajo: banda en el tono `caution` del tema con un CTA de
/// recarga. El ámbar sale del contrato clínico, no de un literal, así que se ve
/// coherente en ambos temas.
class LowInventoryBanner extends StatelessWidget {
  const LowInventoryBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final caution = theme.clinical.tone(ClinicalStatus.caution);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: caution.surface,
        borderRadius: BorderRadius.circular(surfaces.radiusCard),
        border: Border.all(color: caution.accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          IconBadge(
            Icons.medication_liquid,
            color: caution.onAccent,
            background: caution.accent,
            size: 40,
            iconSize: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.type.cardTitle.copyWith(
                    fontSize: 15,
                    color: caution.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.type.meta.copyWith(
                    color: caution.accent.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: caution.accent,
            borderRadius: BorderRadius.circular(surfaces.radiusControl),
            child: InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(surfaces.radiusControl),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Text(
                  actionLabel,
                  style: theme.type.button.copyWith(
                    fontSize: 14,
                    color: caution.onAccent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
