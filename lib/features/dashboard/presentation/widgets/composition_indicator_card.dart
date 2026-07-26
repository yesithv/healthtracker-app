import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/utils/health_classifiers.dart';
import 'package:myvitals_healthtracker_app/core/widgets/bmi_status_badge.dart';
import 'package:myvitals_healthtracker_app/core/widgets/dashed_border_container.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

/// Escala de IMC con marcador de posición.
///
/// La barra usa la RAMPA DE SEVERIDAD del tema (bajo → óptimo → atención →
/// alto), no un degradado escrito a mano, y el color del marcador sale del
/// clasificador. Así degradado, marcador e insignia no pueden contradecirse:
/// los tres beben de la misma paleta clínica y de los mismos umbrales.
class CompositionIndicatorCard extends StatelessWidget {
  final double bmi;
  final String status;

  const CompositionIndicatorCard({
    super.key,
    required this.bmi,
    required this.status,
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

    return DashedBorderContainer(
      color: Color.lerp(surfaces.card, surfaces.brand, 0.30)!,
      borderRadius: surfaces.radiusControl,
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
                        boxShadow: [
                          BoxShadow(
                            color: knobColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
