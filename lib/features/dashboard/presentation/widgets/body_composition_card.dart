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

/// Dashboard card summarizing the latest body-composition reading.
/// Reads the cached, reactive list from [BodyCompositionRepository].
class BodyCompositionCard extends StatelessWidget {
  const BodyCompositionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final goals = Provider.of<HealthGoalsProvider>(context);
    final repo = context.watch<BodyCompositionRepository>();
    if (!repo.isLoaded) return const SizedBox();
    final list = repo.items;

    if (list.isEmpty) {
      return DashedBorderContainer(
        color: MetricColors.compositionColor,
        borderRadius: 20,
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: MetricColors.compositionBg,
              child: const Icon(
                Icons.accessibility_new,
                color: MetricColors.compositionColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.bodyComposition,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.0,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.compositionSubtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noDataYet,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
            ActionButton(
              text: l10n.completeBodyProfile,
              color: MetricColors.compositionColor,
              solid: false,
              onPressed: () => context.push('/record-body-composition'),
            ),
          ],
        ),
      );
    }

    final latest = list.first;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: MetricColors.compositionBg,
                child: const Icon(
                  Icons.accessibility_new,
                  color: MetricColors.compositionColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.bodyComposition,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.0,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Values row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (latest.bodyFatPercent != null)
                _CompositionTile(
                  label: l10n.dashboardCompositionFat,
                  value: '${latest.bodyFatPercent!.toStringAsFixed(1)}%',
                  color: MetricColors.compositionColor,
                  target: goals.targetBodyFat,
                  currentVal: latest.bodyFatPercent,
                  isLowerBetter: true,
                ),
              if (latest.muscleMassKg != null) ...[
                Container(
                  width: 1,
                  height: 40,
                  color: const Color(0xFFE2E8F0),
                ),
                _CompositionTile(
                  label: l10n.dashboardCompositionMuscle,
                  value: '${latest.muscleMassKg!.toStringAsFixed(1)} kg',
                  color: MetricColors.compositionColor,
                  target: goals.targetMuscleMass,
                  currentVal: latest.muscleMassKg,
                  isLowerBetter: false,
                ),
              ],
              if (latest.visceralFatLevel != null) ...[
                Container(
                  width: 1,
                  height: 40,
                  color: const Color(0xFFE2E8F0),
                ),
                _CompositionTile(
                  label: l10n.dashboardCompositionVisceral,
                  value: l10n.dashboardCompositionLevel(
                    latest.visceralFatLevel!,
                  ),
                  color: VisceralCategory.of(latest.visceralFatLevel!).color,
                  target: goals.targetVisceralFat?.toDouble(),
                  currentVal: latest.visceralFatLevel!.toDouble(),
                  isLowerBetter: true,
                ),
              ],
              if (latest.bmrKcal != null) ...[
                Container(
                  width: 1,
                  height: 40,
                  color: const Color(0xFFE2E8F0),
                ),
                _CompositionTile(
                  label: l10n.dashboardCompositionBmr,
                  value: '${latest.bmrKcal} kcal',
                  color: MetricColors.compositionColor,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          ActionButton(
            text: l10n.completeBodyProfile,
            color: MetricColors.compositionColor,
            solid: false,
            onPressed: () => context.push('/record-body-composition'),
          ),
        ],
      ),
    );
  }
}

class _CompositionTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double? target;
  final double? currentVal;
  final bool isLowerBetter;

  const _CompositionTile({
    required this.label,
    required this.value,
    required this.color,
    this.target,
    this.currentVal,
    this.isLowerBetter = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget titleWidget = Text(
      value,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );

    if (target != null && currentVal != null) {
      final isAchieved = isLowerBetter
          ? (currentVal! <= target!)
          : (currentVal! >= target!);

      titleWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          titleWidget,
          const SizedBox(width: 4),
          Icon(
            isAchieved
                ? Icons.check_circle
                : (isLowerBetter ? Icons.arrow_downward : Icons.arrow_upward),
            size: 12,
            color: isAchieved
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
          ),
        ],
      );
    }

    return Column(
      children: [
        titleWidget,
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
