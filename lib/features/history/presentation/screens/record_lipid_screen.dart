import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/lipid_record.dart';
import 'package:myvitals_healthtracker_app/core/labs/lab.dart';
import 'package:myvitals_healthtracker_app/core/labs/labs_api_client.dart';
import 'package:myvitals_healthtracker_app/core/ranges/lab_ranges_store.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/metric_palette.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/tone.dart';
import 'package:myvitals_healthtracker_app/core/widgets/status_chip.dart';
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
  final _labController = TextEditingController(); // solo para "Otro"
  final _commentController = TextEditingController();

  // Selector de laboratorio: '__none__' = no indicado, un code del catálogo, o
  // '__other__' = otro (texto libre en [_labController]).
  static const _kNone = '__none__';
  static const _kOther = '__other__';
  final _labClient = LabsApiClient();
  List<Lab> _labs = [];
  bool _labsLoaded = false;
  String _selectedLab = _kNone;

  /// Código de lab efectivo para clasificar (null = sin lab → rangos estándar).
  String? get _labCodeForRanges =>
      (_selectedLab == _kNone || _selectedLab == _kOther) ? null : _selectedLab;

  /// Precarga los rangos del lab elegido para que los badges se re-pinten con
  /// SU escala (best-effort; sin red los badges usan el fallback ATP III).
  void _warmLabRanges(String? labCode) {
    if (labCode == null) return;
    LabRangesStore.instance.ensureLoaded(labCode).then((_) {
      if (mounted) setState(() {});
    });
  }

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
      _commentController.text = r.comment ?? '';
      if (r.labCode != null && r.labCode!.isNotEmpty) {
        _selectedLab = r.labCode!;
      } else if ((r.labName ?? '').isNotEmpty) {
        _selectedLab = _kOther;
        _labController.text = r.labName!;
      }
    }
    _loadLabs();
    _warmLabRanges(_labCodeForRanges);
  }

  /// Trae el catálogo de laboratorios. Si el registro traía un code que ya no está
  /// en el catálogo, cae a "Otro" conservando el nombre.
  Future<void> _loadLabs() async {
    final labs = await _labClient.fetchLabs();
    if (!mounted) return;
    setState(() {
      _labs = labs;
      _labsLoaded = true;
      if (_selectedLab != _kNone &&
          _selectedLab != _kOther &&
          !labs.any((l) => l.code == _selectedLab)) {
        if (_labController.text.isEmpty) {
          _labController.text = widget.recordToEdit?.labName ?? '';
        }
        _selectedLab = _labController.text.isEmpty ? _kNone : _kOther;
      }
    });
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
    _labClient.close();
    super.dispose();
  }

  // ── Tokens ────────────────────────────────────────────────────────────────

  ThemeData get _theme => Theme.of(context);

  /// Identidad de la familia «perfil lipídico»: verde-azulado en cualquier tema.
  Tone get _family => _theme.metrics.tone(MetricFamily.lipids);

  /// Tiñe el selector de Material con la identidad de la familia, dejándole al
  /// tema la tipografía y las superficies.
  Widget _themedPicker(BuildContext ctx, Widget? child) {
    final base = Theme.of(ctx);
    final family = base.metrics.tone(MetricFamily.lipids);
    return Theme(
      data: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: family.accent,
          onPrimary: family.onAccent,
          onSurface: base.surfaces.ink,
        ),
      ),
      child: child!,
    );
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
      builder: _themedPicker,
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: _themedPicker,
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
      // Falta un dato: merece ATENCIÓN, no alarma. Ese ámbar es el de la
      // paleta clínica, con su propio color de texto legible.
      final warn = _theme.clinical.caution;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.lipidAtLeastOneValue,
            style: _theme.type.body.copyWith(color: warn.onAccent),
          ),
          backgroundColor: warn.accent,
        ),
      );
      return;
    }

    // Deriva laboratorio (código controlado) + nombre a partir de la selección.
    String? labCode;
    String? labName;
    if (_selectedLab == _kOther) {
      labName = _labController.text.trim().isEmpty ? null : _labController.text.trim();
    } else if (_selectedLab != _kNone) {
      labCode = _selectedLab;
      labName = _labs
          .firstWhere((l) => l.code == _selectedLab,
              orElse: () => Lab(code: _selectedLab, name: _selectedLab))
          .name;
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
      labName: labName,
      labCode: labCode,
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
    // Guardar bien es un resultado ÓPTIMO: ese verde sale de la paleta clínica.
    final ok = _theme.clinical.optimal;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.lipidSavedSuccess,
          style: _theme.type.body.copyWith(color: ok.onAccent),
        ),
        backgroundColor: ok.accent,
      ),
    );
    context.pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = _theme;
    final surfaces = theme.surfaces;
    final family = _family;

    return Scaffold(
      backgroundColor: surfaces.canvas,
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
                      color: family.surface,
                      borderRadius: BorderRadius.circular(
                        surfaces.radiusControl,
                      ),
                      border: Border.all(
                        color: family.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: family.accent,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.lipidInfoBanner,
                            // Sobre la superficie de la familia, el texto va en
                            // su acento: es el par que el tema garantiza legible.
                            style: theme.type.body.copyWith(
                              fontSize: 11,
                              height: 1.5,
                              color: family.accent,
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
                    child: _buildLabSelector(l10n),
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
                          statusFn: (v) => LipidStatus.totalCholesterol(v,
                              labCode: _labCodeForRanges),
                          l10n: l10n,
                        ),
                        const SizedBox(height: 16),
                        _buildLipidField(
                          controller: _ldlController,
                          label: l10n.lipidLdl,
                          hint: 'Ej: 90',
                          refRange: l10n.lipidLdlRef,
                          statusFn: (v) =>
                              LipidStatus.ldl(v, labCode: _labCodeForRanges),
                          l10n: l10n,
                        ),
                        const SizedBox(height: 16),
                        _buildLipidField(
                          controller: _hdlController,
                          label: l10n.lipidHdl,
                          hint: 'Ej: 60',
                          refRange: l10n.lipidHdlRef,
                          statusFn: (v) =>
                              LipidStatus.hdl(v, labCode: _labCodeForRanges),
                          l10n: l10n,
                          hdlInverted: true,
                        ),
                        const SizedBox(height: 16),
                        _buildLipidField(
                          controller: _vldlController,
                          label: l10n.lipidVldl,
                          hint: 'Ej: 20',
                          refRange: l10n.lipidVldlRef,
                          statusFn: (v) =>
                              LipidStatus.vldl(v, labCode: _labCodeForRanges),
                          l10n: l10n,
                        ),
                        const SizedBox(height: 16),
                        _buildLipidField(
                          controller: _trigsController,
                          label: l10n.lipidTriglycerides,
                          hint: 'Ej: 140',
                          refRange: l10n.lipidTrigsRef,
                          statusFn: (v) => LipidStatus.triglycerides(v,
                              labCode: _labCodeForRanges),
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
                        backgroundColor: family.accent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            surfaces.radiusControl,
                          ),
                        ),
                        // Los temas planos no llevan sombra en los controles.
                        elevation: surfaces.cardShadow.isEmpty ? 0 : 4,
                        shadowColor: family.accent.withValues(alpha: 0.4),
                      ),
                      child: Text(
                        l10n.saveAndEarnXp,
                        style: theme.type.button.copyWith(
                          fontSize: 16,
                          color: family.onAccent,
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
    final family = _family;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: family.accent,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(_theme.surfaces.radiusCard + 4),
          bottomRight: Radius.circular(_theme.surfaces.radiusCard + 4),
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
                icon: Icon(Icons.arrow_back, color: family.onAccent),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Text(
                  l10n.lipidProfileTitle,
                  textAlign: TextAlign.center,
                  style: _theme.type.sectionLabel.copyWith(
                    fontSize: 15,
                    color: family.onAccent,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.bloodtype, color: family.onAccent),
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
    final theme = _theme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: theme.surfaces.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: _family.accent, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: theme.type.sectionLabel.copyWith(
                  color: theme.surfaces.ink,
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
    final theme = _theme;
    final surfaces = theme.surfaces;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.type.fieldLabel),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: surfaces.inset,
              borderRadius: BorderRadius.circular(surfaces.radiusControl),
              border: Border.all(color: surfaces.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: theme.type.cardTitle.copyWith(fontSize: 14),
                ),
                Icon(icon, color: surfaces.inkSecondary, size: 16),
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
    final theme = _theme;
    final surfaces = theme.surfaces;

    return StatefulBuilder(
      builder: (context, setInner) {
        final val = _val(controller);
        final status = val != null ? statusFn(val) : null;
        // El tono clínico del valor escrito. Quién decide que un LDL de 145 es
        // «límite» son los rangos del laboratorio elegido, no el tema.
        final tone = status == null
            ? null
            : theme.clinical.tone(status.status);

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
                    style: theme.type.cardTitle.copyWith(fontSize: 13),
                  ),
                ),
                Text(
                  refRange,
                  style: theme.type.meta.copyWith(
                    fontSize: 10,
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
                      color: surfaces.inset,
                      borderRadius: BorderRadius.circular(
                        surfaces.radiusControl,
                      ),
                      border: Border.all(
                        color: tone == null
                            ? surfaces.divider
                            : tone.accent.withValues(alpha: 0.5),
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
                              hintStyle: theme.type.body.copyWith(
                                color: surfaces.inkMuted,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 13,
                              ),
                            ),
                            style: theme.type.numeralSmall.copyWith(
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            'mg/dL',
                            style: theme.type.numeralUnit.copyWith(
                              fontSize: 12,
                              color: tone?.accent ?? surfaces.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (status != null) ...[
                  const SizedBox(width: 10),
                  StatusChip(
                    status: status.status,
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

    // Derive overall risk (con los rangos del lab elegido cuando hay).
    final lab = _labCodeForRanges;
    final statuses = <LipidStatus>[
      if (tc != null) LipidStatus.totalCholesterol(tc, labCode: lab),
      if (ldl != null) LipidStatus.ldl(ldl, labCode: lab),
      if (hdl != null) LipidStatus.hdl(hdl, labCode: lab),
      if (vldl != null) LipidStatus.vldl(vldl, labCode: lab),
      if (trigs != null) LipidStatus.triglycerides(trigs, labCode: lab),
    ];

    final hasHigh = statuses.any((s) => s == LipidStatus.high);
    final hasBorderline = statuses.any((s) => s == LipidStatus.borderline);
    final overallStatus = hasHigh
        ? LipidStatus.high
        : hasBorderline
        ? LipidStatus.borderline
        : LipidStatus.optimal;

    final overallLabel = overallStatus.label(l10n);
    final theme = _theme;
    final surfaces = theme.surfaces;
    // El riesgo global gana el peor de los estados presentes: eso lo decide el
    // cálculo de arriba, y el tema solo dice con qué color se pinta.
    final tone = theme.clinical.tone(overallStatus.status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tone.accent.withValues(alpha: 0.08),
            tone.accent.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(surfaces.radiusCard),
        border: Border.all(
          color: tone.accent.withValues(alpha: 0.3),
          width: 1.5,
        ),
        // Los temas planos no llevan sombra: el filete ya delimita la tarjeta.
        boxShadow: surfaces.cardShadow.isEmpty
            ? const []
            : [
                BoxShadow(
                  color: tone.accent.withValues(alpha: 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: tone.accent.withValues(alpha: 0.15),
            child: Icon(
              Icons.analytics_outlined,
              color: tone.accent,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.lipidOverallRisk, style: theme.type.fieldLabel),
                const SizedBox(height: 4),
                Text(
                  overallLabel,
                  style: theme.type.cardTitle.copyWith(
                    fontSize: 18,
                    color: tone.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.lipidOverallDesc,
                  style: theme.type.meta.copyWith(fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Lab selector (catálogo + "Otro" + "No indicado") ──────────────────────
  Widget _buildLabSelector(AppLocalizations l10n) {
    final theme = _theme;
    final surfaces = theme.surfaces;

    if (!_labsLoaded) {
      return Row(
        children: [
          SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _family.accent,
            ),
          ),
          const SizedBox(width: 10),
          Text(l10n.lipidLabLoading,
              style: theme.type.body.copyWith(fontSize: 13)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.lipidLabQuestion,
          style: theme.type.fieldLabel.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: surfaces.inset,
            borderRadius: BorderRadius.circular(surfaces.radiusControl),
            border: Border.all(color: surfaces.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLab,
              isExpanded: true,
              borderRadius: BorderRadius.circular(surfaces.radiusControl),
              dropdownColor: surfaces.card,
              style: theme.type.body.copyWith(color: surfaces.ink),
              iconEnabledColor: surfaces.inkSecondary,
              items: [
                DropdownMenuItem(value: _kNone, child: Text(l10n.lipidLabNotSpecified)),
                ..._labs.map((l) => DropdownMenuItem(
                      value: l.code,
                      child: Text(l.city == null ? l.name : '${l.name} · ${l.city}',
                          overflow: TextOverflow.ellipsis),
                    )),
                DropdownMenuItem(value: _kOther, child: Text(l10n.lipidLabOther)),
              ],
              onChanged: (v) {
                setState(() => _selectedLab = v ?? _kNone);
                _warmLabRanges(_labCodeForRanges);
              },
            ),
          ),
        ),
        if (_selectedLab == _kOther) ...[
          const SizedBox(height: 12),
          _buildTextField(
            controller: _labController,
            label: l10n.lipidLabName,
            hint: l10n.lipidLabNameHint,
            isNumeric: false,
          ),
        ],
      ],
    );
  }

  // ── Generic text field ────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isNumeric = true,
  }) {
    final theme = _theme;
    final surfaces = theme.surfaces;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.type.fieldLabel.copyWith(fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: surfaces.inset,
            borderRadius: BorderRadius.circular(surfaces.radiusControl),
            border: Border.all(color: surfaces.divider),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumeric
                ? TextInputType.number
                : TextInputType.text,
            style: theme.type.body.copyWith(color: surfaces.ink),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.type.body.copyWith(
                color: surfaces.inkMuted,
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
    final theme = _theme;
    final surfaces = theme.surfaces;
    return Container(
      decoration: BoxDecoration(
        color: surfaces.inset,
        borderRadius: BorderRadius.circular(surfaces.radiusCard),
        border: Border.all(color: surfaces.divider),
      ),
      child: TextField(
        controller: _commentController,
        maxLines: 3,
        style: theme.type.body.copyWith(color: surfaces.ink),
        decoration: InputDecoration(
          hintText: l10n.commentHint,
          hintStyle: theme.type.body.copyWith(
            color: surfaces.inkMuted,
            fontSize: 13,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}

