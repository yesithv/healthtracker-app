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
import '../../../history/data/models/lipid_record.dart';
import 'dashboard_card.dart';

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

    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    // Identidad de la familia «perfil lipídico»: verde azulado en cualquier tema.
    final family = theme.metrics.tone(MetricFamily.lipids);

    if (list.isEmpty) {
      return DashedBorderContainer(
        color: family.accent,
        borderRadius: surfaces.radiusCard,
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: family.surface,
              child: Icon(Icons.bloodtype, color: family.accent),
            ),
            const SizedBox(height: 16),
            Text(l10n.lipidProfile, style: theme.type.cardTitle),
            const SizedBox(height: 4),
            Text(
              l10n.lipidSubtitle,
              textAlign: TextAlign.center,
              style: theme.type.meta,
            ),
            const SizedBox(height: 12),
            Text(l10n.noDataYet, style: theme.type.meta),
            const SizedBox(height: 20),
            ActionButton(
              text: l10n.recordLabResults,
              color: family.accent,
              solid: false,
              onPressed: () => context.push('/record-lipid'),
            ),
          ],
        ),
      );
    }

    final latest = list.first;
    final previous = list.length > 1 ? list[1] : null;
    final overall = overallLipidStatus(latest);

    // Valor de un campo lipídico en un registro dado.
    double? fieldOf(LipidRecord r, _LipidField f) => switch (f) {
      _LipidField.total => r.totalCholesterol,
      _LipidField.ldl => r.ldl,
      _LipidField.hdl => r.hdl,
      _LipidField.trig => r.triglycerides,
    };

    // Estado clínico de un campo (cada uno tiene su propio clasificador).
    ClinicalStatus statusOf(_LipidField f, double v) => switch (f) {
      _LipidField.total => LipidStatus.totalCholesterol(
        v,
        labCode: latest.labCode,
      ).status,
      _LipidField.ldl => LipidStatus.ldl(v, labCode: latest.labCode).status,
      _LipidField.hdl => LipidStatus.hdl(v, labCode: latest.labCode).status,
      _LipidField.trig => LipidStatus.triglycerides(
        v,
        labCode: latest.labCode,
      ).status,
    };

    // Serie cronológica de un campo (nulos fuera).
    List<double> sparkOf(_LipidField f) => [
      for (final r in list.reversed)
        if (fieldOf(r, f) != null) fieldOf(r, f)!,
    ];

    String labelOf(_LipidField f) => switch (f) {
      _LipidField.total => l10n.lipidTotalCholesterol,
      _LipidField.ldl => 'LDL',
      _LipidField.hdl => 'HDL',
      _LipidField.trig => 'TRIGS',
    };

    // Solo los campos presentes, en orden canónico. El primero manda como héroe.
    final present = [
      for (final f in _LipidField.values)
        if (fieldOf(latest, f) != null) f,
    ];

    // Un registro sin ningún valor (todos nulos) no tiene nada que pintar.
    if (present.isEmpty) return const SizedBox();

    final heroField = present.first;
    final heroValue = fieldOf(latest, heroField)!;
    final minis = present.skip(1).toList();

    return DashboardCard(
      family: MetricFamily.lipids,
      icon: Icons.bloodtype,
      title: l10n.lipidProfile,
      measuredAt: latest.date,
      statusChip: StatusChip(
        status: overall.status,
        label: overall.label(l10n),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroMetric(
            value: heroValue.toStringAsFixed(0),
            unit: 'mg/dL',
            valueColor: theme.clinical
                .tone(statusOf(heroField, heroValue))
                .accent,
            label: labelOf(heroField),
            status: statusOf(heroField, heroValue),
            current: heroValue,
            previous: previous != null ? fieldOf(previous, heroField) : null,
            spark: sparkOf(heroField),
            sparkColor: family.accent,
          ),
          if (minis.isNotEmpty) ...[
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 0; i < minis.length; i++) ...[
                  if (i > 0)
                    Container(width: 1, height: 44, color: surfaces.divider),
                  Builder(
                    builder: (_) {
                      final f = minis[i];
                      final v = fieldOf(latest, f)!;
                      final status = statusOf(f, v);
                      return MiniMetric(
                        label: labelOf(f),
                        value: v.toStringAsFixed(0),
                        unit: 'mg/dL',
                        valueColor: theme.clinical.tone(status).accent,
                        status: status,
                      );
                    },
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Los cuatro campos del panel lipídico que la tarjeta muestra, en orden de
/// prioridad (el primero presente es el héroe de la tarjeta).
enum _LipidField { total, ldl, hdl, trig }
