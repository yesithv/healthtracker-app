import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/utils/health_classifiers.dart';
import 'package:myvitals_healthtracker_app/core/widgets/bmi_status_badge.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'metric_delta.dart';
import 'metric_sparkline.dart';

/// Escala de IMC con marcador de posición.
///
/// La barra usa la RAMPA DE SEVERIDAD del tema (bajo → óptimo → atención →
/// alto), no un degradado escrito a mano, y el color del marcador sale del
/// clasificador. Así degradado, marcador e insignia no pueden contradecirse:
/// los tres beben de la misma paleta clínica y de los mismos umbrales.
///
/// Encima de la escala se muestra el IMC vigente como cifra protagonista (en el
/// color de su estado, igual que el marcador), el peso de la última medición y
/// —a la derecha— la variación respecto a la lectura previa sobre una
/// mini‑gráfica de tendencia del IMC.
class CompositionIndicatorCard extends StatelessWidget {
  final double bmi;
  final String status;

  /// IMC de la medición anterior, para el delta. `null` la primera vez.
  final double? bmiPrevious;

  /// Peso de la última medición y su unidad, para la línea de contexto.
  final double? weight;
  final String weightUnit;

  /// Serie cronológica de IMC para la sparkline (acento [seriesColor]).
  final List<double> bmiSpark;
  final Color? seriesColor;

  const CompositionIndicatorCard({
    super.key,
    required this.bmi,
    required this.status,
    this.bmiPrevious,
    this.weight,
    this.weightUnit = 'kg',
    this.bmiSpark = const [],
    this.seriesColor,
  });

  /// Extremos de la escala visible. Fuera de ellos el marcador se ancla al
  /// borde: la barra es una ayuda de lectura, no un eje de medida.
  static const double _min = 15;
  static const double _max = 35;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final clinical = theme.clinical;

    final percent = ((bmi - _min) / (_max - _min)).clamp(0.0, 1.0);
    final knobColor = clinical.tone(BmiCategory.of(bmi).status).accent;

    return Container(
      // Antes un filete punteado; ahora un borde sólido y continuo, igual que el
      // resto de tarjetas del inicio, para que se lea como el marco de la card.
      decoration: surfaces.cardDecoration(
        borderColor: surfaces.divider,
        borderWidth: 1.5,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.historyBmiTrend.toUpperCase(),
                    style: theme.type.sectionLabel.copyWith(
                      color: surfaces.brand,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                BmiStatusBadge(bmi: bmi, label: status),
              ],
            ),
            const SizedBox(height: 14),
            Row(
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
                          Text(
                            bmi.toStringAsFixed(1),
                            style: theme.type.numeral.copyWith(color: knobColor),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: MetricDelta(
                              current: bmi,
                              previous: bmiPrevious,
                              decimals: 1,
                            ),
                          ),
                        ],
                      ),
                      if (weight != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${l10n.weightLabel} · '
                          '${weight!.toStringAsFixed(1)} $weightUnit',
                          style: theme.type.meta,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                MetricSparkline(
                  values: bmiSpark,
                  color: seriesColor ?? surfaces.brand,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(colors: clinical.severityRamp),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: -6,
                  child: FractionalTranslation(
                    translation: Offset(percent - 0.5, 0),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: surfaces.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: knobColor, width: 3),
                        boxShadow: surfaces.glow(
                          knobColor,
                          alpha: 0.3,
                          blur: 6,
                          offset: const Offset(0, 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _label(context, l10n.bmiLow, clinical.info.accent),
                _label(context, l10n.bmiNormal, clinical.optimal.accent),
                _label(context, l10n.bmiOverweight, clinical.caution.accent),
                _label(context, l10n.bmiObesity, clinical.alert.accent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text, Color color) => Flexible(
    child: Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).type.meta.copyWith(fontSize: 10, color: color),
    ),
  );
}
