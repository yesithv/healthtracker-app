import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import '../../../../core/constants/metric_colors.dart';
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

    if (list.isEmpty) {
      return DashedBorderContainer(
        color: MetricColors.anthropoColor,
        borderRadius: 20,
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: MetricColors.anthropoBg,
              child: const Icon(
                Icons.straighten,
                color: MetricColors.anthropoColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.anthropometricHistory,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.0,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.anthroSubtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
            ActionButton(
              text: l10n.recordFirstMeasure,
              color: MetricColors.anthropoColor,
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

      bmiCard = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          bmiCard,
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isAchieved
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : const Color(0xFF0D48A0).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  isAchieved ? Icons.check_circle : Icons.track_changes,
                  color: isAchieved
                      ? const Color(0xFF10B981)
                      : const Color(0xFF0D48A0),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isAchieved
                        ? l10n.goalAchieved
                        : l10n.goalRemainingWeight(diff.toStringAsFixed(1)),
                    style: TextStyle(
                      color: isAchieved
                          ? const Color(0xFF10B981)
                          : const Color(0xFF0D48A0),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
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
