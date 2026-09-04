import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens/clinical_palette.dart';
import '../../../../core/theme/tokens/metric_palette.dart';
import '../../../../core/utils/health_classifiers.dart';
import '../../../../core/providers/health_goals_provider.dart';
import '../../../../core/database/record_repositories.dart';
import '../../../history/data/models/body_composition_record.dart';
import 'dashboard_card.dart';

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
      return DashboardEmptyCard(
        family: MetricFamily.bodyComposition,
        icon: Icons.accessibility_new,
        title: l10n.bodyComposition,
        subtitle: l10n.compositionSubtitle,
        actionText: l10n.completeBodyProfile,
        onAction: () => context.push('/record-body-composition'),
      );
    }

    final latest = list.first;
    final previous = list.length > 1 ? list[1] : null;

    // Valor numérico de un campo en un registro (visceral se sube a double).
    double? numOf(BodyCompositionRecord r, _BodyField f) => switch (f) {
      _BodyField.fat => r.bodyFatPercent,
      _BodyField.muscle => r.muscleMassKg,
      _BodyField.visceral => r.visceralFatLevel?.toDouble(),
      _BodyField.bmr => r.bmrKcal?.toDouble(),
    };

    // Solo grasa y grasa visceral tienen lectura clínica; músculo y TMB son
    // informativos (sin barra de zona), pintados con el color de la familia.
    //
    // Y la grasa solo la tiene **si el servidor mandó bandas para este paciente**:
    // sin báscula elegida no hay rango aplicable, y entonces se pinta como el
    // músculo —el número, sin veredicto— en vez de inventar un color.
    ClinicalStatus? statusOf(_BodyField f, double v) => switch (f) {
      _BodyField.fat => FatCategory.of(v)?.status,
      _BodyField.visceral => VisceralCategory.of(v.toInt()).status,
      _BodyField.muscle => null,
      _BodyField.bmr => null,
    };

    String valueStr(_BodyField f, double v) => switch (f) {
      _BodyField.fat => v.toStringAsFixed(1),
      _BodyField.muscle => v.toStringAsFixed(1),
      _BodyField.visceral => l10n.dashboardCompositionLevel(v.toInt()),
      _BodyField.bmr => v.toStringAsFixed(0),
    };

    String? unitOf(_BodyField f) => switch (f) {
      _BodyField.fat => '%',
      _BodyField.muscle => 'kg',
      _BodyField.visceral => null,
      _BodyField.bmr => 'kcal',
    };

    String labelOf(_BodyField f) => switch (f) {
      _BodyField.fat => l10n.dashboardCompositionFat,
      _BodyField.muscle => l10n.dashboardCompositionMuscle,
      _BodyField.visceral => l10n.dashboardCompositionVisceral,
      _BodyField.bmr => l10n.dashboardCompositionBmr,
    };

    Color colorOf(_BodyField f, double v) {
      final s = statusOf(f, v);
      return s == null ? family.accent : theme.clinical.tone(s).accent;
    }

    List<double> sparkOf(_BodyField f) => [
      for (final r in list.reversed)
        if (numOf(r, f) != null) numOf(r, f)!,
    ];

    // Icono de meta (✓ si cumplida, flecha hacia la dirección buscada). Mismo
    // criterio que antes: cumplir la meta es «óptimo» (verde); aún no llegar es
    // tinta apagada, no el rojo de alerta (no llegar a una meta personal no es
    // un hallazgo clínico).
    Widget? goalIcon(_BodyField f, double v, {required double size}) {
      final (double? target, bool lowerBetter) = switch (f) {
        _BodyField.fat => (goals.targetBodyFat, true),
        _BodyField.muscle => (goals.targetMuscleMass, false),
        _BodyField.visceral => (goals.targetVisceralFat?.toDouble(), true),
        _BodyField.bmr => (null, true),
      };
      if (target == null) return null;
      final achieved = lowerBetter ? v <= target : v >= target;
      return Icon(
        achieved
            ? Icons.check_circle
            : (lowerBetter ? Icons.arrow_downward : Icons.arrow_upward),
        size: size,
        color: achieved
            ? theme.clinical.optimal.accent
            : theme.surfaces.inkMuted,
      );
    }

    final present = [
      for (final f in _BodyField.values)
        if (numOf(latest, f) != null) f,
    ];
    // Un registro sin ninguna métrica (todas nulas) no tiene nada que pintar.
    if (present.isEmpty) return const SizedBox();

    final heroField = present.first;
    final heroValue = numOf(latest, heroField)!;
    final minis = present.skip(1).toList();

    return DashboardCard(
      family: MetricFamily.bodyComposition,
      icon: Icons.accessibility_new,
      title: l10n.bodyComposition,
      measuredAt: latest.date,
      onTap: () => context.push('/history/body-composition'),
      footer: DashboardCardFooterLink(
        family: MetricFamily.bodyComposition,
        label: l10n.dashboardViewHistory,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroMetric(
            value: valueStr(heroField, heroValue),
            unit: unitOf(heroField) ?? '',
            valueColor: colorOf(heroField, heroValue),
            label: labelOf(heroField),
            status: statusOf(heroField, heroValue),
            current: heroValue,
            previous: previous != null ? numOf(previous, heroField) : null,
            deltaDecimals: heroField == _BodyField.fat ? 1 : 0,
            deltaUnit: heroField == _BodyField.fat ? '%' : null,
            spark: sparkOf(heroField),
            sparkColor: family.accent,
            valueTrailing: goalIcon(heroField, heroValue, size: 16),
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
                      final v = numOf(latest, f)!;
                      return MiniMetric(
                        label: labelOf(f),
                        value: valueStr(f, v),
                        unit: unitOf(f),
                        valueColor: colorOf(f, v),
                        status: statusOf(f, v),
                        trailingIcon: goalIcon(f, v, size: 13),
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

/// Los campos de composición corporal que la tarjeta muestra, en orden de
/// prioridad (grasa corporal es el héroe cuando está presente).
enum _BodyField { fat, muscle, visceral, bmr }
