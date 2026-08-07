import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/metric_palette.dart';
import 'package:myvitals_healthtracker_app/core/widgets/icon_badge.dart';
import 'package:myvitals_healthtracker_app/core/widgets/main_app_bar.dart';
import 'package:myvitals_healthtracker_app/features/history/presentation/widgets/consolidated_export_button.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final surfaces = Theme.of(context).surfaces;

    return Scaffold(
      backgroundColor: surfaces.canvas,
      body: Column(
        children: [
          MainAppBar(title: l10n.history.toUpperCase()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              children: [
                // Exportación CONSOLIDADA: un único PDF con los cuatro
                // indicadores para el médico. Va arriba, como acción primaria
                // sobre la lista de módulos (cada uno con su propio export).
                const ConsolidatedExportButton(),
                const SizedBox(height: 20),
                // Menu items matching Profile _MenuTile style
                _HistoryMenuTile(
                  icon: Icons.straighten,
                  title: l10n.anthropometry,
                  family: MetricFamily.anthropometry,
                  onTap: () => context.push('/history/anthropometry'),
                ),
                _HistoryMenuTile(
                  icon: Icons.favorite,
                  title: l10n.vitalSigns,
                  family: MetricFamily.vitals,
                  onTap: () => context.push('/history/vital-signs'),
                ),
                _HistoryMenuTile(
                  icon: Icons.bloodtype,
                  title: l10n.lipidProfile,
                  family: MetricFamily.lipids,
                  onTap: () => context.push('/history/lipid'),
                ),
                _HistoryMenuTile(
                  icon: Icons.accessibility_new,
                  title: l10n.bodyComposition,
                  family: MetricFamily.bodyComposition,
                  onTap: () => context.push('/history/body-composition'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;

  /// Familia del indicador. La fila pide la IDENTIDAD y el tema resuelve el
  /// color, igual que en la hoja de registro.
  final MetricFamily family;
  final VoidCallback? onTap;

  const _HistoryMenuTile({
    required this.icon,
    required this.title,
    required this.family,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final tone = theme.metrics.tone(family);
    final radius = surfaces.radiusCard;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: surfaces.selection,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                IconBadge(
                  icon,
                  color: tone.accent,
                  background: tone.accent.withValues(alpha: 0.1),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: theme.type.cardTitle.copyWith(
                      fontSize: 15,
                      color: surfaces.brand,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: surfaces.brand, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
