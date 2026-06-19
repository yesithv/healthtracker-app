import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import '../../../../core/constants/metric_colors.dart';
import '../../../../core/utils/health_classifiers.dart';
import '../../../../core/widgets/action_button.dart';
import '../../../../core/widgets/dashed_border_container.dart';
import '../../../../core/database/record_repositories.dart';

/// Dashboard card summarizing the latest lipid panel.
/// Reads the cached, reactive list from [LipidRepository].
class LipidProfileCard extends StatelessWidget {
  const LipidProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = context.watch<LipidRepository>();
    if (!repo.isLoaded) return const SizedBox();
    final list = repo.items;

    if (list.isEmpty) {
      return DashedBorderContainer(
        color: MetricColors.lipidColor,
        borderRadius: 20,
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: MetricColors.lipidBg,
              child: Icon(Icons.bloodtype, color: MetricColors.lipidColor),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.lipidProfile,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.0,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.lipidSubtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noDataYet,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
            ActionButton(
              text: l10n.recordLabResults,
              color: MetricColors.lipidColor,
              solid: false,
              onPressed: () => context.push('/record-lipid'),
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
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: MetricColors.lipidBg,
                child: Icon(
                  Icons.bloodtype,
                  color: MetricColors.lipidColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.lipidProfile,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.0,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              // Overall risk badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: overallLipidStatus(latest).color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  overallLipidStatus(latest).label(l10n),
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
          // 2-column grid of values
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (latest.totalCholesterol != null)
                _LipidTile(
                  label: l10n.lipidTotalCholesterol,
                  value: latest.totalCholesterol!.toStringAsFixed(0),
                  color: LipidStatus.totalCholesterol(
                    latest.totalCholesterol!,
                  ).color,
                ),
              if (latest.totalCholesterol != null && latest.ldl != null)
                Container(
                  width: 1,
                  height: 40,
                  color: const Color(0xFFE2E8F0),
                ),
              if (latest.ldl != null)
                _LipidTile(
                  label: 'LDL',
                  value: latest.ldl!.toStringAsFixed(0),
                  color: LipidStatus.ldl(latest.ldl!).color,
                ),
              if (latest.hdl != null) ...[
                Container(
                  width: 1,
                  height: 40,
                  color: const Color(0xFFE2E8F0),
                ),
                _LipidTile(
                  label: 'HDL',
                  value: latest.hdl!.toStringAsFixed(0),
                  color: LipidStatus.hdl(latest.hdl!).color,
                ),
              ],
              if (latest.triglycerides != null) ...[
                Container(
                  width: 1,
                  height: 40,
                  color: const Color(0xFFE2E8F0),
                ),
                _LipidTile(
                  label: 'TRIGS',
                  value: latest.triglycerides!.toStringAsFixed(0),
                  color: LipidStatus.triglycerides(
                    latest.triglycerides!,
                  ).color,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          ActionButton(
            text: l10n.recordLabResults,
            color: MetricColors.lipidColor,
            solid: false,
            onPressed: () => context.push('/record-lipid'),
          ),
        ],
      ),
    );
  }
}

class _LipidTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LipidTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          'mg/dL',
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 2),
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
