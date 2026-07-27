import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/clinical_palette.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/metric_palette.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/tone.dart';
import 'package:myvitals_healthtracker_app/core/widgets/status_chip.dart';
import 'package:myvitals_healthtracker_app/core/utils/health_classifiers.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/body_composition_record.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/ui_preferences_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';
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

  /// % de músculo esquelético (opcional): es lo que reporta la báscula OMRON y
  /// lo que guardaba el legacy; [muscleMass] (kg) queda para básculas en kg.
  double? musclePct;

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
      musclePct = r.musclePct;
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

  // ── Tokens ────────────────────────────────────────────────────────────────

  ThemeData get _theme => Theme.of(context);

  /// Identidad de la familia «composición corporal»: índigo en cualquier tema.
  Tone get _family => _theme.metrics.tone(MetricFamily.bodyComposition);

  /// Tiñe el selector de Material con la identidad de la familia, dejándole al
  /// tema la tipografía y las superficies.
  Widget _themedPicker(BuildContext ctx, Widget? child) {
    final base = Theme.of(ctx);
    final family = base.metrics.tone(MetricFamily.bodyComposition);
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

  // ── Date / time pickers ──────────────────────────────────────────────────
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
    // Capturados antes de abrir: dentro del builder `ctx` es el del diálogo.
    final theme = _theme;
    final surfaces = theme.surfaces;
    final family = _family;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaces.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(surfaces.radiusCard),
        ),
        title: Text(title, style: theme.type.cardTitle.copyWith(fontSize: 18)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          style: theme.type.body.copyWith(color: surfaces.ink),
          decoration: InputDecoration(
            suffixText: unit,
            suffixStyle: theme.type.numeralUnit,
            filled: true,
            fillColor: surfaces.inset,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(surfaces.radiusCard),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(surfaces.radiusCard),
              borderSide: BorderSide(color: family.accent, width: 1.5),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.cancel,
              style: theme.type.button.copyWith(color: surfaces.inkSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val >= min && val <= max) onSaved(val);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: family.accent,
              foregroundColor: family.onAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(surfaces.radiusControl),
              ),
            ),
            child: Text(
              'OK',
              style: theme.type.button.copyWith(color: family.onAccent),
            ),
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
    // Capturados antes de abrir: dentro del builder `ctx` es el del diálogo.
    final theme = _theme;
    final surfaces = theme.surfaces;
    final family = _family;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaces.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(surfaces.radiusCard),
        ),
        title: Text(title, style: theme.type.cardTitle.copyWith(fontSize: 18)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: theme.type.body.copyWith(color: surfaces.ink),
          decoration: InputDecoration(
            suffixText: unit,
            suffixStyle: theme.type.numeralUnit,
            filled: true,
            fillColor: surfaces.inset,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(surfaces.radiusCard),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(surfaces.radiusCard),
              borderSide: BorderSide(color: family.accent, width: 1.5),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.cancel,
              style: theme.type.button.copyWith(color: surfaces.inkSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val >= min && val <= max) onSaved(val);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: family.accent,
              foregroundColor: family.onAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(surfaces.radiusControl),
              ),
            ),
            child: Text(
              'OK',
              style: theme.type.button.copyWith(color: family.onAccent),
            ),
          ),
        ],
      ),
    );
  }

  // ── Save ─────────────────────────────────────────────────────────────────
  Future<void> _saveRecord() async {
    // Dispositivo: en edición se conserva el del registro; en uno nuevo se usa la
    // báscula por defecto del perfil (p. ej. 'Omron' para pacientes del legacy).
    final defaultDevice = context.read<UserProfileProvider>().defaultDeviceName;
    final deviceName =
        widget.recordToEdit?.deviceName ??
        (defaultDevice.isEmpty ? null : defaultDevice);

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
      musclePct: musclePct,
      visceralFatLevel: visceralFat,
      metabolicAge: metabolicAge,
      bmrKcal: _displayBmr,
      bodyWaterPercent: bodyWater,
      boneMassKg: boneMass,
      deviceName: deviceName,
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
    // Este aviso usaba el color de la FAMILIA, no el verde de éxito de las
    // otras tres pantallas. Se mantiene tal cual —solo se cambia el color a
    // mano por su token— porque unificarlo sería cambiar la interfaz, no
    // aplicar el tema.
    final family = _family;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.compositionSavedSuccess,
          style: _theme.type.body.copyWith(color: family.onAccent),
        ),
        backgroundColor: family.accent,
      ),
    );
    context.pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fatCat = FatCategory.of(bodyFat);
    final visceralCat = VisceralCategory.of(visceralFat);
    final theme = _theme;
    final surfaces = theme.surfaces;
    final family = _family;
    // El clasificador da el ESTADO; el tema resuelve el color.
    final fatTone = theme.clinical.tone(fatCat.status);
    final visceralTone = theme.clinical.tone(visceralCat.status);

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
                  // ── Info banner ─────────────────────────────────────────
                  if (!context
                      .watch<UIPreferencesProvider>()
                      .isBodyCompInfoDismissed) ...[
                    DismissibleInfoBanner(
                      text: l10n.compositionInfoBanner,
                      baseColor: family.accent,
                      onDismiss: () {
                        context
                            .read<UIPreferencesProvider>()
                            .dismissBodyCompInfo();
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
                    badge: StatusChip(
                      status: fatCat.status,
                      label: fatCat.label(l10n),
                    ),
                    child: _buildSliderField(
                      value: bodyFat,
                      unit: '%',
                      min: 3,
                      max: 60,
                      tone: fatTone,
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
                      tone: family,
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
                            tone: visceralTone,
                            badgeStatus: visceralCat.status,
                            badgeText: visceralCat.label(l10n),
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
                            tone: family,
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
                          label: l10n.compositionSkeletalMuscle,
                          refText: l10n.compositionSkeletalMuscleRef,
                          value: musclePct,
                          unit: '%',
                          hint: 'Ej: 24.9',
                          onSaved: (v) => setState(() => musclePct = v),
                        ),
                        const SizedBox(height: 16),
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

  // ── AppBar ────────────────────────────────────────────────────────────────
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: family.onAccent),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Text(
                  l10n.compositionTitle,
                  textAlign: TextAlign.center,
                  style: _theme.type.sectionLabel.copyWith(
                    fontSize: 15,
                    color: family.onAccent,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.accessibility_new, color: family.onAccent),
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
              Expanded(
                child: Text(
                  title,
                  style: theme.type.sectionLabel.copyWith(
                    color: theme.surfaces.ink,
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
                Text(value, style: theme.type.cardTitle.copyWith(fontSize: 14)),
                Icon(icon, color: surfaces.inkSecondary, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Slider field (fat % and muscle mass) ──────────────────────────────────
  /// Recibe el TONO ya resuelto —clínico para la grasa, de familia para el
  /// músculo— en vez de un color suelto: la cifra, la pista y el pulgar tienen
  /// que salir todos del mismo sitio.
  Widget _buildSliderField({
    required double value,
    required String unit,
    required double min,
    required double max,
    required Tone tone,
    required ValueChanged<double> onChanged,
    required VoidCallback onTap,
  }) {
    final theme = _theme;
    final color = tone.accent;
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
    required Tone tone,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required VoidCallback onTap,
    ClinicalStatus? badgeStatus,
    String? badgeText,
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
          Text(label, style: theme.type.fieldLabel),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Row(
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
              ],
            ),
          ),
          if (badgeStatus != null && badgeText != null) ...[
            const SizedBox(height: 6),
            StatusChip(status: badgeStatus, label: badgeText),
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
    final theme = _theme;
    final surfaces = theme.surfaces;
    final family = _family;
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
                    style: theme.type.cardTitle.copyWith(fontSize: 13),
                  ),
                  Text(refText, style: theme.type.meta.copyWith(fontSize: 10)),
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
                style: theme.type.body.copyWith(color: surfaces.ink),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: theme.type.body.copyWith(
                    color: surfaces.inkMuted,
                    fontSize: 13,
                  ),
                  suffixText: unit,
                  suffixStyle: theme.type.numeralUnit.copyWith(
                    color: family.accent,
                  ),
                  filled: true,
                  fillColor: surfaces.inset,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(surfaces.radiusControl),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(surfaces.radiusControl),
                    borderSide: BorderSide(color: family.accent, width: 1.5),
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
  /// Única tarjeta sólida de la pantalla: va del color de la familia, así que
  /// todo lo que lleva dentro se pinta con su `onAccent`. Las variantes
  /// atenuadas se derivan con opacidad, en vez de usar blancos literales que
  /// dejarían de funcionar si un tema tuviera acento claro.
  Widget _buildBmrCard(AppLocalizations l10n) {
    final theme = _theme;
    final surfaces = theme.surfaces;
    final family = _family;
    final onAccent = family.onAccent;
    final onAccentSoft = onAccent.withValues(alpha: 0.7);
    final onAccentFaint = onAccent.withValues(alpha: 0.6);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: family.accent,
        borderRadius: BorderRadius.circular(surfaces.radiusCard),
        boxShadow: surfaces.glow(
          family.accent,
          alpha: 0.3,
          blur: 15,
          offset: const Offset(0, 6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: onAccentSoft, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.compositionBmr,
                style: theme.type.sectionLabel.copyWith(
                  fontSize: 11,
                  color: onAccentSoft,
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
                  style: theme.type.numeral.copyWith(
                    color: onAccent,
                    fontSize: 38,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    prefixIcon: Icon(Icons.edit, color: onAccentSoft, size: 20),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 0,
                    ),
                    suffixText: 'kcal',
                    suffixStyle: theme.type.numeralUnit.copyWith(
                      color: onAccentFaint,
                      fontSize: 16,
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
            style: theme.type.meta.copyWith(color: onAccentFaint, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildBmrAdjustButton(IconData icon, VoidCallback onTap) {
    final onAccent = _family.onAccent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onAccent.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: onAccent, size: 16),
      ),
    );
  }

  // ── Adjust buttons ────────────────────────────────────────────────────────
  Widget _buildAdjustButton(IconData icon, VoidCallback onTap) {
    final surfaces = _theme.surfaces;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: surfaces.inset,
          shape: BoxShape.circle,
          border: Border.all(color: surfaces.divider),
        ),
        child: Icon(icon, color: _family.accent, size: 20),
      ),
    );
  }

  Widget _buildSmallAdjustButton(IconData icon, VoidCallback onTap) {
    final family = _family;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: family.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: family.accent, size: 16),
      ),
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

  // ── Helpers ───────────────────────────────────────────────────────────────
  double _round1(double v) => (v * 10).round() / 10;
}
