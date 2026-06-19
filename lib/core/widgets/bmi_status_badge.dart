import 'package:flutter/material.dart';

/// A shared pill-style badge that displays the BMI status category.
/// Automatically derives color, background and icon from the [bmi] value.
/// Use this widget in both the dashboard and the history list so the
/// status always looks identical.
class BmiStatusBadge extends StatelessWidget {
  final double bmi;
  final String label; // Pre-localized text (e.g. l10n.bmiNormal)

  const BmiStatusBadge({super.key, required this.bmi, required this.label});

  ({Color color, Color bgColor, IconData icon}) get _style {
    if (bmi < 18.5) {
      return (
        color: const Color(0xFF3B82F6),
        bgColor: const Color(0xFFEFF6FF),
        icon: Icons.arrow_downward_rounded,
      );
    } else if (bmi < 25) {
      return (
        color: const Color(0xFF10B981),
        bgColor: const Color(0xFFF0FDF4),
        icon: Icons.check_circle_outline_rounded,
      );
    } else if (bmi < 30) {
      return (
        color: const Color(0xFFF59E0B),
        bgColor: const Color(0xFFFFFBEB),
        icon: Icons.warning_amber_rounded,
      );
    } else {
      return (
        color: const Color(0xFFEF4444),
        bgColor: const Color(0xFFFEF2F2),
        icon: Icons.report_outlined,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: s.bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: s.color.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: 13, color: s.color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: s.color,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
