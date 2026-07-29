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

    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    // Identidad de la familia «composición corporal»: índigo en cualquier tema.
    final family = theme.metrics.tone(MetricFamily.bodyComposition);

    if (list.isEmpty) {
      return DashedBorderContainer(
        color: family.accent,
        borderRadius: surfaces.radiusCard,
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: family.surface,
              child: Icon(Icons.accessibility_new, color: family.accent),
            ),
            const SizedBox(height: 16),
            Text(l10n.bodyComposition, style: theme.type.cardTitle),
            const SizedBox(height: 4),
            Text(
              l10n.compositionSubtitle,
              textAlign: TextAlign.center,
              style: theme.type.meta,
            ),
            const SizedBox(height: 12),
            Text(l10n.noDataYet, style: theme.type.meta),
            const SizedBox(height: 20),
            ActionButton(
              text: l10n.completeBodyProfile,
              color: family.accent,
              solid: false,
              onPressed: () => context.push('/record-body-composition'),
            ),
          ],
        ),
      );
    }

    final latest = list.first;

    Widget divider() =>
        Container(width: 1, height: 40, color: surfaces.divider);

    // Igual que en el panel lipídico: los separadores se intercalan sobre la
    // lista ya filtrada, para que una tarjeta sin grasa corporal no abra con una
    // línea vertical suelta.
    final tiles = <Widget>[
      if (latest.bodyFatPercent != null)
        _CompositionTile(
          label: l10n.dashboardCompositionFat,
          value: '${latest.bodyFatPercent!.toStringAsFixed(1)}%',
          color: family.accent,
          target: goals.targetBodyFat,
          currentVal: latest.bodyFatPercent,
          isLowerBetter: true,
        ),
      if (latest.muscleMassKg != null)
        _CompositionTile(
          label: l10n.dashboardCompositionMuscle,
          value: '${latest.muscleMassKg!.toStringAsFixed(1)} kg',
          color: family.accent,
          target: goals.targetMuscleMass,
          currentVal: latest.muscleMassKg,
          isLowerBetter: false,
        ),
      if (latest.visceralFatLevel != null)
        _CompositionTile(
          label: l10n.dashboardCompositionVisceral,
          value: l10n.dashboardCompositionLevel(latest.visceralFatLevel!),
          // La grasa visceral SÍ tiene lectura clínica propia: se pinta con el
          // estado, no con el color de la familia.
          color: theme.clinical
              .tone(VisceralCategory.of(latest.visceralFatLevel!).status)
              .accent,
          target: goals.targetVisceralFat?.toDouble(),
          currentVal: latest.visceralFatLevel!.toDouble(),
          isLowerBetter: true,
        ),
      if (latest.bmrKcal != null)
        _CompositionTile(
          label: l10n.dashboardCompositionBmr,
          value: '${latest.bmrKcal} kcal',
          color: family.accent,
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
                radius: 16,
                backgroundColor: family.surface,
                child: Icon(
                  Icons.accessibility_new,
                  color: family.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(l10n.bodyComposition, style: theme.type.cardTitle),
              ),
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
            text: l10n.completeBodyProfile,
            color: family.accent,
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
    final theme = Theme.of(context);

    Widget titleWidget = Text(
      value,
      style: theme.type.numeralSmall.copyWith(fontSize: 15, color: color),
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
            // Objetivo cumplido → verde «óptimo». Objetivo aún lejos → tinta
            // apagada, NO el rojo de alerta que había antes: no haber llegado a
            // una meta personal no es un hallazgo clínico, y gastar el rojo aquí
            // le quitaba fuerza allí donde sí significa algo. La flecha ya dice
            // en qué dirección hay que moverse.
            color: isAchieved
                ? theme.clinical.optimal.accent
                : theme.surfaces.inkMuted,
          ),
        ],
      );
    }

    return Column(
      children: [
        titleWidget,
        const SizedBox(height: 2),
        Text(label, style: theme.type.meta.copyWith(fontSize: 9)),
      ],
    );
  }
}
