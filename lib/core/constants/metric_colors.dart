import 'package:flutter/material.dart';

/// Centralized color definitions for each health metric.
/// These colors are used consistently across:
/// - The register modal cards
/// - The dashboard section headers
/// - The data entry screens
/// - The history/chart screens
class MetricColors {
  MetricColors._();

  // ── Signos Vitales ─────────────────────────────────────────────
  // Red/rose — universally associated with heart rate and blood pressure
  static const Color vitalsColor = Color(0xFFE53935);
  static const Color vitalsBg = Color(0xFFFFEBEE);

  // ── Antropometría ──────────────────────────────────────────────
  // Amber/orange — associated with physical measurement and body shape
  static const Color anthropoColor = Color(0xFFF57C00);
  static const Color anthropoBg = Color(0xFFFFF3E0);

  // ── Perfil Lipídico ────────────────────────────────────────────
  // Teal — associated with blood analysis and lab results
  static const Color lipidColor = Color(0xFF00897B);
  static const Color lipidBg = Color(0xFFE0F2F1);

  // ── Composición Corporal ───────────────────────────────────────
  // Indigo/violet — associated with body scanning and structure
  static const Color compositionColor = Color(0xFF5C6BC0);
  static const Color compositionBg = Color(0xFFE8EAF6);
}
