import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/widgets/dashed_border_container.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/metric_palette.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/tone.dart';
import 'package:myvitals_healthtracker_app/core/widgets/status_chip.dart';
import 'package:myvitals_healthtracker_app/core/utils/health_classifiers.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/anthropometric_record.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'dart:math' as math;

import 'package:myvitals_healthtracker_app/core/providers/ui_preferences_provider.dart';
import 'package:myvitals_healthtracker_app/core/widgets/dismissible_info_banner.dart';
import 'package:myvitals_healthtracker_app/core/widgets/icon_badge.dart';
import 'package:myvitals_healthtracker_app/core/validation/input_rules.dart';

class RecordAnthropometricScreen extends StatefulWidget {
  final AnthropometricRecord? recordToEdit;
  const RecordAnthropometricScreen({super.key, this.recordToEdit});

  @override
  State<RecordAnthropometricScreen> createState() =>
      _RecordAnthropometricScreenState();
}

class _RecordAnthropometricScreenState
    extends State<RecordAnthropometricScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  double weight = 74.5;
  double height = 175;
  double? manualBmi;

  final TextEditingController _commentController = TextEditingController();

  // Perímetros corporales (cm), opcionales — los mismos que mide la consulta.
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();
  final _lowerAbdomenController = TextEditingController();
  final _armController = TextEditingController();
  final _legController = TextEditingController();
  final _chestBustController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final r = widget.recordToEdit;
    if (r != null) {
      selectedDate = r.date;
      selectedTime = TimeOfDay.fromDateTime(r.date);
      weight = r.weight;
      // Registros importados del servidor pueden traer la talla en metros.
      height = r.height < 3 ? r.height * 100 : r.height;
      manualBmi = r.bmi;
      _commentController.text = r.comment ?? '';
      _waistController.text = _cmToText(r.waistCm);
      _hipController.text = _cmToText(r.hipCm);
      _lowerAbdomenController.text = _cmToText(r.lowerAbdomenCm);
      _armController.text = _cmToText(r.armCm);
      _legController.text = _cmToText(r.legCm);
      _chestBustController.text = _cmToText(r.chestBustCm);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    _lowerAbdomenController.dispose();
    _armController.dispose();
    _legController.dispose();
    _chestBustController.dispose();
    super.dispose();
  }

  static String _cmToText(double? v) {
    if (v == null) return '';
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }

  double? _cmValue(TextEditingController c) => InputRules.toNumber(c.text);

  /// Tiñe el selector de Material con la identidad de la familia.
  ///
  /// Se sobreescribe solo el `ColorScheme`, no la `ThemeData` entera: así el
  /// calendario hereda la tipografía y las superficies del tema activo y solo
  /// se le impone de qué color es el día seleccionado.
  Widget _themedPicker(BuildContext ctx, Widget? child) {
    final base = Theme.of(ctx);
    final family = base.metrics.tone(MetricFamily.anthropometry);
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: _themedPicker,
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: _themedPicker,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> _showEditDialog(
    String title,
    double currentValue,
    Function(double) onSaved,
  ) async {
    final controller = TextEditingController(
      text: currentValue.toStringAsFixed(1),
    );
    final l10n = AppLocalizations.of(context)!;
    // Se capturan antes de abrir: dentro del builder `context` es el del
    // diálogo, y leer los tokens de aquí deja explícito de qué tema salen.
    final theme = _theme;
    final surfaces = theme.surfaces;
    final family = _family;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: surfaces.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(surfaces.radiusCard),
          ),
          title: Text(
            title,
            style: theme.type.cardTitle.copyWith(fontSize: 18),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: theme.type.body.copyWith(color: surfaces.ink),
            inputFormatters: InputRules.decimal(decimals: 1, integerDigits: 3),
            decoration: InputDecoration(
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
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.cancel,
                style: theme.type.button.copyWith(color: surfaces.inkSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final val = InputRules.toNumber(controller.text);
                if (val != null) {
                  onSaved(val);
                }
                Navigator.pop(context);
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
        );
      },
    );
  }

  void _incrementWeight() => setState(() {
    weight += 0.5;
    manualBmi = null;
  });
  void _decrementWeight() => setState(() {
    if (weight > 10) weight -= 0.5;
    manualBmi = null;
  });

  void _incrementHeight() => setState(() {
    height += 1;
    manualBmi = null;
  });
  void _decrementHeight() => setState(() {
    if (height > 50) height -= 1;
    manualBmi = null;
  });

  double get bmi {
    if (manualBmi != null) return manualBmi!;
    if (height == 0) return 0;
    // height is in cm
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  // ── Tokens ────────────────────────────────────────────────────────────────
  // Los ayudantes de abajo se llaman desde `build`, así que leen el tema por
  // `context` como cualquier widget. Se exponen como getters para no repetir
  // `Theme.of(context)` en cada uno.

  ThemeData get _theme => Theme.of(context);

  /// Identidad de la familia «antropometría». El tema decide el ámbar exacto;
  /// que sea ámbar y no otro matiz lo fija el contrato semántico.
  Tone get _family => _theme.metrics.tone(MetricFamily.anthropometry);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentBmi = bmi;
    final bmiCat = BmiCategory.of(currentBmi);
    final surfaces = _theme.surfaces;

    return Scaffold(
      backgroundColor: surfaces.canvas,
      body: Column(
        children: [
          _buildCustomAppBar(context, l10n),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!context
                      .watch<UIPreferencesProvider>()
                      .isAnthropoInfoDismissed) ...[
                    DismissibleInfoBanner(
                      text: l10n.infoBannerAnthro,
                      baseColor: _family.accent,
                      onDismiss: () {
                        context
                            .read<UIPreferencesProvider>()
                            .dismissAnthropoInfo();
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildSectionTitle(l10n.dateTimeOfMeasurement),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSelectorCard(
                          label: l10n.dateLabel,
                          value: DateFormat('dd/MM/yyyy').format(selectedDate),
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
                  const SizedBox(height: 32),
                  _buildSectionTitle(l10n.bodyMeasurements),
                  const SizedBox(height: 12),
                  _buildMeasurementCard(
                    l10n.weightLabel,
                    weight.toStringAsFixed(1),
                    'kg',
                    _decrementWeight,
                    _incrementWeight,
                    () => _showEditDialog(
                      l10n.weightLabel,
                      weight,
                      (val) => setState(() {
                        weight = val;
                        manualBmi = null;
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMeasurementCard(
                    l10n.heightLabel,
                    height.toStringAsFixed(0),
                    'cm',
                    _decrementHeight,
                    _incrementHeight,
                    () => _showEditDialog(
                      l10n.heightLabel,
                      height,
                      (val) => setState(() {
                        height = val;
                        manualBmi = null;
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildBmiCard(l10n, currentBmi, bmiCat, () {
                    _showEditDialog(
                      l10n.bmiTitle,
                      currentBmi,
                      (val) => setState(() => manualBmi = val),
                    );
                  }),
                  const SizedBox(height: 32),
                  _buildSectionTitle(l10n.circumferencesSection),
                  const SizedBox(height: 12),
                  _buildCircumferencesCard(l10n),
                  const SizedBox(height: 32),
                  _buildSectionTitle(l10n.commentOptional),
                  const SizedBox(height: 12),
                  _buildCommentBox(l10n),
                  const SizedBox(height: 32),
                  // Save Action
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final record = AnthropometricRecord(
                          id: widget.recordToEdit?.id,
                          date: DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          ),
                          weight: weight,
                          height: height,
                          bmi: currentBmi,
                          waistCm: _cmValue(_waistController),
                          hipCm: _cmValue(_hipController),
                          lowerAbdomenCm: _cmValue(_lowerAbdomenController),
                          armCm: _cmValue(_armController),
                          legCm: _cmValue(_legController),
                          chestBustCm: _cmValue(_chestBustController),
                          comment: _commentController.text.trim().isEmpty
                              ? null
                              : _commentController.text.trim(),
                          createdAt: widget.recordToEdit?.createdAt,
                        );
                        if (widget.recordToEdit != null) {
                          await AnthropometricRepository.instance.update(
                            record,
                          );
                        } else {
                          await AnthropometricRepository.instance.insert(
                            record,
                          );
                        }
                        if (!context.mounted) return;
                        // Guardar bien es un resultado ÓPTIMO, y ese es el
                        // verde de la paleta clínica: no un verde suelto.
                        final ok = _theme.clinical.optimal;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.anthropoSavedSuccess,
                              style: _theme.type.body.copyWith(
                                color: ok.onAccent,
                              ),
                            ),
                            backgroundColor: ok.accent,
                          ),
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _family.accent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            surfaces.radiusControl,
                          ),
                        ),
                        // Los temas planos no llevan sombra en los controles;
                        // el token de sombra de tarjeta dice cuál es el caso.
                        elevation: surfaces.cardShadow.isEmpty ? 0 : 4,
                        shadowColor: _family.accent.withValues(alpha: 0.4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.saveAndEarnXp,
                            style: _theme.type.button.copyWith(
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

  Widget _buildCustomAppBar(BuildContext context, AppLocalizations l10n) {
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
                  l10n.recordAnthropometricTitle,
                  textAlign: TextAlign.center,
                  style: _theme.type.sectionLabel.copyWith(
                    fontSize: 15,
                    color: family.onAccent,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.straighten, color: family.onAccent),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: _theme.type.sectionLabel.copyWith(color: _theme.surfaces.ink),
    );
  }

  Widget _buildSelectorCard({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final surfaces = _theme.surfaces;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: _theme.type.fieldLabel),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: surfaces.card,
              borderRadius: BorderRadius.circular(surfaces.radiusCard),
              border: Border.all(color: surfaces.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: _theme.type.cardTitle.copyWith(fontSize: 15),
                ),
                Icon(icon, color: surfaces.inkSecondary, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementCard(
    String label,
    String value,
    String unit,
    VoidCallback onDecrement,
    VoidCallback onIncrement,
    VoidCallback onEdit,
  ) {
    final theme = _theme;
    final family = _family;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: theme.surfaces.cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.type.fieldLabel.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onEdit,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: theme.type.numeralSmall.copyWith(fontSize: 28),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        unit,
                        style: theme.type.numeralUnit.copyWith(
                          fontSize: 16,
                          color: family.accent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.edit, size: 16, color: family.accent),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildAdjustButton(Icons.remove, onDecrement),
          const SizedBox(width: 12),
          _buildAdjustButton(Icons.add, onIncrement),
        ],
      ),
    );
  }

  Widget _buildAdjustButton(IconData icon, VoidCallback onTap) {
    final surfaces = _theme.surfaces;
    return InkWell(
      onTap: onTap,
      borderRadius: surfaces.iconRadius,
      child: IconBadge(
        icon,
        color: _family.accent,
        background: surfaces.inset,
        size: 44,
        iconSize: 24,
        border: Border.all(color: surfaces.divider),
      ),
    );
  }

  /// Tarjeta del IMC.
  ///
  /// Recibe la CATEGORÍA, no un color: quién decide que 26,1 es «sobrepeso» son
  /// los rangos del backoffice vía [BmiCategory], y el tema solo resuelve con
  /// qué ámbar se pinta. La insignia es [StatusChip], que además aplica el
  /// idioma del tema —relleno sólido o suave— sin que esta pantalla lo sepa.
  Widget _buildBmiCard(
    AppLocalizations l10n,
    double bmi,
    BmiCategory category,
    VoidCallback onEditManual,
  ) {
    final theme = _theme;
    final family = _family;
    return DashedBorderContainer(
      color: family.accent.withValues(alpha: 0.5),
      borderRadius: theme.surfaces.radiusCard,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.bmiTitle,
                  style: theme.type.fieldLabel.copyWith(fontSize: 13),
                ),
                InkWell(
                  onTap: onEditManual,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 14, color: family.accent),
                        const SizedBox(width: 4),
                        Text(
                          l10n.manual,
                          style: theme.type.button.copyWith(
                            fontSize: 13,
                            color: family.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  bmi.toStringAsFixed(1),
                  style: theme.type.numeral.copyWith(
                    fontSize: 32,
                    color: family.accent,
                  ),
                ),
                const SizedBox(width: 12),
                StatusChip(
                  status: category.status,
                  label: category.label(l10n),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildBmiGradientBar(l10n, bmi),
          ],
        ),
      ),
    );
  }

  Widget _buildBmiGradientBar(AppLocalizations l10n, double bmi) {
    // Normalizing BMI for the gradient marker (15 to 35 typical range)
    double percent = (bmi - 15) / (35 - 15);
    percent = math.max(0.0, math.min(1.0, percent));

    final theme = _theme;
    final surfaces = theme.surfaces;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                // La rampa de severidad del tema, en orden clínico:
                // bajo → normal → sobrepeso → obesidad. El orden lo fija la
                // paleta, no esta pantalla, así que no puede quedar al revés.
                gradient: LinearGradient(colors: theme.clinical.severityRamp),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top:
                  -40, // Adjusted top position to make the tip touch the bar correctly
              child: FractionalTranslation(
                translation: Offset(percent - 0.5, 0),
                child: Icon(
                  Icons.arrow_drop_down,
                  color: surfaces.ink,
                  size: 80, // Increased size even more per request
                  // El halo va del color del lienzo: separa la punta de la
                  // rampa en cualquier tema, claro o cálido.
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
            Text(l10n.bmiLow, style: _bmiLabelStyle()),
            Text(l10n.bmiNormal, style: _bmiLabelStyle()),
            Text(l10n.bmiOverweight, style: _bmiLabelStyle()),
            Text(l10n.bmiObesity, style: _bmiLabelStyle()),
          ],
        ),
      ],
    );
  }

  TextStyle _bmiLabelStyle() => _theme.type.sectionLabel.copyWith(
    fontSize: 8,
    color: _theme.surfaces.inkMuted,
  );

  /// Tarjeta con los 6 perímetros (cm) que también mide la consulta. Todos
  /// opcionales: se guarda solo lo diligenciado.
  Widget _buildCircumferencesCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _theme.surfaces.cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildCmField(l10n.circWaist, _waistController)),
              const SizedBox(width: 12),
              Expanded(child: _buildCmField(l10n.circHip, _hipController)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCmField(
                  l10n.circLowerAbdomen,
                  _lowerAbdomenController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildCmField(l10n.circArm, _armController)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildCmField(l10n.circLeg, _legController)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCmField(l10n.circChestBust, _chestBustController),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCmField(String label, TextEditingController controller) {
    final theme = _theme;
    final surfaces = theme.surfaces;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.type.fieldLabel),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: theme.type.body.copyWith(color: surfaces.ink),
          inputFormatters: InputRules.decimal(decimals: 1, integerDigits: 3),
          decoration: InputDecoration(
            hintText: '— cm',
            suffixText: 'cm',
            suffixStyle: theme.type.numeralUnit.copyWith(
              fontSize: 12,
              color: _family.accent,
            ),
            filled: true,
            fillColor: surfaces.inset,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(surfaces.radiusControl),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentBox(AppLocalizations l10n) {
    final theme = _theme;
    final surfaces = theme.surfaces;
    return Container(
      decoration: BoxDecoration(
        color: surfaces.card,
        borderRadius: BorderRadius.circular(surfaces.radiusCard),
        border: Border.all(color: surfaces.divider),
      ),
      child: TextField(
        controller: _commentController,
        maxLines: 4,
        // Texto libre, pero acotado: un pegado accidental no debe meter miles
        // de caracteres en la base.
        inputFormatters: InputRules.freeText(),
        style: theme.type.body.copyWith(color: surfaces.ink),
        decoration: InputDecoration(
          hintText: l10n.commentHint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
