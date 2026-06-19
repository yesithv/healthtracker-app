import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/constants/metric_colors.dart';
import 'package:myvitals_healthtracker_app/core/utils/health_classifiers.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/body_composition_record.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/ui_preferences_provider.dart';
import 'package:myvitals_healthtracker_app/core/widgets/dismissible_info_banner.dart';
import 'dart:math' as math;

class RecordBodyCompositionScreen extends StatefulWidget {
  final BodyCompositionRecord? recordToEdit;
  const RecordBodyCompositionScreen({super.key, this.recordToEdit});

  @override
  State<RecordBodyCompositionScreen> createState() =>
      _RecordBodyCompositionScreenState();
}

class _RecordBodyCompositionScreenState
    extends State<RecordBodyCompositionScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  // ── Values ───────────────────────────────────────────────────────────────
  double bodyFat = 21.6;
  double muscleMass = 36.5;
  int visceralFat = 6;
  int metabolicAge = 37;
  double? bodyWater;
  double? boneMass;

  final TextEditingController _commentController = TextEditingController();
  late final TextEditingController _bmrController;

  // ── BMR: user can override the auto-estimate ──────────────────────────────
  int get _estimatedBmr => (370 + 21.6 * muscleMass).round();
  int? _userBmr; // null = use estimate
  int get _displayBmr => _userBmr ?? _estimatedBmr;

  @override
  void initState() {
    super.initState();
    final r = widget.recordToEdit;
    if (r != null) {
      selectedDate = r.date;
      selectedTime = TimeOfDay.fromDateTime(r.date);
      if (r.bodyFatPercent != null) bodyFat = r.bodyFatPercent!;
      if (r.muscleMassKg != null) muscleMass = r.muscleMassKg!;
      if (r.visceralFatLevel != null) visceralFat = r.visceralFatLevel!;
      if (r.metabolicAge != null) metabolicAge = r.metabolicAge!;
      bodyWater = r.bodyWaterPercent;
      boneMass = r.boneMassKg;
      _commentController.text = r.comment ?? '';
      if (r.bmrKcal != null) _userBmr = r.bmrKcal;
    }
    _bmrController = TextEditingController(text: _displayBmr.toString());
  }

  @override
  void dispose() {
    _commentController.dispose();
    _bmrController.dispose();
    super.dispose();
  }

  // ── Date / time pickers ──────────────────────────────────────────────────
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: MetricColors.compositionColor,
            onPrimary: Colors.white,
            onSurface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: MetricColors.compositionColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != selectedTime) {
      setState(() => selectedTime = picked);
    }
  }

  // ── Edit dialogs ─────────────────────────────────────────────────────────
  Future<void> _showDoubleEditDialog(
    String title,
    double current,
    String unit,
    Function(double) onSaved, {
    double min = 0,
    double max = 999,
  }) async {
    final controller = TextEditingController(text: current.toStringAsFixed(1));
    final l10n = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1E293B),
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            suffixText: unit,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: MetricColors.compositionColor,
                width: 1.5,
              ),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val >= min && val <= max) onSaved(val);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MetricColors.compositionColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showIntEditDialog(
    String title,
    int current,
    String unit,
    Function(int) onSaved, {
    int min = 0,
    int max = 100,
  }) async {
    final controller = TextEditingController(text: current.toString());
    final l10n = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1E293B),
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            suffixText: unit,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: MetricColors.compositionColor,
                width: 1.5,
              ),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val >= min && val <= max) onSaved(val);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MetricColors.compositionColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── Save ─────────────────────────────────────────────────────────────────
  Future<void> _saveRecord() async {
    final record = BodyCompositionRecord(
      id: widget.recordToEdit?.id,
      date: DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      ),
      bodyFatPercent: bodyFat,
      muscleMassKg: muscleMass,
      visceralFatLevel: visceralFat,
      metabolicAge: metabolicAge,
      bmrKcal: _displayBmr,
      bodyWaterPercent: bodyWater,
      boneMassKg: boneMass,
      deviceName: null,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      createdAt: widget.recordToEdit?.createdAt,
    );
    if (widget.recordToEdit != null) {
      await BodyCompositionRepository.instance.update(record);
    } else {
      await BodyCompositionRepository.instance.insert(record);
    }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.compositionSavedSuccess,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: MetricColors.compositionColor,
      ),
    );
    context.pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fatStatus = FatCategory.of(bodyFat);
    final visceralStatus = VisceralCategory.of(visceralFat);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Column(
        children: [
          _buildAppBar(context, l10n),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Info banner ─────────────────────────────────────────
                  if (!context.watch<UIPreferencesProvider>().isBodyCompInfoDismissed) ...[
                    DismissibleInfoBanner(
                      text: l10n.compositionInfoBanner,
                      baseColor: MetricColors.compositionColor,
                      onDismiss: () {
                        context.read<UIPreferencesProvider>().dismissBodyCompInfo();
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Date & Time ────────────────────────────────────────
                  _buildSectionCard(
                    icon: Icons.calendar_month_outlined,
                    title: l10n.dateTimeOfMeasurement,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSelectorCard(
                            label: l10n.dateLabel,
                            value: DateFormat(
                              'dd/MM/yyyy',
                            ).format(selectedDate),
                            icon: Icons.calendar_today_outlined,
                            onTap: () => _selectDate(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSelectorCard(
                            label: l10n.timeLabel,
                            value: selectedTime.format(context),
                            icon: Icons.access_time,
                            onTap: () => _selectTime(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Body Fat % ─────────────────────────────────────────
                  _buildSectionCard(
                    icon: Icons.pie_chart_outline,
                    title: l10n.compositionBodyFat,
                    badge: _buildFatBadge(fatStatus, l10n),
                    child: _buildSliderField(
                      value: bodyFat,
                      unit: '%',
                      min: 3,
                      max: 60,
                      color: fatStatus.color,
                      onChanged: (v) => setState(() => bodyFat = _round1(v)),
                      onTap: () => _showDoubleEditDialog(
                        l10n.compositionBodyFat,
                        bodyFat,
                        '%',
                        (v) => setState(() => bodyFat = v),
                        min: 3,
                        max: 60,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Muscle Mass ─────────────────────────────────────────
                  _buildSectionCard(
                    icon: Icons.fitness_center,
                    title: l10n.compositionMuscleMass,
                    child: _buildSliderField(
                      value: muscleMass,
                      unit: 'kg',
                      min: 10,
                      max: 100,
                      color: MetricColors.compositionColor,
                      onChanged: (v) => setState(() => muscleMass = _round1(v)),
                      onTap: () => _showDoubleEditDialog(
                        l10n.compositionMuscleMass,
                        muscleMass,
                        'kg',
                        (v) => setState(() => muscleMass = v),
                        min: 10,
                        max: 100,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Visceral + Metabolic Age ────────────────────────────
                  _buildSectionCard(
                    icon: Icons.monitor_heart_outlined,
                    title: l10n.compositionVisceralAndAge,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildIntPickerCard(
                            label: l10n.compositionVisceralFat,
                            value: visceralFat,
                            unit: l10n.compositionLevel,
                            color: visceralStatus.color,
                            badgeText: visceralStatus.label(l10n),
                            onDecrement: () => setState(() {
                              if (visceralFat > 1) visceralFat--;
                            }),
                            onIncrement: () => setState(() {
                              if (visceralFat < 30) visceralFat++;
                            }),
                            onTap: () => _showIntEditDialog(
                              l10n.compositionVisceralFat,
                              visceralFat,
                              '',
                              (v) => setState(() => visceralFat = v),
                              min: 1,
                              max: 30,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildIntPickerCard(
                            label: l10n.compositionMetabolicAge,
                            value: metabolicAge,
                            unit: l10n.compositionYears,
                            color: MetricColors.compositionColor,
                            onDecrement: () => setState(() {
                              if (metabolicAge > 10) metabolicAge--;
                            }),
                            onIncrement: () => setState(() {
                              if (metabolicAge < 99) metabolicAge++;
                            }),
                            onTap: () => _showIntEditDialog(
                              l10n.compositionMetabolicAge,
                              metabolicAge,
                              l10n.compositionYears,
                              (v) => setState(() => metabolicAge = v),
                              min: 10,
                              max: 99,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Optional: water + bone ──────────────────────────────
                  _buildSectionCard(
                    icon: Icons.water_drop_outlined,
                    title: l10n.compositionOptionalSection,
                    child: Column(
                      children: [
                        _buildOptionalDoubleField(
                          label: l10n.compositionBodyWater,
                          refText: l10n.compositionBodyWaterRef,
                          value: bodyWater,
                          unit: '%',
                          hint: 'Ej: 55.0',
                          onSaved: (v) => setState(() => bodyWater = v),
                        ),
                        const SizedBox(height: 16),
                        _buildOptionalDoubleField(
                          label: l10n.compositionBoneMass,
                          refText: l10n.compositionBoneMassRef,
                          value: boneMass,
                          unit: 'kg',
                          hint: 'Ej: 3.2',
                          onSaved: (v) => setState(() => boneMass = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── BMR editable ────────────────────────────────────────
                  _buildBmrCard(l10n),
                  const SizedBox(height: 20),

                  // ── Comment ─────────────────────────────────────────────
                  _buildSectionCard(
                    title: l10n.commentOptional,
                    child: _buildCommentBox(l10n),
                  ),
                  const SizedBox(height: 32),

                  // ── Save ────────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveRecord,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MetricColors.compositionColor,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: MetricColors.compositionColor.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      child: Text(
                        l10n.saveAndEarnXp,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: MetricColors.compositionColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Text(
                  l10n.compositionTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.accessibility_new, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section card ──────────────────────────────────────────────────────────
  Widget _buildSectionCard({
    IconData? icon,
    required String title,
    Widget? badge,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              if (icon != null) ...[
                Icon(icon, color: MetricColors.compositionColor, size: 18),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ── Date/Time selectors ───────────────────────────────────────────────────
  Widget _buildSelectorCard({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Icon(icon, color: const Color(0xFF64748B), size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Slider field (fat % and muscle mass) ──────────────────────────────────
  Widget _buildSliderField({
    required double value,
    required String unit,
    required double min,
    required double max,
    required Color color,
    required ValueChanged<double> onChanged,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onTap,
              child: Row(
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
                  const SizedBox(width: 4),
                  Icon(Icons.edit, size: 14, color: color),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                _buildAdjustButton(
                  Icons.remove,
                  () => setState(() => onChanged(math.max(min, value - 0.1))),
                ),
                const SizedBox(width: 10),
                _buildAdjustButton(
                  Icons.add,
                  () => setState(() => onChanged(math.min(max, value + 0.1))),
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

  // ── Integer picker card (visceral / metabolic age) ────────────────────────
  Widget _buildIntPickerCard({
    required String label,
    required int value,
    required String unit,
    required Color color,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required VoidCallback onTap,
    String? badgeText,
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Row(
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
              ],
            ),
          ),
          if (badgeText != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildSmallAdjustButton(Icons.remove, onDecrement),
              const SizedBox(width: 8),
              _buildSmallAdjustButton(Icons.add, onIncrement),
            ],
          ),
        ],
      ),
    );
  }

  // ── Optional field row ────────────────────────────────────────────────────
  Widget _buildOptionalDoubleField({
    required String label,
    required String refText,
    required double? value,
    required String unit,
    required String hint,
    required Function(double) onSaved,
  }) {
    final controller = TextEditingController(
      text: value != null ? value.toStringAsFixed(1) : '',
    );
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    refText,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onChanged: (text) {
                  final v = double.tryParse(text);
                  if (v != null) onSaved(v);
                },
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                  suffixText: unit,
                  suffixStyle: TextStyle(
                    color: MetricColors.compositionColor,
                    fontWeight: FontWeight.bold,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: MetricColors.compositionColor,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── BMR editable card ─────────────────────────────────────────────────────
  Widget _buildBmrCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MetricColors.compositionColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: MetricColors.compositionColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.compositionBmr,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bmrController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    prefixIcon: Icon(Icons.edit, color: Colors.white70, size: 20),
                    prefixIconConstraints: BoxConstraints(minWidth: 30, minHeight: 0),
                    suffixText: 'kcal',
                    suffixStyle: TextStyle(
                      color: Colors.white60,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onChanged: (v) {
                    final parsed = int.tryParse(v);
                    setState(() => _userBmr = parsed);
                  },
                ),
              ),
              Column(
                children: [
                  _buildBmrAdjustButton(Icons.add, () {
                    final val = _displayBmr + 10;
                    setState(() => _userBmr = val);
                    _bmrController.text = val.toString();
                  }),
                  const SizedBox(height: 6),
                  _buildBmrAdjustButton(Icons.remove, () {
                    final val = (_displayBmr - 10).clamp(500, 9999);
                    setState(() => _userBmr = val);
                    _bmrController.text = val.toString();
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.compositionBmrSubtitle,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBmrAdjustButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  // ── Adjust buttons ────────────────────────────────────────────────────────
  Widget _buildAdjustButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, color: MetricColors.compositionColor, size: 20),
      ),
    );
  }

  Widget _buildSmallAdjustButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: MetricColors.compositionBg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: MetricColors.compositionColor, size: 16),
      ),
    );
  }

  // ── Fat badge ─────────────────────────────────────────────────────────────
  Widget _buildFatBadge(FatCategory status, AppLocalizations l10n) {
    final label = status.label(l10n);
    final color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ── Comment box ───────────────────────────────────────────────────────────
  Widget _buildCommentBox(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _commentController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: l10n.commentHint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  double _round1(double v) => (v * 10).round() / 10;
}
