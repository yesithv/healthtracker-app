import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/providers/health_goals_provider.dart';
import '../../../../core/constants/metric_colors.dart';
import '../../../../core/widgets/secondary_app_bar.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.goalsSavedSuccess),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
    context.pop();
  }

  double _round1(double value) => (value * 10).roundToDouble() / 10;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Column(
        children: [
          const SecondaryAppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- INFO & TOGGLE CARD ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.flag_circle_outlined,
                                color: Color(0xFFEF4444),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.medicalGoalsToggle,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.medicalGoalsSubtitle,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _goalsEnabled,
                              activeThumbColor: const Color(0xFFEF4444),
                              activeTrackColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
                              onChanged: (val) => setState(() => _goalsEnabled = val),
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
                        color: const Color(0xFF0D48A0),
                        onChanged: (v) => setState(() => _targetWeight = _round1(v)),
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
                        color: MetricColors.compositionColor,
                        onChanged: (v) => setState(() => _targetBodyFat = _round1(v)),
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
                        color: const Color(0xFFF59E0B),
                        onChanged: (v) => setState(() => _targetMuscleMass = _round1(v)),
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
                        color: const Color(0xFF8B5CF6),
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

                  // --- SAVE BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveGoals,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFFEF4444).withValues(alpha: 0.4),
                      ),
                      child: Text(
                        l10n.savePreferences,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF64748B), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
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
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
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
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
    required Color color,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
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
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF475569)),
      ),
    );
  }
}
