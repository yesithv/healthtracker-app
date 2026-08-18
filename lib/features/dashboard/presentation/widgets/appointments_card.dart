import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Cuadrado de «Citas médicas» en el Dashboard: por ahora es solo un marcador
/// de posición «próximamente», sin módulo detrás. Comparte tamaño con
/// [MedicationsSummaryCard] para formar la fila de dos cuadrados del fondo, pero
/// se dibuja atenuado (borde tenue, sin realce) para leerse como pendiente.
class AppointmentsCard extends StatelessWidget {
  const AppointmentsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: surfaces.card,
        borderRadius: BorderRadius.circular(surfaces.radiusCard),
        border: Border.all(color: surfaces.divider),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_outlined, size: 18, color: surfaces.inkMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.medDashApptsTitle,
                  style: theme.type.sectionLabel
                      .copyWith(color: surfaces.inkSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            l10n.medDashApptsSoon,
            style: theme.type.meta.copyWith(color: surfaces.inkMuted),
          ),
        ],
      ),
    );
  }
}
