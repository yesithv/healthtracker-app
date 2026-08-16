import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/providers/health_goals_provider.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens/content_palette.dart';
import '../../../../core/theme/tokens/metric_palette.dart';
import '../../../../core/theme/tokens/tone.dart';
import '../../../../core/widgets/secondary_app_bar.dart';
import '../../../../core/widgets/settings_page_layout.dart';
import 'package:myvitals_healthtracker_app/core/widgets/icon_badge.dart';

class HealthGoalsScreen extends StatefulWidget {
  const HealthGoalsScreen({super.key});

  @override
  State<HealthGoalsScreen> createState() => _HealthGoalsScreenState();
}

class _HealthGoalsScreenState extends State<HealthGoalsScreen> {
  bool _goalsEnabled = false;
  double _targetWeight = 70.0;
  double _targetBodyFat = 15.0;
  double _targetMuscleMass = 30.0;
  int _targetVisceralFat = 5;

  @override
  void initState() {
    super.initState();
    final goals = Provider.of<HealthGoalsProvider>(context, listen: false);
    _goalsEnabled = goals.medicalGoalsEnabled;
    _targetWeight = goals.targetWeight ?? 70.0;
    _targetBodyFat = goals.targetBodyFat ?? 15.0;
    _targetMuscleMass = goals.targetMuscleMass ?? 30.0;
    _targetVisceralFat = goals.targetVisceralFat ?? 5;
  }

