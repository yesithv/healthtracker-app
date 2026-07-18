import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/widgets/dashed_border_container.dart';
import 'package:myvitals_healthtracker_app/core/constants/metric_colors.dart';
import 'package:myvitals_healthtracker_app/core/utils/health_classifiers.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/anthropometric_record.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:myvitals_healthtracker_app/core/providers/ui_preferences_provider.dart';
import 'package:myvitals_healthtracker_app/core/widgets/dismissible_info_banner.dart';

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

  double? _cmValue(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: MetricColors.anthropoColor,
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: MetricColors.anthropoColor,
            ),
          ),
          child: child!,
        );
      },
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

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: MetricColors.anthropoColor,
                  width: 1.5,
                ),
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(
                  controller.text.replaceAll(',', '.'),
                );
                if (val != null) {
                  onSaved(val);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MetricColors.anthropoColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('OK'),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentBmi = bmi;
    final bmiCat = BmiCategory.of(currentBmi);
    final bmiCategory = bmiCat.label(l10n);
    final bmiColor = bmiCat.color;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Column(
        children: [
          _buildCustomAppBar(context, l10n),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!context.watch<UIPreferencesProvider>().isAnthropoInfoDismissed) ...[
                    DismissibleInfoBanner(
                      text: l10n.infoBannerAnthro,
                      baseColor: MetricColors.anthropoColor,
                      onDismiss: () {
                        context.read<UIPreferencesProvider>().dismissAnthropoInfo();
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
                  _buildBmiCard(l10n, currentBmi, bmiCategory, bmiColor, () {
                    _showEditDialog(
                      l10n.bmiTitle,
                      currentBmi,
                      (val) => setState(() => manualBmi = val),
                    );
                  }),
                  const SizedBox(height: 32),
                  _buildSectionTitle('PERÍMETROS CORPORALES (OPCIONAL)'),
                  const SizedBox(height: 12),
                  _buildCircumferencesCard(),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.anthropoSavedSuccess,
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MetricColors.anthropoColor,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: MetricColors.anthropoColor.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.saveAndEarnXp,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: MetricColors.anthropoColor,
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
                  l10n.recordAnthropometricTitle,
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
                icon: const Icon(Icons.straighten, color: Colors.white),
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
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildSelectorCard({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Icon(icon, color: const Color(0xFF64748B), size: 18),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
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
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        unit,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: MetricColors.anthropoColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.edit,
                        size: 16,
                        color: MetricColors.anthropoColor,
                      ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, color: MetricColors.anthropoColor),
      ),
    );
  }

  Widget _buildBmiCard(
    AppLocalizations l10n,
    double bmi,
    String category,
    Color color,
    VoidCallback onEditManual,
  ) {
    return DashedBorderContainer(
      color: MetricColors.anthropoColor.withValues(alpha: 0.5),
      borderRadius: 20,
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                InkWell(
                  onTap: onEditManual,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.edit,
                          size: 14,
                          color: MetricColors.anthropoColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.manual,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: MetricColors.anthropoColor,
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
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: MetricColors.anthropoColor,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
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
                    Color(0xFF3B82F6), // Bajo
                    Color(0xFF10B981), // Normal
                    Color(0xFFF59E0B), // Sobrepeso
                    Color(0xFFEF4444), // Obesidad
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top:
                  -40, // Adjusted top position to make the tip touch the bar correctly
              child: FractionalTranslation(
                translation: Offset(percent - 0.5, 0),
                child: const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFF1E293B),
                  size: 80, // Increased size even more per request
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
            Text(l10n.bmiLow, style: _bmiLabelStyle()),
            Text(l10n.bmiNormal, style: _bmiLabelStyle()),
            Text(l10n.bmiOverweight, style: _bmiLabelStyle()),
            Text(l10n.bmiObesity, style: _bmiLabelStyle()),
          ],
        ),
      ],
    );
  }

  TextStyle _bmiLabelStyle() {
    return const TextStyle(
      fontSize: 8,
      fontWeight: FontWeight.bold,
      color: Color(0xFF94A3B8),
      letterSpacing: 0.5,
    );
  }

  /// Tarjeta con los 6 perímetros (cm) que también mide la consulta. Todos
  /// opcionales: se guarda solo lo diligenciado.
  Widget _buildCircumferencesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Row(children: [
            Expanded(child: _buildCmField('Cintura', _waistController)),
            const SizedBox(width: 12),
            Expanded(child: _buildCmField('Cadera', _hipController)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildCmField('Abdomen bajo', _lowerAbdomenController)),
            const SizedBox(width: 12),
            Expanded(child: _buildCmField('Brazo', _armController)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildCmField('Pierna', _legController)),
            const SizedBox(width: 12),
            Expanded(child: _buildCmField('Pecho/Busto', _chestBustController)),
          ]),
        ],
      ),
    );
  }

  Widget _buildCmField(String label, TextEditingController controller) {
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
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: InputDecoration(
            hintText: '— cm',
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
            suffixText: 'cm',
            suffixStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: MetricColors.anthropoColor,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentBox(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _commentController,
        maxLines: 4,
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
