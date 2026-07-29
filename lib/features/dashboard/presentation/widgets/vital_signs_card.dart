import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens/metric_palette.dart';
import '../../../../core/utils/health_classifiers.dart';
import '../../../../core/widgets/action_button.dart';
import '../../../../core/widgets/dashed_border_container.dart';
import '../../../../core/widgets/status_chip.dart';
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

    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    // Identidad de la familia «signos vitales»: rojo en cualquier tema.
    final family = theme.metrics.tone(MetricFamily.vitals);

    if (list.isEmpty) {
      return DashedBorderContainer(
        color: family.accent,
        borderRadius: surfaces.radiusCard,
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: family.surface,
              child: Icon(Icons.favorite, color: family.accent),
            ),
            const SizedBox(height: 16),
            Text(l10n.vitalSigns, style: theme.type.cardTitle),
            const SizedBox(height: 4),
            Text(
              l10n.vitalsSubtitle,
              textAlign: TextAlign.center,
              style: theme.type.meta,
            ),
            const SizedBox(height: 12),
            Text(l10n.noDataYet, style: theme.type.meta),
            const SizedBox(height: 20),
            ActionButton(
              text: l10n.recordVitalsAction,
              color: family.accent,
              solid: false,
              onPressed: () => context.push('/record-vital-signs'),
            ),
          ],
        ),
      );
    }

    final latest = list.first;
    final bpCat = BpCategory.of(latest.systolic, latest.diastolic);
    // El ESTADO lo decide el clasificador (rangos del backoffice); el tema sólo
    // resuelve con qué color se dibuja.
    final bpStatus = bpCat.status;
    final bpTone = theme.clinical.tone(bpStatus);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: surfaces.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: family.surface,
                child: Icon(Icons.favorite, color: family.accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(l10n.vitalSigns, style: theme.type.cardTitle),
              ),
              StatusChip(status: bpStatus, label: bpCat.label(l10n)),
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
                color: bpTone.accent,
              ),
              Container(width: 1, height: 50, color: surfaces.divider),
              _VitalTile(
                label: l10n.heartRateTitle,
                value: latest.heartRate.toString(),
                unit: 'bpm',
                // El pulso tiene su propia lectura clínica: no hereda el color
                // de la tensión, se clasifica aparte.
                color: theme.clinical
                    .tone(HrCategory.of(latest.heartRate).status)
                    .accent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ActionButton(
            text: l10n.recordVitalsAction,
            color: family.accent,
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
    final type = Theme.of(context).type;
    return Column(
      children: [
        Text(value, style: type.numeral.copyWith(color: color)),
        Text(unit, style: type.numeralUnit),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: type.meta),
      ],
    );
  }
}
