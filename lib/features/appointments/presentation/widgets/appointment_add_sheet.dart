import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/features/appointments/data/models/appointment.dart';
import 'package:myvitals_healthtracker_app/features/appointments/domain/appointment_specialties.dart';
import 'package:myvitals_healthtracker_app/features/appointments/presentation/controllers/appointments_controller.dart';

/// Hoja de alta/edición de una cita, en dos modos con un solo formulario:
/// - **Ya tengo fecha** (agendada): fecha + hora concretas.
/// - **Debo sacarla** (por sacar / recall): fecha objetivo para agendarla.
///
/// Si se pasa [existing], la hoja abre en **modo edición**: precarga los campos y
/// al guardar actualiza esa cita (en vez de crear una nueva). El resto de campos
/// (especialidad, médico/lugar, notas) son opcionales. Un toggle **«control
/// periódico»** fija la recurrencia (cada N meses): al confirmar asistencia, el
/// controlador genera automáticamente la siguiente «por sacar».
class AppointmentAddSheet extends StatefulWidget {
  const AppointmentAddSheet({super.key, this.existing});

  /// Cita a editar; null para crear una nueva.
  final Appointment? existing;

  @override
  State<AppointmentAddSheet> createState() => _AppointmentAddSheetState();
}

class _AppointmentAddSheetState extends State<AppointmentAddSheet> {
  /// true = «Ya tengo fecha» (agendada); false = «Debo sacarla» (por sacar).
  late bool _scheduledMode;

  late final TextEditingController _titleController;
  late final TextEditingController _providerController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;

  /// Especialidad elegida del desplegable; `null` = «Sin especialidad».
  String? _specialty;

  DateTime? _date;
  TimeOfDay? _time;

  bool _isRecurring = false;

  /// Opciones de periodicidad ofrecidas (en meses).
  static const List<int> _intervalOptions = [1, 3, 6, 12];
  int _intervalMonths = 3;

