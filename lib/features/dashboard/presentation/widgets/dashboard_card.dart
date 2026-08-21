import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens/clinical_palette.dart';
import '../../../../core/theme/tokens/metric_palette.dart';
import 'metric_delta.dart';
import 'metric_sparkline.dart';
import 'status_ramp.dart';

/// Andamiaje común de las tarjetas de indicador del inicio.
///
/// Centraliza lo que las cuatro repetían a mano —el contenedor con la decoración
/// de tarjeta del tema y la cabecera (pastilla de icono, título, insignia de
/// estado y fecha de la última medición)— para que cada tarjeta solo aporte su
/// [child] con las lecturas.
class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.family,
    required this.icon,
    required this.title,
    required this.child,
    this.measuredAt,
    this.statusChip,
  });

  /// Familia del indicador: fija la identidad de color de la pastilla del icono.
  final MetricFamily family;
  final IconData icon;
  final String title;

  /// Fecha de la lectura mostrada. Se rotula como «Última medición · DD MMM YYYY».
  final DateTime? measuredAt;

  /// Insignia de estado a la derecha del título (opcional).
  final Widget? statusChip;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      // Filete sólido y visible para que se note el marco de la tarjeta.
      decoration: theme.surfaces.cardDecoration(
        borderColor: theme.surfaces.divider,
        borderWidth: 1.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardCardHeader(
            family: family,
            icon: icon,
            title: title,
            measuredAt: measuredAt,
            statusChip: statusChip,
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

/// Cabecera reutilizable: pastilla de icono + título (+ fecha) + insignia.
class DashboardCardHeader extends StatelessWidget {
  const DashboardCardHeader({
    super.key,
    required this.family,
    required this.icon,
    required this.title,
    this.measuredAt,
    this.statusChip,
  });

  final MetricFamily family;
  final IconData icon;
  final String title;
  final DateTime? measuredAt;
  final Widget? statusChip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tone = theme.metrics.tone(family);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: tone.surface,
          child: Icon(icon, color: tone.accent, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: theme.type.cardTitle),
              if (measuredAt != null) ...[
                const SizedBox(height: 2),
                Text(
                  '${l10n.dashboardLastMeasured} · '
                  '${DateFormat('dd MMM yyyy').format(measuredAt!)}',
                  style: theme.type.meta.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (statusChip != null) ...[const SizedBox(width: 8), statusChip!],
      ],
    );
  }
}

/// Lectura PROTAGONISTA de una tarjeta: cifra grande en su color de estado, con
/// su barra de zona clínica a la izquierda y —a la derecha— el delta respecto a
/// la lectura anterior sobre una mini‑gráfica de tendencia.
class HeroMetric extends StatelessWidget {
  const HeroMetric({
    super.key,
    required this.value,
    required this.unit,
    required this.valueColor,
    required this.label,
    this.status,
    this.current,
    this.previous,
    this.deltaDecimals = 0,
    this.deltaUnit,
    this.spark = const [],
    this.sparkColor,
    this.valueTrailing,
  });

  final String value;
  final String unit;
  final Color valueColor;

  /// Icono opcional junto a la cifra (p. ej. la ✓ de meta cumplida).
  final Widget? valueTrailing;

  /// Rótulo bajo la cifra (p. ej. «Presión arterial»).
  final String label;

  /// Estado clínico para la barra de zona; `null` la oculta (dato informativo).
  final ClinicalStatus? status;

  final double? current;
  final double? previous;
  final int deltaDecimals;
  final String? deltaUnit;

  /// Serie cronológica para la sparkline; su color de familia.
  final List<double> spark;
  final Color? sparkColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.type.numeral.copyWith(color: valueColor),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(unit, style: theme.type.numeralUnit),
                  ),
                  if (valueTrailing != null) ...[
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: valueTrailing,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(label, style: theme.type.meta),
              if (status != null) ...[
                const SizedBox(height: 12),
                StatusRamp(status: status!),
              ],
            ],
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            MetricDelta(
              current: current,
              previous: previous,
              decimals: deltaDecimals,
              unit: deltaUnit,
            ),
            if (spark.length >= 2) ...[
              const SizedBox(height: 6),
              MetricSparkline(
                values: spark,
                color: sparkColor ?? valueColor,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Lectura SECUNDARIA de una tarjeta: cifra mediana en su color, una barra de
/// zona compacta y el rótulo. Es el reemplazo enriquecido de las viejas casillas
/// «cifra + unidad + etiqueta» separadas por filetes.
class MiniMetric extends StatelessWidget {
  const MiniMetric({
    super.key,
    required this.label,
    required this.value,
    required this.valueColor,
    this.unit,
    this.status,
    this.trailingIcon,
  });

  final String label;
  final String value;
  final Color valueColor;

  /// Unidad bajo la cifra (mg/dL, kg…). `null` la omite.
  final String? unit;

  /// Estado clínico para la barra de zona compacta; `null` la oculta.
  final ClinicalStatus? status;

  /// Icono opcional a la derecha de la cifra (p. ej. la ✓ de meta cumplida).
  final Widget? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: theme.type.numeralSmall.copyWith(
                fontSize: 18,
                color: valueColor,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 4),
              trailingIcon!,
            ],
          ],
        ),
        if (unit != null)
          Text(unit!, style: theme.type.numeralUnit.copyWith(fontSize: 9)),
        if (status != null) ...[
          const SizedBox(height: 6),
          StatusRamp(status: status!, width: 44),
        ],
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.type.meta.copyWith(fontSize: 9),
        ),
      ],
    );
  }
}
