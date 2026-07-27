import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/vital_sign_record.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/metric_palette.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/tone.dart';
import 'package:myvitals_healthtracker_app/core/widgets/status_chip.dart';
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

  // ── Tokens ────────────────────────────────────────────────────────────────

  ThemeData get _theme => Theme.of(context);

  /// Identidad de la familia «signos vitales»: rojo en cualquier tema.
  Tone get _family => _theme.metrics.tone(MetricFamily.vitals);

  /// Tiñe el selector de Material con la identidad de la familia, dejándole al
  /// tema la tipografía y las superficies.
  Widget _themedPicker(BuildContext ctx, Widget? child) {
    final base = Theme.of(ctx);
    final family = base.metrics.tone(MetricFamily.vitals);
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
          style: theme.type.body.copyWith(color: surfaces.ink),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
    // Guardar bien es un resultado ÓPTIMO: ese verde sale de la paleta clínica.
    final ok = _theme.clinical.optimal;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.vitalsSavedSuccess,
          style: _theme.type.body.copyWith(color: ok.onAccent),
        ),
        backgroundColor: ok.accent,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bpCat = BpCategory.of(systolic, diastolic);
    final hrCat = HrCategory.of(heartRate);
    final theme = _theme;
    final surfaces = theme.surfaces;
    // El clasificador da el ESTADO (rangos del backoffice); el tema resuelve el
    // color. Ni esta pantalla ni el tema deciden si 128/84 está elevada.
    final bpTone = theme.clinical.tone(bpCat.status);
    final hrTone = theme.clinical.tone(hrCat.status);

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
                  if (!context
                      .watch<UIPreferencesProvider>()
                      .isVitalInfoDismissed) ...[
                    DismissibleInfoBanner(
                      text: l10n.infoBannerVitals,
                      baseColor: _family.accent,
                      onDismiss: () {
                        context
                            .read<UIPreferencesProvider>()
                            .dismissVitalInfo();
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  // ── Fecha y Hora ──────────────────────────────────────────
                  _buildSectionCard(
                    icon: Icons.calendar_month_outlined,
                    iconColor: _family.accent,
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
                    iconColor: _family.accent,
                    title: l10n.bloodPressureTitle,
                    badge: StatusChip(
                      status: bpCat.status,
                      label: bpCat.label(l10n),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildBpValueCard(
                                value: systolic,
                                label: l10n.systolicLabel,
                                unit: 'mmHg',
                                tone: bpTone,
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
                                style: theme.type.numeral.copyWith(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w300,
                                  color: surfaces.inkMuted,
                                ),
                              ),
                            ),
                            Expanded(
                              child: _buildBpValueCard(
                                value: diastolic,
                                label: l10n.diastolicLabel,
                                unit: 'mmHg',
                                tone: bpTone,
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
                    iconColor: _family.accent,
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
                                    style: theme.type.numeral.copyWith(
                                      fontSize: 40,
                                      color: hrTone.accent,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'BPM',
                                    style: theme.type.numeralUnit.copyWith(
                                      fontSize: 16,
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
                        _buildHrGradientBar(l10n),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Contexto y Síntomas ───────────────────────────────────
                  _buildSectionCard(
                    icon: Icons.assignment_outlined,
                    iconColor: _family.accent,
                    title: l10n.contextAndSymptoms,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Activity state
                        Text(l10n.activityState, style: theme.type.fieldLabel),
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
                        Text(l10n.howDoYouFeel, style: theme.type.fieldLabel),
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
                        backgroundColor: _family.accent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            surfaces.radiusControl,
                          ),
                        ),
                        // Los temas planos no llevan sombra en los controles.
                        elevation: surfaces.cardShadow.isEmpty ? 0 : 4,
                        shadowColor: _family.accent.withValues(alpha: 0.4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.saveAndEarnXp,
                            style: theme.type.button.copyWith(
                              fontSize: 16,
                              color: _family.onAccent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // La chispa era un `✦` dentro de la cadena traducida.
                          // Ninguna de las seis fuentes empaquetadas trae ese
                          // glifo, así que se dibujaba como un cuadrito vacío.
                          // Como icono no depende de la fuente de texto.
                          Icon(
                            Icons.auto_awesome,
                            size: 18,
                            color: _family.onAccent,
                          ),
                        ],
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
                  l10n.recordVitalSignsTitle,
                  textAlign: TextAlign.center,
                  style: _theme.type.sectionLabel.copyWith(
                    fontSize: 15,
                    color: family.onAccent,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.favorite, color: family.onAccent),
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
                Icon(icon, color: iconColor ?? _family.accent, size: 18),
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

  // ── Date / Time selectors ─────────────────────────────────────────────────
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

  // ── Blood pressure value card ─────────────────────────────────────────────
  /// Recibe el TONO clínico ya resuelto, no un color suelto: el filete y la
  /// cifra deben salir del mismo estado que la insignia de la tarjeta.
  Widget _buildBpValueCard({
    required int value,
    required String label,
    required String unit,
    required Tone tone,
    required VoidCallback onTap,
  }) {
    final theme = _theme;
    final surfaces = theme.surfaces;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: surfaces.inset,
              borderRadius: BorderRadius.circular(surfaces.radiusCard),
              border: Border.all(
                color: tone.accent.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                value.toString(),
                style: theme.type.numeral.copyWith(
                  fontSize: 36,
                  color: tone.accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.type.sectionLabel.copyWith(
              fontSize: 10,
              color: surfaces.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ── HR gradient bar ───────────────────────────────────────────────────────
  Widget _buildHrGradientBar(AppLocalizations l10n) {
    final percent = _hrBarPercent;
    final theme = _theme;
    final surfaces = theme.surfaces;
    final clinical = theme.clinical;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                // Rampa de severidad del tema, en orden clínico:
                // baja → normal → normal-alta → alta.
                gradient: LinearGradient(colors: clinical.severityRamp),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: -38,
              child: FractionalTranslation(
                translation: Offset(percent - 0.5, 0),
                child: Icon(
                  Icons.arrow_drop_down,
                  color: surfaces.ink,
                  size: 72,
                  // El halo va del lienzo: separa la punta de la rampa en
                  // cualquier tema.
                  shadows: [Shadow(color: surfaces.canvas, blurRadius: 2)],
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
              // «Normal» resaltado en el verde de ÓPTIMO: es el único rótulo
              // que marca un objetivo, no solo un tramo de la escala.
              style: _labelStyle(color: clinical.optimal.accent),
            ),
            Text(l10n.hrHigh, style: _labelStyle()),
          ],
        ),
      ],
    );
  }

  TextStyle _labelStyle({Color? color}) => _theme.type.sectionLabel.copyWith(
    fontSize: 9,
    color: color ?? _theme.surfaces.inkMuted,
  );

  // ── Activity chip ─────────────────────────────────────────────────────────
  Widget _buildChip(String label, String value, IconData icon) {
    final selected = activityState == value;
    final theme = _theme;
    final surfaces = theme.surfaces;
    final family = _family;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activityState = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? family.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? family.accent : surfaces.divider,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? family.onAccent : surfaces.inkMuted,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.type.badge.copyWith(
                  fontSize: 10,
                  color: selected ? family.onAccent : surfaces.inkSecondary,
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
    final theme = _theme;
    final surfaces = theme.surfaces;
    final family = _family;
    return GestureDetector(
      onTap: () => setState(() => symptom = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? family.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(surfaces.radiusCard),
          border: Border.all(
            color: selected ? family.accent : surfaces.divider,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? family.onAccent : surfaces.inkMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: theme.type.badge.copyWith(
                  fontSize: 12,
                  color: selected ? family.onAccent : surfaces.inkSecondary,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: family.onAccent, size: 14),
          ],
        ),
      ),
    );
  }

  // ── Adjust button ─────────────────────────────────────────────────────────
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
