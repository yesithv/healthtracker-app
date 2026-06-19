import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/core/widgets/bmi_status_badge.dart';
import 'package:myvitals_healthtracker_app/core/widgets/dashed_border_container.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'dart:math' as math;

class CompositionIndicatorCard extends StatelessWidget {
  final double bmi;
  final String status;

  const CompositionIndicatorCard({
    super.key,
    required this.bmi,
    required this.status,
  });

  Color get _knobColor {
    if (bmi < 18.5) return const Color(0xFF3B82F6);
    if (bmi < 25) return const Color(0xFF10B981);
    if (bmi < 30) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Normalizing BMI for the gradient marker (15 to 35 typical range)
    double percent = (bmi - 15) / (35 - 15);
    percent = math.max(0.0, math.min(1.0, percent));

    final knobColor = _knobColor;

    return DashedBorderContainer(
      color: const Color(0xFF0D48A0).withValues(alpha: 0.3),
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ── Title ──────────────────────────────────────
                Text(
                  l10n.historyBmiTrend,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0D48A0),
                    letterSpacing: 0.8,
                  ),
                ),
                // ── Shared status badge ────────────────────────
                BmiStatusBadge(bmi: bmi, label: status),
              ],
            ),
            const SizedBox(height: 24),
            // ── Gradient bar + knob ──────────────────────────
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF3B82F6), // Bajo
                        Color(0xFF10B981), // Normal
                        Color(0xFFF59E0B), // Sobrepeso
                        Color(0xFFEF4444), // Obesidad
                      ],
                    ),
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
                        color: Colors.white,
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
            // ── Category labels ──────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _label(l10n.bmiLow, const Color(0xFF3B82F6)),
                _label(l10n.bmiNormal, const Color(0xFF10B981)),
                _label(l10n.bmiOverweight, const Color(0xFFF59E0B)),
                _label(l10n.bmiObesity, const Color(0xFFEF4444)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, Color color) => Text(
    text,
    style: TextStyle(
      fontSize: 8,
      fontWeight: FontWeight.bold,
      color: color.withValues(alpha: 0.7),
      letterSpacing: 0.3,
    ),
  );
}
