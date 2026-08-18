import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/medication.dart';
import '../../data/models/medication_dose.dart';
import '../controllers/medications_controller.dart';
import '../view_models/med_view_mapper.dart';
import '../view_models/med_view_models.dart';
import '../widgets/step_progress_bar.dart';

/// Asistente de alta y edición de un medicamento (5 pasos). Recoge identidad,
/// dosis, frecuencia, fechas e inventario en campos reales, valida lo esencial y
/// guarda con el [MedicationsController] (que reprograma los avisos). Si recibe
/// un id por `extra`, edita ese medicamento en lugar de crear uno.
class MedicationWizardScreen extends StatefulWidget {
  const MedicationWizardScreen({super.key, this.medicationId});

  final String? medicationId;

  @override
  State<MedicationWizardScreen> createState() => _MedicationWizardScreenState();
}

class _MedicationWizardScreenState extends State<MedicationWizardScreen> {
  static const _total = 5;
  int _step = 1;

  final _nameCtrl = TextEditingController();
  final _strengthCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  MedicationForm _form = MedicationForm.capsule;
  String _colorKey = 'brand';
  String _shape = 'capsule';
  String _strengthUnit = 'mg';
  int _doseQty = 1;

  FrequencyType _freq = FrequencyType.daily;
  int _daysMask = 0x7F; // todos por defecto
  int _intervalN = 2;
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];

  DateTime _startDate = DateTime.now();
  bool _hasEnd = false;
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  bool _trackInventory = true;
  int _units = 30;
  int _threshold = 5;
  int _leadDays = 3;
  int _packSize = 30;
  bool _refillAlerts = true;

  Medication? _existing;

  static const _colorKeys = ['brand', 'teal', 'violet', 'green', 'amber'];
  static const _units_ = ['mg', 'mcg', 'ml', 'g', 'UI'];

  @override
  void initState() {
    super.initState();
    final id = widget.medicationId;
    if (id != null) {
      final controller = context.read<MedicationsController>();
      final med = controller.medicationById(id);
      if (med != null) _prefill(med, controller.dosesFor(id));
    }
  }

  void _prefill(Medication m, List<MedicationDose> doses) {
    _existing = m;
    _nameCtrl.text = m.name;
    _strengthCtrl.text = m.strengthValue == null
        ? ''
        : (m.strengthValue! % 1 == 0
            ? m.strengthValue!.toInt().toString()
            : m.strengthValue!.toString());
    _notesCtrl.text = m.notes ?? '';
    _form = m.form;
    _colorKey = _colorKeys.contains(m.color) ? m.color! : 'brand';
    _shape = m.shape == 'round' ? 'round' : 'capsule';
    _strengthUnit = _units_.contains(m.strengthUnit) ? m.strengthUnit! : 'mg';
    _doseQty = m.doseQuantity.round().clamp(1, 20);
    _freq = m.frequencyType;
    _daysMask = m.daysOfWeek ?? 0x7F;
    _intervalN = m.intervalDays ?? 2;
    if (doses.isNotEmpty) {
      _times
        ..clear()
        ..addAll(doses.map((d) => TimeOfDay(hour: d.hour, minute: d.minute)));
    }
    _startDate = m.startDate ?? DateTime.now();
    _hasEnd = m.endDate != null;
    if (m.endDate != null) _endDate = m.endDate!;
    _trackInventory = m.stockTrackingEnabled;
    _units = (m.stockQuantity ?? 30).round();
    _threshold = (m.refillThreshold ?? 5).round();
    _leadDays = m.refillLeadDays ?? 3;
    _packSize = (m.packSize ?? 30).round();
    _refillAlerts = m.refillAlertEnabled;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _strengthCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _error(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool _validateStep(AppLocalizations l10n) {
    if (_step == 1 && _nameCtrl.text.trim().isEmpty) {
      _error(l10n.medErrorNameRequired);
      return false;
    }
    if (_step == 3) {
      if (_freq == FrequencyType.daysOfWeek && _daysMask == 0) {
        _error(l10n.medErrorSelectDays);
        return false;
      }
      if (_times.isEmpty) {
        _error(l10n.medErrorAddTime);
        return false;
      }
    }
    return true;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _step = 1);
      _error(l10n.medErrorNameRequired);
      return;
    }
    final controller = context.read<MedicationsController>();
    final router = GoRouter.of(context);

    final strength =
        double.tryParse(_strengthCtrl.text.trim().replaceAll(',', '.'));
    final med = Medication(
      id: _existing?.id,
      name: _nameCtrl.text.trim(),
      form: _form,
      strengthValue: strength,
      strengthUnit: strength == null ? null : _strengthUnit,
      doseQuantity: _doseQty.toDouble(),
      color: _colorKey,
      shape: _shape,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      frequencyType: _freq,
      daysOfWeek: _freq == FrequencyType.daysOfWeek ? _daysMask : null,
      intervalDays: _freq == FrequencyType.intervalDays ? _intervalN : null,
      anchorDate: _freq == FrequencyType.intervalDays ? _startDate : null,
      startDate: _startDate,
      endDate: _hasEnd ? _endDate : null,
      isActive: _existing?.isActive ?? true,
      stockQuantity: _trackInventory ? _units.toDouble() : null,
      stockTrackingEnabled: _trackInventory,
      refillThreshold: _trackInventory ? _threshold.toDouble() : null,
      refillLeadDays: _trackInventory ? _leadDays : null,
      packSize: _trackInventory ? _packSize.toDouble() : null,
      refillAlertEnabled: _refillAlerts,
      createdAt: _existing?.createdAt,
    );

    final doses = [
      for (final t in _times)
        MedicationDose(medicationId: med.id, hour: t.hour, minute: t.minute),
    ];

    try {
      if (_existing != null) {
        await controller.updateMedication(med, doses);
      } else {
        await controller.addMedication(med, doses);
      }
    } catch (e) {
      // Si la escritura falla, NO se navega atrás: se avisa y se deja el
      // formulario intacto para reintentar (antes se cerraba como si hubiera
      // guardado).
      if (mounted) _error(l10n.medErrorSaveFailed);
      return;
    }
    router.pop();
  }

  void _next(AppLocalizations l10n) {
    if (!_validateStep(l10n)) return;
    if (_step < _total) {
      setState(() => _step++);
    } else {
      _save();
    }
  }

  void _back() {
    if (_step > 1) {
      setState(() => _step--);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: surfaces.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _back,
                    child: Text(
                      _step == 1 ? l10n.cancel : '‹ ${l10n.medBack}',
                      style: theme.type.button.copyWith(
                        color:
                            _step == 1 ? surfaces.inkSecondary : surfaces.brand,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l10n.medWizardStepOf(_step, _total),
                    style: theme.type.sectionLabel.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StepProgressBar(total: _total, current: _step),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(_title(l10n),
                    style: theme.type.screenTitle.copyWith(fontSize: 30)),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [_stepBody(l10n)],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: _PrimaryButton(
                label: _step == _total
                    ? l10n.medSaveMedication
                    : l10n.medContinue,
                onTap: () => _next(l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _title(AppLocalizations l10n) => switch (_step) {
        1 => l10n.medStepIdentity,
        2 => l10n.medStepDose,
        3 => l10n.medStepFrequency,
        4 => l10n.medStepDates,
        _ => l10n.medStepInventory,
      };

  Widget _stepBody(AppLocalizations l10n) => switch (_step) {
        1 => _identityStep(l10n),
        2 => _doseStep(l10n),
        3 => _frequencyStep(l10n),
        4 => _datesStep(l10n),
        _ => _inventoryStep(l10n),
      };

  // ── Paso 1 · Identidad
  Widget _identityStep(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(l10n.medFieldName),
        _TextField(controller: _nameCtrl, hint: 'Vytorin'),
        const SizedBox(height: 20),
        _FieldLabel(l10n.medFieldForm),
        _ChipWrap(
          // Una opción por cada valor de MedicationForm, en el mismo orden que
          // el enum, para que el índice mapee directo (incluido `other`, que
          // antes no era seleccionable y al editar se degradaba a `drops`).
          options: [
            l10n.medFormNameCapsule,
            l10n.medFormNameTablet,
            l10n.medFormNameLiquid,
            l10n.medFormNameInjection,
            l10n.medFormNameDrops,
            l10n.medFormNameOther,
          ],
          selected: _form.index,
          onSelect: (i) => setState(() => _form = MedicationForm.values[i]),
        ),
        const SizedBox(height: 20),
        _FieldLabel(l10n.medFieldStrength),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _TextField(
                controller: _strengthCtrl,
                hint: '10',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: surfaces.inset,
                  borderRadius: BorderRadius.circular(surfaces.radiusControl),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _strengthUnit,
                    isExpanded: true,
                    dropdownColor: surfaces.card,
                    style: theme.type.body,
                    items: [
                      for (final u in _units_)
                        DropdownMenuItem(value: u, child: Text(u)),
                    ],
                    onChanged: (v) =>
                        setState(() => _strengthUnit = v ?? 'mg'),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _FieldLabel(l10n.medFieldColorIcon),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: surfaces.cardDecoration(),
          child: Column(
            children: [
              Row(
                children: [
                  for (var i = 0; i < _colorKeys.length; i++) ...[
                    _Swatch(
                      color: MedColor.values[i],
                      selected: _colorKey == _colorKeys[i],
                      onTap: () => setState(() => _colorKey = _colorKeys[i]),
                    ),
                    if (i < _colorKeys.length - 1) const SizedBox(width: 10),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ShapeButton(
                      label: l10n.medShapeCapsule,
                      selected: _shape == 'capsule',
                      onTap: () => setState(() => _shape = 'capsule'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ShapeButton(
                      label: l10n.medShapeRound,
                      selected: _shape == 'round',
                      onTap: () => setState(() => _shape = 'round'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Paso 2 · Dosis
  Widget _doseStep(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(l10n.medFieldQtyPerDose),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: surfaces.cardDecoration(),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  doseAmountLabel(_doseQty, _form, l10n),
                  style: theme.type.cardTitle.copyWith(fontSize: 16),
                ),
              ),
              _MiniStepper(
                value: _doseQty,
                onMinus: () => setState(() => _doseQty = (_doseQty - 1).clamp(1, 20)),
                onPlus: () => setState(() => _doseQty = (_doseQty + 1).clamp(1, 20)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _FieldLabel(l10n.medFieldReason),
        _TextField(controller: _notesCtrl, hint: ''),
      ],
    );
  }

  // ── Paso 3 · Frecuencia
  Widget _frequencyStep(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final locale = l10n.localeName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Segmented(
          options: [
            l10n.medFreqDaily,
            l10n.medFreqSpecificDays,
            l10n.medFreqEveryNDays,
          ],
          selected: _freq.index,
          onSelect: (i) => setState(() => _freq = FrequencyType.values[i]),
        ),
        const SizedBox(height: 24),
        if (_freq == FrequencyType.daysOfWeek) ...[
          _FieldLabel(l10n.medFieldWeekdays),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var wd = 1; wd <= 7; wd++)
                _DayCircle(
                  label: weekdayShort(wd, locale)[0].toUpperCase(),
                  selected: (_daysMask & (1 << (wd - 1))) != 0,
                  onTap: () => setState(() {
                    final bit = 1 << (wd - 1);
                    (_daysMask & bit) != 0
                        ? _daysMask &= ~bit
                        : _daysMask |= bit;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        if (_freq == FrequencyType.intervalDays) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: surfaces.cardDecoration(),
            child: Row(
              children: [
                Expanded(
                  child: Text(l10n.medIntervalLabel,
                      style: theme.type.cardTitle.copyWith(fontSize: 16)),
                ),
                _MiniStepper(
                  value: _intervalN,
                  onMinus: () =>
                      setState(() => _intervalN = (_intervalN - 1).clamp(1, 60)),
                  onPlus: () =>
                      setState(() => _intervalN = (_intervalN + 1).clamp(1, 60)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        Row(
          children: [
            _FieldLabel(l10n.medFieldDoseTimes),
            const Spacer(),
            GestureDetector(
              onTap: _addTime,
              child: Text('+ ${l10n.medAddTime}',
                  style: theme.type.button
                      .copyWith(fontSize: 14, color: surfaces.brand)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _times.length; i++)
          _TimeRow(
            time: _times[i],
            onEdit: () => _editTime(i),
            onRemove: _times.length > 1 ? () => _removeTime(i) : null,
          ),
      ],
    );
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) setState(() => _times.add(picked));
  }

  Future<void> _editTime(int i) async {
    final picked =
        await showTimePicker(context: context, initialTime: _times[i]);
    if (picked != null) setState(() => _times[i] = picked);
  }

  void _removeTime(int i) => setState(() => _times.removeAt(i));

  // ── Paso 4 · Fechas
  Widget _datesStep(AppLocalizations l10n) {
    final locale = l10n.localeName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(l10n.medFieldStart),
        _DateField(
          label: shortDateLabel(_startDate, locale),
          onTap: () async {
            final picked = await _pickDate(_startDate);
            if (picked != null) setState(() => _startDate = picked);
          },
        ),
        const SizedBox(height: 20),
        _ToggleRow(
          title: l10n.medWithEndDate,
          subtitle: l10n.medWithEndDateSub,
          value: _hasEnd,
          onChanged: (v) => setState(() => _hasEnd = v),
        ),
        if (_hasEnd) ...[
          const SizedBox(height: 16),
          _FieldLabel(l10n.medFieldEnd),
          _DateField(
            label: shortDateLabel(_endDate, locale),
            onTap: () async {
              final picked = await _pickDate(_endDate);
              if (picked != null) setState(() => _endDate = picked);
            },
          ),
        ],
      ],
    );
  }

  Future<DateTime?> _pickDate(DateTime initial) => showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );

  // ── Paso 5 · Inventario
  Widget _inventoryStep(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ToggleRow(
          title: l10n.medTrackInventory,
          subtitle: l10n.medTrackInventorySub,
          value: _trackInventory,
          onChanged: (v) => setState(() => _trackInventory = v),
        ),
        if (_trackInventory) ...[
          const SizedBox(height: 16),
          _StepperRow(
            label: l10n.medCurrentUnits,
            value: _units,
            onMinus: () => setState(() => _units = (_units - 1).clamp(0, 999)),
            onPlus: () => setState(() => _units = (_units + 1).clamp(0, 999)),
          ),
          const SizedBox(height: 12),
          _StepperRow(
            label: l10n.medAlertWhenRemaining,
            value: _threshold,
            onMinus: () =>
                setState(() => _threshold = (_threshold - 1).clamp(0, 999)),
            onPlus: () =>
                setState(() => _threshold = (_threshold + 1).clamp(0, 999)),
          ),
          const SizedBox(height: 12),
          _StepperRow(
            label: l10n.medLeadTimeDays,
            value: _leadDays,
            onMinus: () =>
                setState(() => _leadDays = (_leadDays - 1).clamp(0, 60)),
            onPlus: () =>
                setState(() => _leadDays = (_leadDays + 1).clamp(0, 60)),
          ),
          const SizedBox(height: 12),
          _StepperRow(
            label: l10n.medPackSize,
            value: _packSize,
            onMinus: () =>
                setState(() => _packSize = (_packSize - 1).clamp(1, 999)),
            onPlus: () =>
                setState(() => _packSize = (_packSize + 1).clamp(1, 999)),
          ),
          const SizedBox(height: 16),
          _ToggleRow(
            title: l10n.medRefillAlerts,
            subtitle: l10n.medRefillAlertsSub,
            value: _refillAlerts,
            onChanged: (v) => setState(() => _refillAlerts = v),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(l10n.medTrackInventorySub,
                style: theme.type.meta.copyWith(color: surfaces.inkMuted)),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────── Piezas del asistente

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Theme.of(context).type.sectionLabel),
      );
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
  });
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: theme.type.body,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: surfaces.inset,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(surfaces.radiusControl),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(surfaces.radiusControl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: surfaces.inset,
          borderRadius: BorderRadius.circular(surfaces.radiusControl),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: theme.type.body)),
            Icon(Icons.calendar_today, size: 18, color: surfaces.inkMuted),
          ],
        ),
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap(
      {required this.options, required this.selected, required this.onSelect});
  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < options.length; i++)
          _Chip(
              label: options[i],
              selected: selected == i,
              onTap: () => onSelect(i)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Material(
      color: selected ? surfaces.brand : surfaces.inset,
      borderRadius: BorderRadius.circular(surfaces.radiusControl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(surfaces.radiusControl),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            label,
            style: theme.type.button.copyWith(
              fontSize: 15,
              color: selected ? surfaces.onBrand : surfaces.inkSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(
      {required this.color, required this.selected, required this.onTap});
  final MedColor color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    final tone = resolveMedTone(context, color);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: tone.accent,
          shape: BoxShape.circle,
          border: selected ? Border.all(color: surfaces.ink, width: 2) : null,
        ),
      ),
    );
  }
}

class _ShapeButton extends StatelessWidget {
  const _ShapeButton(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Material(
      color: selected ? surfaces.selection : Colors.transparent,
      borderRadius: BorderRadius.circular(surfaces.radiusControl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(surfaces.radiusControl),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(surfaces.radiusControl),
            border: Border.all(
                color: selected ? surfaces.brand : surfaces.divider),
          ),
          child: Text(
            label,
            style: theme.type.button.copyWith(
              fontSize: 14,
              color: selected ? surfaces.ink : surfaces.inkSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented(
      {required this.options, required this.selected, required this.onSelect});
  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaces.inset,
        borderRadius: BorderRadius.circular(surfaces.radiusControl),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected == i ? surfaces.brand : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(surfaces.radiusControl - 2),
                  ),
                  child: Text(
                    options[i],
                    textAlign: TextAlign.center,
                    style: theme.type.button.copyWith(
                      fontSize: 13,
                      color:
                          selected == i ? surfaces.onBrand : surfaces.inkSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCircle extends StatelessWidget {
  const _DayCircle(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? surfaces.brand : surfaces.inset,
        ),
        child: Text(
          label,
          style: theme.type.button.copyWith(
            color: selected ? surfaces.onBrand : surfaces.inkSecondary,
          ),
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.time, required this.onEdit, this.onRemove});
  final TimeOfDay time;
  final VoidCallback onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final label = timeLabelHM(time.hour, time.minute);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: surfaces.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: surfaces.inset,
              borderRadius: BorderRadius.circular(surfaces.radiusIcon),
            ),
            child: Icon(Icons.schedule, size: 18, color: surfaces.brand),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: InkWell(
              onTap: onEdit,
              child: Text(label,
                  style: theme.type.numeral.copyWith(fontSize: 22)),
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: Icon(Icons.close, size: 18, color: surfaces.inkMuted),
            ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: surfaces.cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.type.cardTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.type.meta),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: surfaces.onBrand,
            activeTrackColor: surfaces.brand,
          ),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });
  final String label;
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: surfaces.cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: theme.type.cardTitle.copyWith(fontSize: 16)),
          ),
          _MiniStepper(value: value, onMinus: onMinus, onPlus: onPlus),
        ],
      ),
    );
  }
}

class _MiniStepper extends StatelessWidget {
  const _MiniStepper(
      {required this.value, required this.onMinus, required this.onPlus});
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    Widget btn(IconData icon, VoidCallback onTap) => Material(
          color: surfaces.inset,
          borderRadius: BorderRadius.circular(surfaces.radiusControl),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(surfaces.radiusControl),
            child: Padding(
                padding: const EdgeInsets.all(7),
                child: Icon(icon, size: 18, color: surfaces.brand)),
          ),
        );
    return Row(
      children: [
        btn(Icons.remove, onMinus),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('$value',
              style: theme.type.numeral.copyWith(fontSize: 22)),
        ),
        btn(Icons.add, onPlus),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final radius = BorderRadius.circular(surfaces.radiusControl);
    return Material(
      color: surfaces.brand,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 17),
          child: Text(label,
              style: theme.type.button.copyWith(color: surfaces.onBrand)),
        ),
      ),
    );
  }
}