  void _saveGoals() {
    final goals = Provider.of<HealthGoalsProvider>(context, listen: false);
    goals.updateHealthGoals(
      enabled: _goalsEnabled,
      weight: _targetWeight,
      bodyFat: _targetBodyFat,
      muscleMass: _targetMuscleMass,
      visceralFat: _targetVisceralFat,
    );

    final l10n = AppLocalizations.of(context)!;
    // Guardar bien es un resultado ÓPTIMO, igual que en las pantallas de
    // registro: el verde sale de la paleta clínica, no de esta pantalla.
    final ok = _theme.clinical.optimal;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.goalsSavedSuccess,
          style: _theme.type.body.copyWith(color: ok.onAccent),
        ),
        backgroundColor: ok.accent,
      ),
    );
    context.pop();
  }

  double _round1(double value) => (value * 10).roundToDouble() / 10;

  // ── Tokens ────────────────────────────────────────────────────────────────

  ThemeData get _theme => Theme.of(context);

  /// Acento de la pantalla: el MISMO que su fila en Perfil, para que al entrar
  /// se reconozca de dónde viene. Ver la nota sobre acentos de orientación en
  /// `profile_screen.dart`.
  Tone get _accent => _theme.content.tone(ContentCategory.heart);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = _theme;
    final surfaces = theme.surfaces;
    final accent = _accent;

    return Scaffold(
      backgroundColor: surfaces.canvas,
      body: Column(
        children: [
          const SecondaryAppBar(),
          Expanded(
            child: SingleChildScrollView(
              // El widget común aporta el encabezado (ícono centrado + título +
              // descripción) y el botón «Guardar preferencias» estándar, para
              // que sean idénticos al resto de pantallas de Perfil.
              child: SettingsPageLayout(
                icon: Icons.flag_circle_outlined,
                title: l10n.healthGoalsTitle,
                description: l10n.goalsScreenDescription,
                onConfirm: _saveGoals,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- INFO & TOGGLE CARD ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: surfaces.cardDecoration(
                        radius: surfaces.radiusCard + 4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconBadge(
                                Icons.flag_circle_outlined,
                                color: accent.accent,
                                background: accent.accent.withValues(
                                  alpha: 0.1,
                                ),
                                padding: 10,
                                iconSize: 28,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.medicalGoalsToggle,
                                      style: theme.type.cardTitle.copyWith(
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.medicalGoalsSubtitle,
                                      style: theme.type.body.copyWith(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _goalsEnabled,
                                activeThumbColor: accent.accent,
                                activeTrackColor: accent.accent.withValues(
                                  alpha: 0.2,
                                ),
                                onChanged: (val) =>
                                    setState(() => _goalsEnabled = val),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (_goalsEnabled) ...[
                      // --- TARGET WEIGHT ---
                      _buildSectionCard(
                        icon: Icons.monitor_weight_outlined,
                        title: l10n.targetWeight,
                        child: _buildSliderField(
                          value: _targetWeight,
                          unit: 'kg', // Could be unit aware later
                          min: 30,
                          max: 200,
                          // El peso es antropometría; la grasa, el músculo y la
                          // grasa visceral son composición corporal. Cada
                          // objetivo lleva la identidad del indicador al que
                          // apunta, no un color elegido para que la pantalla
                          // quede variada.
                          tone: theme.metrics.tone(MetricFamily.anthropometry),
                          onChanged: (v) =>
                              setState(() => _targetWeight = _round1(v)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- TARGET BODY FAT ---
                      _buildSectionCard(
                        icon: Icons.pie_chart_outline,
                        title: l10n.targetBodyFat,
                        child: _buildSliderField(
                          value: _targetBodyFat,
                          unit: '%',
                          min: 3,
                          max: 60,
                          tone: theme.metrics.tone(MetricFamily.bodyComposition),
                          onChanged: (v) =>
                              setState(() => _targetBodyFat = _round1(v)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- TARGET MUSCLE MASS ---
                      _buildSectionCard(
                        icon: Icons.fitness_center,
                        title: l10n.targetMuscleMass,
                        child: _buildSliderField(
                          value: _targetMuscleMass,
                          unit: 'kg',
                          min: 10,
                          max: 100,
                          tone: theme.metrics.tone(MetricFamily.bodyComposition),
                          onChanged: (v) =>
                              setState(() => _targetMuscleMass = _round1(v)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- TARGET VISCERAL FAT ---
                      _buildSectionCard(
                        icon: Icons.monitor_heart_outlined,
                        title: l10n.targetVisceralFat,
                        child: _buildIntPickerCard(
                          value: _targetVisceralFat,
                          unit: l10n.compositionLevel,
                          tone: theme.metrics.tone(MetricFamily.bodyComposition),
                          onDecrement: () => setState(() {
                            if (_targetVisceralFat > 1) _targetVisceralFat--;
                          }),
                          onIncrement: () => setState(() {
                            if (_targetVisceralFat < 30) _targetVisceralFat++;
                          }),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final theme = _theme;
    final surfaces = theme.surfaces;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: surfaces.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: surfaces.inkSecondary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: theme.type.cardTitle.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildSliderField({
    required double value,
    required String unit,
    required double min,
    required double max,
    required Tone tone,
    required ValueChanged<double> onChanged,
  }) {
    final theme = _theme;
    final color = tone.accent;
    return Column(
      children: [
        Row(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value.toStringAsFixed(1),
                  style: theme.type.numeral.copyWith(
                    fontSize: 40,
                    color: color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  unit,
                  style: theme.type.numeralUnit.copyWith(
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                _buildAdjustButton(
                  Icons.remove,
                  () => onChanged(math.max(min, value - 0.1)),
                ),
                const SizedBox(width: 10),
                _buildAdjustButton(
                  Icons.add,
                  () => onChanged(math.min(max, value + 0.1)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.18),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.12),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            trackHeight: 4,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildIntPickerCard({
    required int value,
    required String unit,
    required Tone tone,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    final theme = _theme;
    final surfaces = theme.surfaces;
    final color = tone.accent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaces.inset,
        borderRadius: BorderRadius.circular(surfaces.radiusCard),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value.toString(),
                style: theme.type.numeralSmall.copyWith(
                  fontSize: 28,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: theme.type.numeralUnit.copyWith(
                  fontSize: 13,
                  color: color,
                ),
              ),
              const Spacer(),
              _buildAdjustButton(Icons.remove, onDecrement),
              const SizedBox(width: 10),
              _buildAdjustButton(Icons.add, onIncrement),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustButton(IconData icon, VoidCallback onTap) {
    final surfaces = _theme.surfaces;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: surfaces.inset,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: surfaces.divider),
        ),
        child: Icon(icon, size: 20, color: surfaces.inkSecondary),
      ),
    );
  }
}
