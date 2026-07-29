import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens/metric_palette.dart';
import '../../../../core/utils/health_classifiers.dart';
import '../../../../core/widgets/action_button.dart';
import '../../../../core/widgets/dashed_border_container.dart';
import '../../../../core/providers/health_goals_provider.dart';
import '../../../../core/database/record_repositories.dart';
import 'composition_indicator_card.dart';

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
      return DashedBorderContainer(
        color: family.accent,
        borderRadius: surfaces.radiusCard,
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: family.surface,
              child: Icon(Icons.straighten, color: family.accent),
            ),
            const SizedBox(height: 16),
            Text(l10n.anthropometricHistory, style: theme.type.cardTitle),
            const SizedBox(height: 4),
            Text(
              l10n.anthroSubtitle,
              textAlign: TextAlign.center,
              style: theme.type.meta,
            ),
            const SizedBox(height: 20),
            ActionButton(
              text: l10n.recordFirstMeasure,
              color: family.accent,
              solid: false,
              onPressed: () => context.push('/record-anthropometric'),
            ),
          ],
        ),
      );
    }

    final latestRecord = list.first;

    Widget bmiCard = CompositionIndicatorCard(
      bmi: latestRecord.bmi,
      status: BmiCategory.of(latestRecord.bmi).label(l10n),
    );

    if (goals.targetWeight != null) {
      final diff = (latestRecord.weight - goals.targetWeight!).abs();
      final isAchieved = diff <= 0.5;

      // Objetivo cumplido = «óptimo» (verde semántico); en curso = color de
      // marca, porque es informativo y no una valoración clínica.
      final Color goalColor = isAchieved
          ? theme.clinical.optimal.accent
          : surfaces.brand;

      bmiCard = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          bmiCard,
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
        ],
      );
    }

    return bmiCard;
  }
}