  bool _titleTouched = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _scheduledMode = e?.status == AppointmentStatus.scheduled;
    _titleController = TextEditingController(text: e?.title ?? '');
    // La especialidad ya no se teclea: se preselecciona el valor guardado (si lo
    // hay). Si no coincide con ninguna opción del idioma actual, el desplegable
    // lo añade como opción extra para no perderlo (ver build).
    final existingSpecialty = e?.specialty?.trim();
    _specialty = (existingSpecialty == null || existingSpecialty.isEmpty)
        ? null
        : existingSpecialty;
    _providerController = TextEditingController(text: e?.provider ?? '');
    _locationController = TextEditingController(text: e?.location ?? '');
    _notesController = TextEditingController(text: e?.notes ?? '');
    _isRecurring = e?.isRecurring ?? false;
    _intervalMonths = e?.intervalMonths ?? 3;
    if (e != null) {
      final date = e.scheduledAt ?? e.dueToBookOn;
      if (date != null) {
        _date = DateTime(date.year, date.month, date.day);
        if (e.scheduledAt != null) {
          _time = TimeOfDay.fromDateTime(e.scheduledAt!);
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _providerController.dispose();
    _locationController.dispose();
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
    final specialty = _specialty?.trim() ?? '';
    final provider = _providerController.text.trim();
    final location = _locationController.text.trim();
    final notes = _notesController.text.trim();
    final intervalMonths = _isRecurring ? _intervalMonths : null;

    String? orNull(String s) => s.isEmpty ? null : s;

    if (_isEditing) {
      // En edición se pasan los textos tal cual (incluida la cadena vacía) para
      // que vaciar un campo lo limpie: `copyWith` sólo ignora `null`, no `''`.
      await _saveEdit(
        controller,
        title: title,
        specialty: specialty,
        provider: provider,
        location: location,
        notes: notes,
        intervalMonths: intervalMonths,
      );
    } else if (_scheduledMode) {
      await controller.addScheduled(
        title: title,
        scheduledAt: _scheduledDateTime(),
        specialty: orNull(specialty),
        provider: orNull(provider),
        location: orNull(location),
        notes: orNull(notes),
        isRecurring: _isRecurring,
        intervalMonths: intervalMonths,
      );
    } else {
      await controller.addToBook(
        title: title,
        dueToBookOn: DateTime(_date!.year, _date!.month, _date!.day),
        specialty: orNull(specialty),
        provider: orNull(provider),
        location: orNull(location),
        notes: orNull(notes),
        isRecurring: _isRecurring,
        intervalMonths: intervalMonths,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  /// Fecha/hora combinada para una cita agendada (hora por defecto 9:00).
  DateTime _scheduledDateTime() {
    final time = _time ?? const TimeOfDay(hour: 9, minute: 0);
    return DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      time.hour,
      time.minute,
    );
  }

  /// Guarda la edición sobre la cita existente, respetando el modo elegido
  /// (agendada / por sacar) y limpiando la fecha del otro modo.
  Future<void> _saveEdit(
    AppointmentsController controller, {
    required String title,
    required String specialty,
    required String provider,
    required String location,
    required String notes,
    int? intervalMonths,
  }) async {
    final base = widget.existing!.copyWith(
      title: title,
      specialty: specialty,
      provider: provider,
      location: location,
      notes: notes,
      isRecurring: _isRecurring,
      intervalMonths: intervalMonths,
    );
    final updated = _scheduledMode
        ? base.copyWith(
            status: AppointmentStatus.scheduled,
            scheduledAt: _scheduledDateTime(),
            clearDueToBookOn: true,
          )
        : base.copyWith(
            status: AppointmentStatus.toBook,
            dueToBookOn: DateTime(_date!.year, _date!.month, _date!.day),
            clearScheduledAt: true,
          );
    await controller.save(updated);
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
                _isEditing ? l10n.appointmentEditTitle : l10n.appointmentAddTitle,
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

              // Especialidad como lista cerrada: el usuario elige, no teclea.
              _Field(
                label: l10n.appointmentFieldSpecialty,
                child: _SpecialtyDropdown(
                  value: _specialty,
                  onChanged: (v) => setState(() => _specialty = v),
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
                label: l10n.appointmentFieldLocation,
                child: TextField(
                  controller: _locationController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration(
                    context,
                    hint: l10n.appointmentFieldLocationHint,
                  ),
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

              // Recurrencia: control periódico cada N meses.
              _RecurrenceSection(
                enabled: _isRecurring,
                intervalMonths: _intervalMonths,
                intervalOptions: _intervalOptions,
                onToggle: (v) => setState(() => _isRecurring = v),
                onIntervalChanged: (m) => setState(() => _intervalMonths = m),
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

/// Sección de recurrencia: toggle «control periódico» + selector de cada N meses
/// + una línea que explica qué pasa al confirmar asistencia.
class _RecurrenceSection extends StatelessWidget {
  const _RecurrenceSection({
    required this.enabled,
    required this.intervalMonths,
    required this.intervalOptions,
    required this.onToggle,
    required this.onIntervalChanged,
  });

  final bool enabled;
  final int intervalMonths;
  final List<int> intervalOptions;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onIntervalChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.appointmentFieldRecurring,
                  style: theme.type.fieldLabel.copyWith(color: surfaces.ink),
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeThumbColor: surfaces.onBrand,
                activeTrackColor: surfaces.brand,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 4),
            Text(
              l10n.appointmentFrequencyLabel,
              style: theme.type.meta.copyWith(color: surfaces.inkSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in intervalOptions)
                  _ModeChip(
                    label: l10n.appointmentEveryNMonths(m),
                    selected: m == intervalMonths,
                    onTap: () => onIntervalChanged(m),
                    expand: false,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.appointmentRecurringHint,
              style: theme.type.meta.copyWith(color: surfaces.inkMuted),
            ),
          ],
        ],
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
    this.expand = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Cuando true, el texto se centra y ocupa el ancho del padre (para el selector
  /// de modo dentro de un [Expanded]); cuando false, el chip se ajusta a su
  /// contenido (para los chips de periodicidad dentro de un [Wrap]).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final text = Text(
      label,
      textAlign: TextAlign.center,
      style: theme.type.button.copyWith(
        color: selected ? surfaces.onBrand : surfaces.inkSecondary,
      ),
    );
    return Material(
      color: selected ? surfaces.brand : surfaces.inset,
      borderRadius: BorderRadius.circular(surfaces.radiusControl),
      child: InkWell(
        borderRadius: BorderRadius.circular(surfaces.radiusControl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: expand ? Center(child: text) : text,
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

/// Desplegable CERRADO de especialidad: el usuario elige de un catálogo curado
/// en vez de teclear, para reducir la copia y evitar variantes sueltas. La
/// primera opción («Sin especialidad») deja el campo vacío, que es opcional.
///
/// Al editar una cita cuya especialidad guardada no esté en el catálogo del
/// idioma actual (un valor demo en otro idioma o texto libre heredado), se añade
/// como opción extra para no perder lo que ya estaba.
class _SpecialtyDropdown extends StatelessWidget {
  const _SpecialtyDropdown({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;

    final options = appointmentSpecialties(l10n);
    // Preserva un valor guardado que no esté en el catálogo actual.
    final extras = (value != null && value!.isNotEmpty && !options.contains(value))
        ? [value!]
        : const <String>[];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surfaces.inset,
        borderRadius: BorderRadius.circular(surfaces.radiusControl),
        border: Border.all(color: surfaces.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          dropdownColor: surfaces.card,
          style: theme.type.body,
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                l10n.specialtyNone,
                style: theme.type.body.copyWith(color: surfaces.inkMuted),
              ),
            ),
            for (final s in [...extras, ...options])
              DropdownMenuItem<String?>(
                value: s,
                child: Text(s, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
        ),
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
