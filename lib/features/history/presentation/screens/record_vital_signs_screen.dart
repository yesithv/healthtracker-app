import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/vital_sign_record.dart';
import 'package:myvitals_healthtracker_app/core/constants/metric_colors.dart';
import 'package:myvitals_healthtracker_app/core/utils/health_classifiers.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/ui_preferences_provider.dart';
import 'package:myvitals_healthtracker_app/core/widgets/dismissible_info_banner.dart';

class RecordVitalSignsScreen extends StatefulWidget {
  final VitalSignRecord? recordToEdit;
  const RecordVitalSignsScreen({super.key, this.recordToEdit});

  @override
  State<RecordVitalSignsScreen> createState() => _RecordVitalSignsScreenState();
}

class _RecordVitalSignsScreenState extends State<RecordVitalSignsScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  int systolic = 120;
  int diastolic = 80;
  int heartRate = 72;

  String activityState = 'reposo';
  String symptom = 'normal';

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final r = widget.recordToEdit;
    if (r != null) {
      selectedDate = r.date;
      selectedTime = TimeOfDay.fromDateTime(r.date);
      systolic = r.systolic;
      diastolic = r.diastolic;
      heartRate = r.heartRate;
      if (r.activityState != null) activityState = r.activityState!;
      if (r.symptom != null) symptom = r.symptom!;
      _commentController.text = r.comment ?? '';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  double get _hrBarPercent {
    // Map 40–180bpm to 0–1
    final clamped = heartRate.clamp(40, 180);
    return (clamped - 40) / (180 - 40);
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: MetricColors.vitalsColor,
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
            primary: MetricColors.vitalsColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != selectedTime) {
      setState(() => selectedTime = picked);
    }
  }

  Future<void> _showIntEditDialog(
    String title,
    int current,
    String unit,
    Function(int) onSaved, {
    int min = 0,
    int max = 300,
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
                color: MetricColors.vitalsColor,
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
              backgroundColor: MetricColors.vitalsColor,
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

  Future<void> _saveRecord() async {
    final record = VitalSignRecord(
      id: widget.recordToEdit?.id,
      date: DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      ),
      systolic: systolic,
      diastolic: diastolic,
      heartRate: heartRate,
      activityState: activityState,
      symptom: symptom,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      createdAt: widget.recordToEdit?.createdAt,
    );
    if (widget.recordToEdit != null) {
      await VitalSignsRepository.instance.update(record);
    } else {
      await VitalSignsRepository.instance.insert(record);
    }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.vitalsSavedSuccess,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bpStatus = BpCategory.of(systolic, diastolic);
    final hrStatus = HrCategory.of(heartRate);

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
                  if (!context.watch<UIPreferencesProvider>().isVitalInfoDismissed) ...[
                    DismissibleInfoBanner(
                      text: l10n.infoBannerVitals,
                      baseColor: MetricColors.vitalsColor,
                      onDismiss: () {
                        context.read<UIPreferencesProvider>().dismissVitalInfo();
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  // ── Fecha y Hora ──────────────────────────────────────────
                  _buildSectionCard(
                    icon: Icons.calendar_month_outlined,
                    iconColor: MetricColors.vitalsColor,
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

                  // ── Presión Arterial ──────────────────────────────────────
                  _buildSectionCard(
                    icon: Icons.monitor_heart_outlined,
                    iconColor: MetricColors.vitalsColor,
                    title: l10n.bloodPressureTitle,
                    badge: _buildBpBadge(bpStatus, l10n),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildBpValueCard(
                                value: systolic,
                                label: l10n.systolicLabel,
                                unit: 'mmHg',
                                color: bpStatus.color,
                                onTap: () => _showIntEditDialog(
                                  l10n.systolicLabel,
                                  systolic,
                                  'mmHg',
                                  (v) => setState(() => systolic = v),
                                  min: 60,
                                  max: 250,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                '/',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                            Expanded(
                              child: _buildBpValueCard(
                                value: diastolic,
                                label: l10n.diastolicLabel,
                                unit: 'mmHg',
                                color: bpStatus.color,
                                onTap: () => _showIntEditDialog(
                                  l10n.diastolicLabel,
                                  diastolic,
                                  'mmHg',
                                  (v) => setState(() => diastolic = v),
                                  min: 40,
                                  max: 160,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Frecuencia Cardiaca ───────────────────────────────────
                  _buildSectionCard(
                    icon: Icons.favorite,
                    iconColor: MetricColors.vitalsColor,
                    title: l10n.heartRateTitle,
                    child: Column(
                      children: [
                        // Value row
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _showIntEditDialog(
                                l10n.heartRateTitle,
                                heartRate,
                                'bpm',
                                (v) => setState(() => heartRate = v),
                                min: 30,
                                max: 220,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    heartRate.toString(),
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: hrStatus.color,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'BPM',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                _buildAdjustButton(
                                  Icons.remove,
                                  () => setState(() {
                                    if (heartRate > 30) heartRate--;
                                  }),
                                ),
                                const SizedBox(width: 10),
                                _buildAdjustButton(
                                  Icons.add,
                                  () => setState(() {
                                    if (heartRate < 220) heartRate++;
                                  }),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Gradient bar
                        _buildHrGradientBar(l10n, hrStatus),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Contexto y Síntomas ───────────────────────────────────
                  _buildSectionCard(
                    icon: Icons.assignment_outlined,
                    iconColor: MetricColors.vitalsColor,
                    title: l10n.contextAndSymptoms,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Activity state
                        Text(
                          l10n.activityState,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildChip(
                              l10n.activityRest,
                              'reposo',
                              Icons.airline_seat_recline_normal,
                            ),
                            const SizedBox(width: 10),
                            _buildChip(
                              l10n.activityExercise,
                              'ejercicio',
                              Icons.directions_run,
                            ),
                            const SizedBox(width: 10),
                            _buildChip(
                              l10n.activityPostOp,
                              'post-op',
                              Icons.local_hospital_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // How do you feel?
                        Text(
                          l10n.howDoYouFeel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 3.2,
                          children: [
                            _buildSymptomChip(
                              l10n.symptomNormal,
                              'normal',
                              Icons.sentiment_satisfied_alt,
                            ),
                            _buildSymptomChip(
                              l10n.symptomDizziness,
                              'mareo',
                              Icons.rotate_right,
                            ),
                            _buildSymptomChip(
                              l10n.symptomPain,
                              'dolor',
                              Icons.bolt,
                            ),
                            _buildSymptomChip(
                              l10n.symptomFatigue,
                              'fatiga',
                              Icons.battery_2_bar,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Comentario ────────────────────────────────────────────
                  _buildSectionCard(
                    title: l10n.commentOptional,
                    child: _buildCommentBox(l10n),
                  ),

                  const SizedBox(height: 32),

                  // ── Save Button ───────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveRecord,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MetricColors.vitalsColor,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: MetricColors.vitalsColor.withValues(
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
        color: MetricColors.vitalsColor,
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
                  l10n.recordVitalSignsTitle,
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
                icon: const Icon(Icons.favorite, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section Card Container ────────────────────────────────────────────────
  Widget _buildSectionCard({
    IconData? icon,
    Color? iconColor,
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
                Icon(
                  icon,
                  color: iconColor ?? MetricColors.vitalsColor,
                  size: 18,
                ),
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

  // ── Date / Time selectors ─────────────────────────────────────────────────
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

  // ── Blood pressure value card ─────────────────────────────────────────────
  Widget _buildBpValueCard({
    required int value,
    required String label,
    required String unit,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── BP badge ──────────────────────────────────────────────────────────────
  Widget _buildBpBadge(BpCategory status, AppLocalizations l10n) {
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

  // ── HR gradient bar ───────────────────────────────────────────────────────
  Widget _buildHrGradientBar(AppLocalizations l10n, HrCategory status) {
    final percent = _hrBarPercent;
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF3B82F6), // Baja
                    Color(0xFF10B981), // Normal
                    Color(0xFFF59E0B), // Normal-Alta
                    Color(0xFFEF4444), // Alta
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: -38,
              child: FractionalTranslation(
                translation: Offset(percent - 0.5, 0),
                child: const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFF1E293B),
                  size: 72,
                  shadows: [Shadow(color: Colors.white, blurRadius: 2)],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.hrLow, style: _labelStyle()),
            Text(
              l10n.hrNormal,
              style: _labelStyle(color: const Color(0xFF10B981)),
            ),
            Text(l10n.hrHigh, style: _labelStyle()),
          ],
        ),
      ],
    );
  }

  TextStyle _labelStyle({Color? color}) => TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.bold,
    color: color ?? const Color(0xFF94A3B8),
    letterSpacing: 0.5,
  );

  // ── Activity chip ─────────────────────────────────────────────────────────
  Widget _buildChip(String label, String value, IconData icon) {
    final selected = activityState == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activityState = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? MetricColors.vitalsColor : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? MetricColors.vitalsColor
                  : const Color(0xFFDDE3EE),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : const Color(0xFF94A3B8),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Symptom chip ──────────────────────────────────────────────────────────
  Widget _buildSymptomChip(String label, String value, IconData icon) {
    final selected = symptom == value;
    return GestureDetector(
      onTap: () => setState(() => symptom = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? MetricColors.vitalsColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? MetricColors.vitalsColor
                : const Color(0xFFDDE3EE),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }

  // ── Adjust button ─────────────────────────────────────────────────────────
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
        child: Icon(icon, color: const Color(0xFFE53935), size: 20),
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

}
