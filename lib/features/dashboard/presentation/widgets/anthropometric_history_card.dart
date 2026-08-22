import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens/metric_palette.dart';
import '../../../../core/utils/health_classifiers.dart';
import '../../../../core/widgets/bmi_status_badge.dart';
import '../../../../core/providers/health_goals_provider.dart';
import '../../../../core/database/record_repositories.dart';
import 'composition_indicator_card.dart';
import 'dashboard_card.dart';

/// Dashboard card showing the latest BMI and progress toward the weight goal.
/// Reads the cached, reactive list from [AnthropometricRepository].
class AnthropometricHistoryCard extends StatelessWidget {
  const AnthropometricHistoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final goals = Provider.of<HealthGoalsProvider>(context);
    final repo = context.watch<AnthropometricRepository>();
    if (!repo.isLoaded) return const SizedBox();
    final list = repo.items;

    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    // Identidad de la familia «antropometría»: ámbar en cualquier tema.
    final family = theme.metrics.tone(MetricFamily.anthropometry);

    if (list.isEmpty) {
      return DashboardEmptyCard(
        family: MetricFamily.anthropometry,
        icon: Icons.straighten,
        title: l10n.anthropometricHistory,
        subtitle: l10n.anthroSubtitle,
        actionText: l10n.recordFirstMeasure,
        onAction: () => context.push('/record-anthropometric'),
      );
    }

    final latestRecord = list.first;
    final previousRecord = list.length > 1 ? list[1] : null;

    // Contenido incrustado: la escala de IMC sin su marco/cabecera propios
    // (el DashboardCard aporta marco, título e insignia de estado).
    final children = <Widget>[
      CompositionIndicatorCard(
        embedded: true,
        bmi: latestRecord.bmi,
        status: BmiCategory.of(latestRecord.bmi).label(l10n),
        bmiPrevious: previousRecord?.bmi,
        weight: latestRecord.weight,
        bmiSpark: [for (final r in list.reversed) r.bmi],
        seriesColor: family.accent,
      ),
    ];

    if (goals.targetWeight != null) {
      final diff = (latestRecord.weight - goals.targetWeight!).abs();
      final isAchieved = diff <= 0.5;

      // Objetivo cumplido = «óptimo» (verde semántico); en curso = color de
      // marca, porque es informativo y no una valoración clínica.
      final Color goalColor = isAchieved
          ? theme.clinical.optimal.accent
          : surfaces.brand;

      children.addAll([
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Color.lerp(surfaces.card, goalColor, 0.10),
            borderRadius: BorderRadius.circular(surfaces.radiusControl),
          ),
          child: Row(
            children: [
              Icon(
                isAchieved ? Icons.check_circle : Icons.track_changes,
                color: goalColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isAchieved
                      ? l10n.goalAchieved
                      : l10n.goalRemainingWeight(diff.toStringAsFixed(1)),
                  style: theme.type.button.copyWith(color: goalColor),
                ),
              ),
            ],
          ),
        ),
      ]);
    }

    return DashboardCard(
      family: MetricFamily.anthropometry,
      icon: Icons.straighten,
      title: l10n.anthropometricHistory,
      measuredAt: latestRecord.date,
      onTap: () => context.push('/history/anthropometry'),
      statusChip: BmiStatusBadge(
        bmi: latestRecord.bmi,
        label: BmiCategory.of(latestRecord.bmi).label(l10n),
      ),
      footer: DashboardCardFooterLink(
        family: MetricFamily.anthropometry,
        label: l10n.dashboardViewHistory,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
