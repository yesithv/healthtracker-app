import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/lipid_record.dart';
import 'package:myvitals_healthtracker_app/core/constants/metric_colors.dart';
import 'package:myvitals_healthtracker_app/core/utils/health_classifiers.dart';
import 'package:intl/intl.dart';

// ────────────────────────────────────────────────────────────────────────────
// Lipid reference ranges (mg/dL)
// ────────────────────────────────────────────────────────────────────────────
// Total Chol : <200 Desirable | 200-239 Borderline | ≥240 High
// LDL        : <100 Optimal   | 100-129 Near-opt   | 130-159 Borderline | ≥160 High
// HDL        : <40 Low(♂)/<50 Low(♀) | 40-59 OK | ≥60 Protective
// VLDL       : 2-30 Normal
// Trigs      : <150 Normal | 150-199 Borderline | 200-499 High | ≥500 Very High

class RecordLipidScreen extends StatefulWidget {
  final LipidRecord? recordToEdit;
  const RecordLipidScreen({super.key, this.recordToEdit});

  @override
  State<RecordLipidScreen> createState() => _RecordLipidScreenState();
}

class _RecordLipidScreenState extends State<RecordLipidScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  final _tcController = TextEditingController(); // Total Cholesterol
  final _ldlController = TextEditingController();
  final _hdlController = TextEditingController();
  final _vldlController = TextEditingController();
  final _trigsController = TextEditingController();
  final _labController = TextEditingController();
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final r = widget.recordToEdit;
    if (r != null) {
      selectedDate = r.date;
      selectedTime = TimeOfDay.fromDateTime(r.date);
      _tcController.text = _numToText(r.totalCholesterol);
      _ldlController.text = _numToText(r.ldl);
      _hdlController.text = _numToText(r.hdl);
      _vldlController.text = _numToText(r.vldl);
      _trigsController.text = _numToText(r.triglycerides);
      _labController.text = r.labName ?? '';
      _commentController.text = r.comment ?? '';
    }
  }

  @override
  void dispose() {
    _tcController.dispose();
    _ldlController.dispose();
    _hdlController.dispose();
    _vldlController.dispose();
    _trigsController.dispose();
    _labController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  double? _val(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  /// Formats a stored value for an input field, dropping a trailing ".0".
  String _numToText(double? v) {
    if (v == null) return '';
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: MetricColors.lipidColor,
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
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: MetricColors.lipidColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != selectedTime) {
      setState(() => selectedTime = picked);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final tc = _val(_tcController);
    final ldl = _val(_ldlController);
    final hdl = _val(_hdlController);
    final vldl = _val(_vldlController);
    final trigs = _val(_trigsController);

    if (tc == null &&
        ldl == null &&
        hdl == null &&
        vldl == null &&
        trigs == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.lipidAtLeastOneValue),
          backgroundColor: const Color(0xFFF59E0B),
        ),
      );
      return;
    }

    final record = LipidRecord(
      id: widget.recordToEdit?.id,
      date: DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      ),
      totalCholesterol: tc,
      ldl: ldl,
      hdl: hdl,
      vldl: vldl,
      triglycerides: trigs,
      labName: _labController.text.trim().isEmpty
          ? null
          : _labController.text.trim(),
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      createdAt: widget.recordToEdit?.createdAt,
    );
    if (widget.recordToEdit != null) {
      await LipidRepository.instance.update(record);
    } else {
      await LipidRepository.instance.insert(record);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.lipidSavedSuccess,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
    context.pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                  // ── Info banner ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: MetricColors.lipidBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: MetricColors.lipidColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: MetricColors.lipidColor,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.lipidInfoBanner,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF00695C),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Fecha y Hora ─────────────────────────────────────────
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



                  // ── Laboratorio ──────────────────────────────────────────
                  _buildSectionCard(
                    icon: Icons.science_outlined,
                    title: l10n.lipidLabInfo,
                    child: _buildTextField(
                      controller: _labController,
                      label: l10n.lipidLabName,
                      hint: l10n.lipidLabNameHint,
                      isNumeric: false,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Resultados del Análisis ──────────────────────────────
                  _buildSectionCard(
                    icon: Icons.biotech_outlined,
                    title: l10n.lipidResultsTitle,
                    child: Column(
                      children: [
                        _buildLipidField(
                          controller: _tcController,
                          label: l10n.lipidTotalCholesterol,
                          hint: 'Ej: 180',
                          refRange: l10n.lipidTcRef,
                          statusFn: LipidStatus.totalCholesterol,
                          l10n: l10n,
                        ),
                        const SizedBox(height: 16),
                        _buildLipidField(
                          controller: _ldlController,
                          label: l10n.lipidLdl,
                          hint: 'Ej: 90',
                          refRange: l10n.lipidLdlRef,
                          statusFn: LipidStatus.ldl,
                          l10n: l10n,
                        ),
                        const SizedBox(height: 16),
                        _buildLipidField(
                          controller: _hdlController,
                          label: l10n.lipidHdl,
                          hint: 'Ej: 60',
                          refRange: l10n.lipidHdlRef,
                          statusFn: LipidStatus.hdl,
                          l10n: l10n,
                          hdlInverted: true,
                        ),
                        const SizedBox(height: 16),
                        _buildLipidField(
                          controller: _vldlController,
                          label: l10n.lipidVldl,
                          hint: 'Ej: 20',
                          refRange: l10n.lipidVldlRef,
                          statusFn: LipidStatus.vldl,
                          l10n: l10n,
                        ),
                        const SizedBox(height: 16),
                        _buildLipidField(
                          controller: _trigsController,
                          label: l10n.lipidTriglycerides,
                          hint: 'Ej: 140',
                          refRange: l10n.lipidTrigsRef,
                          statusFn: LipidStatus.triglycerides,
                          l10n: l10n,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Resumen visual ───────────────────────────────────────
                  _buildSummaryCard(l10n),

                  const SizedBox(height: 20),

                  // ── Comentario ───────────────────────────────────────────
                  _buildSectionCard(
                    title: l10n.commentOptional,
                    child: _buildCommentBox(l10n),
                  ),

                  const SizedBox(height: 32),

                  // ── Save ─────────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MetricColors.lipidColor,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: MetricColors.lipidColor.withValues(
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

  // ── AppBar ─────────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: MetricColors.lipidColor,
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
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Text(
                  l10n.lipidProfileTitle,
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
                icon: const Icon(Icons.bloodtype, color: Colors.white),
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
                Icon(icon, color: MetricColors.lipidColor, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ── Date / time selector ──────────────────────────────────────────────────
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

  // ── Lipid field with live status badge ────────────────────────────────────
  Widget _buildLipidField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String refRange,
    required LipidStatus Function(double) statusFn,
    required AppLocalizations l10n,
    bool hdlInverted = false,
  }) {
    return StatefulBuilder(
      builder: (context, setInner) {
        final val = _val(controller);
        final status = val != null ? statusFn(val) : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label row + ref range
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Text(
                  refRange,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Input + status badge
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: status != null
                            ? status.color.withValues(alpha: 0.5)
                            : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]'),
                              ),
                            ],
                            onChanged: (_) => setInner(() {}),
                            decoration: InputDecoration(
                              hintText: hint,
                              hintStyle: const TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 13,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            'mg/dL',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: status != null
                                  ? status.color
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (status != null) ...[
                  const SizedBox(width: 10),
                  _StatusBadge(
                    status: status,
                    label: status.label(l10n, hdlInverted: hdlInverted),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  // ── Summary card ──────────────────────────────────────────────────────────
  Widget _buildSummaryCard(AppLocalizations l10n) {
    final tc = _val(_tcController);
    final ldl = _val(_ldlController);
    final hdl = _val(_hdlController);
    final vldl = _val(_vldlController);
    final trigs = _val(_trigsController);

    final hasSomeData =
        tc != null ||
        ldl != null ||
        hdl != null ||
        vldl != null ||
        trigs != null;
    if (!hasSomeData) return const SizedBox.shrink();

    // Derive overall risk
    final statuses = <LipidStatus>[
      if (tc != null) LipidStatus.totalCholesterol(tc),
      if (ldl != null) LipidStatus.ldl(ldl),
      if (hdl != null) LipidStatus.hdl(hdl),
      if (vldl != null) LipidStatus.vldl(vldl),
      if (trigs != null) LipidStatus.triglycerides(trigs),
    ];

    final hasHigh = statuses.any((s) => s == LipidStatus.high);
    final hasBorderline = statuses.any((s) => s == LipidStatus.borderline);
    final overallStatus = hasHigh
        ? LipidStatus.high
        : hasBorderline
        ? LipidStatus.borderline
        : LipidStatus.optimal;

    final overallColor = overallStatus.color;
    final overallLabel = overallStatus.label(l10n);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            overallColor.withValues(alpha: 0.08),
            overallColor.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: overallColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: overallColor.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: overallColor.withValues(alpha: 0.15),
            child: Icon(
              Icons.analytics_outlined,
              color: overallColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.lipidOverallRisk,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  overallLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: overallColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.lipidOverallDesc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Generic text field ────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isNumeric = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumeric
                ? TextInputType.number
                : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
            ),
          ),
        ),
      ],
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

// ── Status badge widget ────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final LipidStatus status;
  final String label;

  const _StatusBadge({
    required this.status,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

