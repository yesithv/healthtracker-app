import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/features/appointments/presentation/controllers/appointments_controller.dart';

/// Hoja de alta de una cita, en dos modos con un solo formulario:
/// - **Ya tengo fecha** (agendada): fecha + hora concretas.
/// - **Debo sacarla** (por sacar / recall): fecha objetivo para agendarla.
///
/// El resto de campos (especialidad, médico/lugar, notas) son opcionales. Al
/// guardar delega en [AppointmentsController], que persiste y reprograma avisos.
class AppointmentAddSheet extends StatefulWidget {
  const AppointmentAddSheet({super.key});

  @override
  State<AppointmentAddSheet> createState() => _AppointmentAddSheetState();
}

class _AppointmentAddSheetState extends State<AppointmentAddSheet> {
  /// true = «Ya tengo fecha» (agendada); false = «Debo sacarla» (por sacar).
  bool _scheduledMode = false;

  final _titleController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _providerController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _date;
  TimeOfDay? _time;

  bool _titleTouched = false;

  @override
  void dispose() {
    _titleController.dispose();
    _specialtyController.dispose();
    _providerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _date == null) {
      setState(() => _titleTouched = true);
      return;
    }

    final controller = context.read<AppointmentsController>();
    final specialty = _specialtyController.text.trim();
    final provider = _providerController.text.trim();
    final notes = _notesController.text.trim();

    if (_scheduledMode) {
      final time = _time ?? const TimeOfDay(hour: 9, minute: 0);
      final at = DateTime(
        _date!.year,
        _date!.month,
        _date!.day,
        time.hour,
        time.minute,
      );
      await controller.addScheduled(
        title: title,
        scheduledAt: at,
        specialty: specialty.isEmpty ? null : specialty,
        provider: provider.isEmpty ? null : provider,
        notes: notes.isEmpty ? null : notes,
      );
    } else {
      await controller.addToBook(
        title: title,
        dueToBookOn: DateTime(_date!.year, _date!.month, _date!.day),
        specialty: specialty.isEmpty ? null : specialty,
        provider: provider.isEmpty ? null : provider,
        notes: notes.isEmpty ? null : notes,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final material = MaterialLocalizations.of(context);

    final dateLabel = _date == null
        ? l10n.appointmentPickDate
        : material.formatMediumDate(_date!);
    final timeLabel =
        _time == null ? l10n.appointmentPickTime : _time!.format(context);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: surfaces.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Asa del modal.
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: surfaces.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                l10n.appointmentAddTitle,
                style: theme.type.screenTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 16),

              // Selector de modo.
              _ModeSelector(
                scheduledMode: _scheduledMode,
                onChanged: (v) => setState(() => _scheduledMode = v),
              ),
              const SizedBox(height: 20),

              _Field(
                label: l10n.appointmentFieldTitle,
                child: TextField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration(
                    context,
                    hint: l10n.appointmentFieldTitleHint,
                    error: _titleTouched && _titleController.text.trim().isEmpty
                        ? l10n.appointmentTitleRequired
                        : null,
                  ),
                  onChanged: (_) {
                    if (_titleTouched) setState(() {});
                  },
                ),
              ),

              _Field(
                label: l10n.appointmentFieldSpecialty,
                child: TextField(
                  controller: _specialtyController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration(
                    context,
                    hint: l10n.appointmentFieldSpecialtyHint,
                  ),
                ),
              ),

              // Fecha (y hora si es agendada).
              _Field(
                label: _scheduledMode
                    ? l10n.appointmentFieldDate
                    : l10n.appointmentFieldTargetDate,
                child: Row(
                  children: [
                    Expanded(
                      child: _PickerButton(
                        icon: Icons.calendar_today_outlined,
                        label: dateLabel,
                        onTap: _pickDate,
                      ),
                    ),
                    if (_scheduledMode) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PickerButton(
                          icon: Icons.schedule_outlined,
                          label: timeLabel,
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_titleTouched && _date == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Text(
                    l10n.appointmentDateRequired,
                    style: theme.type.meta
                        .copyWith(color: theme.clinical.alert.accent),
                  ),
                ),

              _Field(
                label: l10n.appointmentFieldProvider,
                child: TextField(
                  controller: _providerController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration(context),
                ),
              ),

              _Field(
                label: l10n.appointmentFieldNotes,
                child: TextField(
                  controller: _notesController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  decoration: _inputDecoration(context),
                ),
              ),

              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: surfaces.brand,
                    foregroundColor: surfaces.onBrand,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: theme.type.button,
                  ),
                  child: Text(l10n.appointmentSave),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    String? hint,
    String? error,
  }) {
    final surfaces = Theme.of(context).surfaces;
    return InputDecoration(
      hintText: hint,
      errorText: error,
      filled: true,
      fillColor: surfaces.inset,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(surfaces.radiusControl),
        borderSide: BorderSide(color: surfaces.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(surfaces.radiusControl),
        borderSide: BorderSide(color: surfaces.divider),
      ),
    );
  }
}

/// Selector de dos modos: «Debo sacarla» (por sacar) vs «Ya tengo fecha».
class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.scheduledMode, required this.onChanged});

  final bool scheduledMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _ModeChip(
            label: l10n.appointmentModeToBook,
            selected: !scheduledMode,
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ModeChip(
            label: l10n.appointmentModeScheduled,
            selected: scheduledMode,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
        borderRadius: BorderRadius.circular(surfaces.radiusControl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.type.button.copyWith(
                color: selected ? surfaces.onBrand : surfaces.inkSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Etiqueta encima de un campo del formulario.
class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.type.fieldLabel
                .copyWith(color: theme.surfaces.inkSecondary),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

/// Botón que abre un selector (fecha u hora) y muestra el valor elegido.
class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Material(
      color: surfaces.inset,
      borderRadius: BorderRadius.circular(surfaces.radiusControl),
      child: InkWell(
        borderRadius: BorderRadius.circular(surfaces.radiusControl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: surfaces.inkMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.type.body.copyWith(color: surfaces.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
