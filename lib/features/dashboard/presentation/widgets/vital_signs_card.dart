import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens/clinical_palette.dart';
import '../../../../core/theme/tokens/metric_palette.dart';
import '../../../../core/utils/health_classifiers.dart';
import '../../../../core/widgets/action_button.dart';
import '../../../../core/widgets/dashed_border_container.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/database/record_repositories.dart';
import 'dashboard_card.dart';
import 'status_ramp.dart';

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
    final previous = list.length > 1 ? list[1] : null;

    final bpCat = BpCategory.of(latest.systolic, latest.diastolic);
    // El ESTADO lo decide el clasificador (rangos del backoffice); el tema sólo
    // resuelve con qué color se dibuja.
    final bpStatus = bpCat.status;
    final bpTone = theme.clinical.tone(bpStatus);
    // El pulso tiene su propia lectura clínica: no hereda el color de la tensión.
    final hrStatus = HrCategory.of(latest.heartRate).status;
    final hrTone = theme.clinical.tone(hrStatus);

    // Serie cronológica (los repositorios entregan más reciente primero).
    final systolicSpark = [for (final r in list.reversed) r.systolic.toDouble()];

    return DashboardCard(
      family: MetricFamily.vitals,
      icon: Icons.favorite,
      title: l10n.vitalSigns,
      measuredAt: latest.date,
      statusChip: StatusChip(status: bpStatus, label: bpCat.label(l10n)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroMetric(
            value: '${latest.systolic}/${latest.diastolic}',
            unit: 'mmHg',
            valueColor: bpTone.accent,
            label: l10n.bloodPressureTitle,
            status: bpStatus,
            current: latest.systolic.toDouble(),
            previous: previous?.systolic.toDouble(),
            spark: systolicSpark,
            sparkColor: family.accent,
          ),
          const SizedBox(height: 16),
          _HeartRateBar(
            label: l10n.heartRateTitle,
            heartRate: latest.heartRate,
            status: hrStatus,
            valueColor: hrTone.accent,
            familyAccent: family.accent,
          ),
        ],
      ),
    );
  }
}

/// Barra secundaria de frecuencia cardíaca: descansa en una superficie hundida
/// del tema, con el icono de la familia, su barra de zona y la cifra en el color
/// de su estado.
class _HeartRateBar extends StatelessWidget {
  const _HeartRateBar({
    required this.label,
    required this.heartRate,
    required this.status,
    required this.valueColor,
    required this.familyAccent,
  });

  final String label;
  final int heartRate;
  final ClinicalStatus status;
  final Color valueColor;
  final Color familyAccent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: surfaces.inset,
        borderRadius: BorderRadius.circular(surfaces.radiusControl),
      ),
      child: Row(
        children: [
          Icon(Icons.favorite, size: 16, color: familyAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.type.meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          StatusRamp(status: status, width: 64),
          const SizedBox(width: 14),
          Text(
            '$heartRate',
            style: theme.type.numeralSmall.copyWith(
              fontSize: 18,
              color: valueColor,
            ),
          ),
          const SizedBox(width: 3),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              'bpm',
              style: theme.type.numeralUnit.copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
