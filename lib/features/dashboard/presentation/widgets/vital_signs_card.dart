import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import '../../../../core/constants/metric_colors.dart';
import '../../../../core/utils/health_classifiers.dart';
import '../../../../core/widgets/action_button.dart';
import '../../../../core/widgets/dashed_border_container.dart';
import '../../../../core/database/record_repositories.dart';

/// Dashboard card summarizing the latest blood-pressure / heart-rate reading.
/// Reads the cached, reactive list from [VitalSignsRepository].
class VitalSignsCard extends StatelessWidget {
  const VitalSignsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = context.watch<VitalSignsRepository>();
    if (!repo.isLoaded) return const SizedBox();
    final list = repo.items;

    if (list.isEmpty) {
      return DashedBorderContainer(
        color: MetricColors.vitalsColor,
        borderRadius: 20,
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: MetricColors.vitalsBg,
              child: Icon(Icons.favorite, color: MetricColors.vitalsColor),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.vitalSigns,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.0,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.vitalsSubtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noDataYet,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
            ActionButton(
              text: l10n.recordVitalsAction,
              color: MetricColors.vitalsColor,
              solid: false,
              onPressed: () => context.push('/record-vital-signs'),
            ),
          ],
        ),
      );
    }

    final latest = list.first;
    final bpCat = BpCategory.of(latest.systolic, latest.diastolic);
    final bpColor = bpCat.color;
    final bpLabel = bpCat.label(l10n);

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
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: MetricColors.vitalsBg,
                child: Icon(
                  Icons.favorite,
                  color: MetricColors.vitalsColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.vitalSigns,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.0,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: bpColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  bpLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _VitalTile(
                label: l10n.bloodPressureTitle,
                value: '${latest.systolic}/${latest.diastolic}',
                unit: 'mmHg',
                color: bpColor,
              ),
              Container(
                width: 1,
                height: 50,
                color: const Color(0xFFE2E8F0),
              ),
              _VitalTile(
                label: l10n.heartRateTitle,
                value: latest.heartRate.toString(),
                unit: 'bpm',
                color: MetricColors.vitalsColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ActionButton(
            text: l10n.recordVitalsAction,
            color: MetricColors.vitalsColor,
            solid: false,
            onPressed: () => context.push('/record-vital-signs'),
          ),
        ],
      ),
    );
  }
}

class _VitalTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _VitalTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
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
