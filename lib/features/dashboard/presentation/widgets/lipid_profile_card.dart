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
    final overall = overallLipidStatus(latest);

    // Separador vertical entre lecturas, con el filete del tema.
    Widget divider() =>
        Container(width: 1, height: 40, color: surfaces.divider);

    // Se compone la fila de lecturas en una lista para intercalar separadores
    // sólo entre las que existen: antes, cada `if` añadía su propio separador y
    // un panel que empezara por HDL abría con una línea suelta.
    final tiles = <Widget>[
      if (latest.totalCholesterol != null)
        _LipidTile(
          label: l10n.lipidTotalCholesterol,
          value: latest.totalCholesterol!.toStringAsFixed(0),
          status: LipidStatus.totalCholesterol(
            latest.totalCholesterol!,
            labCode: latest.labCode,
          ).status,
        ),
      if (latest.ldl != null)
        _LipidTile(
          label: 'LDL',
          value: latest.ldl!.toStringAsFixed(0),
          status: LipidStatus.ldl(latest.ldl!, labCode: latest.labCode).status,
        ),
      if (latest.hdl != null)
        _LipidTile(
          label: 'HDL',
          value: latest.hdl!.toStringAsFixed(0),
          status: LipidStatus.hdl(latest.hdl!, labCode: latest.labCode).status,
        ),
      if (latest.triglycerides != null)
        _LipidTile(
          label: 'TRIGS',
          value: latest.triglycerides!.toStringAsFixed(0),
          status: LipidStatus.triglycerides(
            latest.triglycerides!,
            labCode: latest.labCode,
          ).status,
        ),
    ];

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
                child: Icon(Icons.bloodtype, color: family.accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(l10n.lipidProfile, style: theme.type.cardTitle),
              ),
              StatusChip(status: overall.status, label: overall.label(l10n)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) divider(),
                tiles[i],
              ],
            ],
          ),
          const SizedBox(height: 16),
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
}

class _LipidTile extends StatelessWidget {
  final String label;
  final String value;
  final ClinicalStatus status;

  const _LipidTile({
    required this.label,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.type.numeralSmall.copyWith(
            fontSize: 20,
            color: theme.clinical.tone(status).accent,
          ),
        ),
        Text('mg/dL', style: theme.type.numeralUnit.copyWith(fontSize: 9)),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.type.meta.copyWith(fontSize: 9),
        ),
      ],
    );
  }
}
